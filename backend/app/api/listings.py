import uuid
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_optional_user
from app.config import settings
from app.db import get_db
from app.models import Listing, ListingStatus, User
from app.schemas.listing import ListingCreate, ListingOut, ListingStatusUpdate, listing_out
from app.services.embeddings import embed_passage, embed_query
from app.services.geo import distance_m_expr
from app.services.matching import match_listing_to_filters

router = APIRouter()


def _distance_m(lat: float, lng: float):
    return distance_m_expr(lat, lng, Listing.lat, Listing.lng)


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
    return [
        listing_out(x, exact=viewer is not None and x.author_id == viewer.id)
        for x in result.scalars().all()
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
    return [
        listing_out(x, exact=viewer is not None and x.author_id == viewer.id)
        for x in result.scalars().all()
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
    return listing_out(listing, exact=viewer is not None and listing.author_id == viewer.id)


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
    return listing_out(listing, exact=True)
