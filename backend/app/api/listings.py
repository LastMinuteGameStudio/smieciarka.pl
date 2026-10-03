import uuid
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.config import settings
from app.db import get_db
from app.models import Listing, ListingStatus, User
from app.schemas.listing import ListingCreate, ListingOut, ListingStatusUpdate
from app.services.embeddings import embed_passage

router = APIRouter()


def _distance_m(lat: float, lng: float):
    cos_central_angle = func.least(
        1.0,
        func.greatest(
            -1.0,
            func.cos(func.radians(lat)) * func.cos(func.radians(Listing.lat))
            * func.cos(func.radians(Listing.lng) - func.radians(lng))
            + func.sin(func.radians(lat)) * func.sin(func.radians(Listing.lat)),
        ),
    )
    return 6371000 * func.acos(cos_central_angle)


@router.post("/listings", response_model=ListingOut, status_code=status.HTTP_201_CREATED)
async def create_listing(
    body: ListingCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    text = f"{body.title}. {body.description or ''}".strip()
    vector = await embed_passage(text)

    listing = Listing(
        author_id=current_user.id,
        title=body.title,
        description=body.description,
        lat=body.location.lat,
        lng=body.location.lng,
        location_label=body.location_label,
        embedding=vector,
        status=ListingStatus.active,
        expires_at=datetime.now(timezone.utc) + timedelta(hours=settings.listing_ttl_hours),
    )
    db.add(listing)
    await db.commit()
    await db.refresh(listing)
    return listing


@router.get("/listings/nearby", response_model=list[ListingOut])
async def listings_nearby(
    lat: float = Query(...),
    lng: float = Query(...),
    radius: int = Query(5000, description="radius in meters"),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Listing)
        .where(Listing.status == ListingStatus.active)
        .where(_distance_m(lat, lng) <= radius)
        .order_by(Listing.created_at.desc())
        .limit(50)
    )
    return result.scalars().all()


@router.get("/listings/{listing_id}", response_model=ListingOut)
async def get_listing(listing_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    listing = await db.get(Listing, listing_id)
    if listing is None:
        raise HTTPException(status_code=404, detail="Not found")
    return listing


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
    return listing
