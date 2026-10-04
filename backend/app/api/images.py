"""Photo upload and removal for a listing.

Upload goes through the API, not through a presigned PUT as spec section 9
describes. The reason is EXIF: a client uploading straight to the bucket puts
untouched camera bytes there, GPS tags included, and with no worker to clean
them up afterwards the exact address of the author would sit in the object
store behind a public URL. Stripping has to happen before the bytes are
stored, so they pass through the API, which is also the only place that can
reject an undecodable file.

A listing holds several photos (MAX_IMAGES_PER_LISTING), one per request.
Each upload re-captions, re-embeds and re-matches the listing, which is the
two-pass behaviour of spec section 6.6: the first pass ran on title and
description at creation, this is the pass that uses the picture.
"""

import logging
import uuid

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.config import settings
from app.db import get_db
from app.models import Listing, ListingImage, User
from app.schemas.listing import ListingOut, listing_out
from app.services import storage, vision
from app.services.embeddings import embed_passage, listing_text
from app.services.images import ImageRejected, OUTPUT_CONTENT_TYPE, OUTPUT_EXTENSION, process
from app.services.matching import match_listing_to_filters

logger = logging.getLogger(__name__)
router = APIRouter()

_READ_CHUNK = 64 * 1024


async def _owned_listing(listing_id: uuid.UUID, user: User, db: AsyncSession) -> Listing:
    listing = await db.get(Listing, listing_id)
    if listing is None:
        raise HTTPException(status_code=404, detail="Not found")
    if listing.author_id != user.id:
        raise HTTPException(status_code=403, detail="Not your listing")
    return listing


async def _read_limited(upload: UploadFile, limit: int) -> bytes:
    """Read at most limit bytes, then reject.

    Streamed rather than upload.read(): reading first and checking the length
    afterwards would already have the whole body in memory, so a huge file
    would cost the memory it was supposed to be refused for.
    """
    chunks: list[bytes] = []
    total = 0
    while chunk := await upload.read(_READ_CHUNK):
        total += len(chunk)
        if total > limit:
            raise ImageRejected(f"File exceeds the {limit // (1024 * 1024)} MB limit")
        chunks.append(chunk)
    return b"".join(chunks)


async def _listing_images(listing_id: uuid.UUID, db: AsyncSession) -> list[ListingImage]:
    result = await db.execute(
        select(ListingImage)
        .where(ListingImage.listing_id == listing_id)
        .order_by(ListingImage.position)
    )
    return list(result.scalars().all())


async def _reindex(listing: Listing, db: AsyncSession) -> list[ListingImage]:
    """Rebuild the joined caption and the embedding from the current photos."""
    images = await _listing_images(listing.id, db)
    captions = [image.caption for image in images if image.caption]
    listing.image_caption = " ".join(captions) or None
    listing.embedding = await embed_passage(
        listing_text(listing.title, listing.description, listing.image_caption)
    )
    await db.commit()
    await db.refresh(listing)
    return images


@router.post(
    "/listings/{listing_id}/images",
    response_model=ListingOut,
    status_code=status.HTTP_201_CREATED,
)
async def upload_listing_image(
    listing_id: uuid.UUID,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    listing = await _owned_listing(listing_id, current_user, db)

    existing = await db.scalar(
        select(func.count())
        .select_from(ListingImage)
        .where(ListingImage.listing_id == listing_id)
    )
    if existing >= settings.max_images_per_listing:
        raise HTTPException(
            status_code=409,
            detail=f"Image limit reached ({settings.max_images_per_listing})",
        )

    try:
        raw = await _read_limited(file, settings.max_image_bytes)
        full_bytes, thumb_bytes = await process(raw, file.content_type)
    except ImageRejected as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    # Next position is max+1, not the row count: deleting a middle photo
    # leaves a gap, and counting would reuse a position already taken.
    highest = await db.scalar(
        select(func.max(ListingImage.position)).where(ListingImage.listing_id == listing_id)
    )
    position = 0 if highest is None else highest + 1

    image_id = uuid.uuid4()
    prefix = f"listings/{listing_id}/{image_id}"
    storage_key = f"{prefix}.{OUTPUT_EXTENSION}"
    thumb_key = f"{prefix}_thumb.{OUTPUT_EXTENSION}"

    await storage.put(storage_key, full_bytes, OUTPUT_CONTENT_TYPE)
    await storage.put(thumb_key, thumb_bytes, OUTPUT_CONTENT_TYPE)

    # Captioned from the thumbnail: naming objects does not need full
    # resolution, and the smaller payload keeps the call quick.
    image_caption = await vision.caption(thumb_bytes, OUTPUT_CONTENT_TYPE)

    db.add(
        ListingImage(
            id=image_id,
            listing_id=listing_id,
            storage_key=storage_key,
            thumb_key=thumb_key,
            position=position,
            caption=image_caption,
        )
    )
    await db.commit()

    images = await _reindex(listing, db)

    # Second matching pass (spec 6.6). UNIQUE(user_id, listing_id) means
    # people already notified from the title are not notified twice; only
    # filters that match because of the photo produce anything new.
    try:
        await match_listing_to_filters(listing, db)
    except Exception:
        logger.exception("re-matching after image upload failed for listing %s", listing.id)

    return listing_out(listing, exact=True, images=images)


@router.delete("/listings/{listing_id}/images/{image_id}", response_model=ListingOut)
async def delete_listing_image(
    listing_id: uuid.UUID,
    image_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    listing = await _owned_listing(listing_id, current_user, db)

    image = await db.get(ListingImage, image_id)
    if image is None or image.listing_id != listing_id:
        raise HTTPException(status_code=404, detail="Not found")

    keys = [image.storage_key, image.thumb_key]
    await db.delete(image)
    await db.commit()

    # Objects go after the row is gone: a leftover object is invisible waste,
    # while a row pointing at a deleted object would break every response for
    # this listing.
    try:
        await storage.delete(keys)
    except Exception:
        logger.exception("could not delete objects %s for listing %s", keys, listing_id)

    # Dropping a photo drops its caption, so the embedding has to change too.
    # No re-match here: removing text must not generate notifications.
    images = await _reindex(listing, db)
    return listing_out(listing, exact=True, images=images)
