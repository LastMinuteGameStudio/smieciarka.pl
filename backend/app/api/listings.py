import uuid
from collections import defaultdict
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_optional_user
from app.config import settings
from app.db import get_db
from app.models import Listing, ListingImage, ListingStatus, User
from app.schemas.listing import ListingCreate, ListingOut, ListingStatusUpdate, listing_out
from app.services.embeddings import embed_passage, embed_query, listing_text
from app.services.geo import distance_m_expr
from app.services.matching import match_listing_to_filters

router = APIRouter()


def _distance_m(lat: float, lng: float):
    return distance_m_expr(lat, lng, Listing.lat, Listing.lng)


async def _images_for(listing_ids: list[uuid.UUID], db: AsyncSession):
    """Fetch photos for several listings in one query, grouped by listing.

    One query for the whole page: an async session does not lazy-load a
    relationship on attribute access, and doing it per row would be N+1.
    """
    if not listing_ids:
        return {}
    result = await db.execute(
        select(ListingImage)
        .where(ListingImage.listing_id.in_(listing_ids))
        .order_by(ListingImage.position)
    )
    grouped = defaultdict(list)
    for image in result.scalars().all():
        grouped[image.listing_id].append(image)
    return grouped


@router.post("/listings", response_model=ListingOut, status_code=status.HTTP_201_CREATED)
async def create_listing(
    body: ListingCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # No caption yet: photos are uploaded after the listing exists, and each
    # upload re-embeds it (see api/images.py).
    vector = await embed_passage(listing_text(body.title, body.description, None))

    listing = Listing(
        author_id=current_user.id,
        title=body.title,
        description=body.description,
        lat=body.location.lat,
        lng=body.location.lng,
        location_label=body.location_label,
        address=body.address,
        pickup_date=body.pickup_date,
        embedding=vector,
        status=ListingStatus.active,
        expires_at=datetime.now(timezone.utc) + timedelta(hours=settings.listing_ttl_hours),
    )
    db.add(listing)
    await db.commit()
    await db.refresh(listing)

    await match_listing_to_filters(listing, db)

    return listing_out(listing, exact=True)


@router.get("/listings/search", response_model=list[ListingOut])
async def search_listings(
    q: str = Query(..., min_length=1),
    lat: float | None = Query(None),
    lng: float | None = Query(None),
    radius: int = Query(5000, description="radius in meters, requires lat/lng"),
    viewer: User | None = Depends(get_optional_user),
    db: AsyncSession = Depends(get_db),
):
    query_vector = await embed_query(q)

    stmt = (
        select(Listing)
        .where(Listing.status == ListingStatus.active)
        .order_by(Listing.embedding.cosine_distance(query_vector))
        .limit(50)
    )
    if lat is not None and lng is not None:
        stmt = stmt.where(_distance_m(lat, lng) <= radius)

    result = await db.execute(stmt)
    listings = result.scalars().all()
    images = await _images_for([x.id for x in listings], db)
    return [
        listing_out(
            x,
            exact=viewer is not None and x.author_id == viewer.id,
            images=images.get(x.id, ()),
        )
        for x in listings
    ]


@router.get("/listings/nearby", response_model=list[ListingOut])
async def listings_nearby(
    lat: float = Query(...),
    lng: float = Query(...),
    radius: int = Query(5000, description="radius in meters"),
    viewer: User | None = Depends(get_optional_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Listing)
        .where(Listing.status == ListingStatus.active)
        .where(_distance_m(lat, lng) <= radius)
        .order_by(Listing.created_at.desc())
        .limit(50)
    )
    listings = result.scalars().all()
    images = await _images_for([x.id for x in listings], db)
    return [
        listing_out(
            x,
            exact=viewer is not None and x.author_id == viewer.id,
            images=images.get(x.id, ()),
        )
        for x in listings
    ]


@router.get("/listings/{listing_id}", response_model=ListingOut)
async def get_listing(
    listing_id: uuid.UUID,
    viewer: User | None = Depends(get_optional_user),
    db: AsyncSession = Depends(get_db),
):
    listing = await db.get(Listing, listing_id)
    if listing is None:
        raise HTTPException(status_code=404, detail="Not found")
    images = await _images_for([listing.id], db)
    return listing_out(
        listing,
        exact=viewer is not None and listing.author_id == viewer.id,
        images=images.get(listing.id, ()),
    )


@router.post("/listings/{listing_id}/status", response_model=ListingOut)
async def update_listing_status(
    listing_id: uuid.UUID,
    body: ListingStatusUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    listing = await db.get(Listing, listing_id)
    if listing is None:
        raise HTTPException(status_code=404, detail="Not found")
    if listing.author_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not your listing")
    if body.status not in (ListingStatus.reserved, ListingStatus.given_away):
        raise HTTPException(status_code=400, detail="Invalid status")

    listing.status = body.status
    await db.commit()
    await db.refresh(listing)
    images = await _images_for([listing.id], db)
    return listing_out(listing, exact=True, images=images.get(listing.id, ()))
