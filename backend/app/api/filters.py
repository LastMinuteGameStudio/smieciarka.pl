import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.config import settings
from app.db import get_db
from app.models import AreaType, User, WatchFilter
from app.schemas.filter import FilterCreate, FilterOut
from app.services.embeddings import embed_query
from app.services.query_expansion import expand_query

router = APIRouter()


@router.post("/filters", response_model=FilterOut, status_code=status.HTTP_201_CREATED)
async def create_filter(
    body: FilterCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if body.area.type == AreaType.radius and (body.area.center is None or body.area.radius_m is None):
        raise HTTPException(status_code=400, detail="radius area requires center and radius_m")

    existing = await db.scalar(
        select(func.count()).select_from(WatchFilter).where(WatchFilter.user_id == current_user.id)
    )
    if existing >= settings.max_filters_per_user:
        raise HTTPException(
            status_code=409,
            detail=f"Filter limit reached ({settings.max_filters_per_user})",
        )

    # Expand once, here, and embed the expansion: an abstract need scores poorly
    # against concrete listings otherwise (spec 6.2). The user only ever sees
    # body.query. Falls back to the raw query if expansion is unavailable.
    expanded = await expand_query(body.query)
    vector = await embed_query(expanded or body.query)

    watch_filter = WatchFilter(
        user_id=current_user.id,
        query=body.query,
        expanded_query=expanded,
        embedding=vector,
        area_type=body.area.type,
        center_lat=body.area.center.lat if body.area.center else None,
        center_lng=body.area.center.lng if body.area.center else None,
        radius_m=body.area.radius_m,
    )
    db.add(watch_filter)
    await db.commit()
    await db.refresh(watch_filter)
    return watch_filter


@router.get("/filters", response_model=list[FilterOut])
async def list_filters(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(WatchFilter)
        .where(WatchFilter.user_id == current_user.id)
        .order_by(WatchFilter.created_at.desc())
    )
    return result.scalars().all()


@router.delete("/filters/{filter_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_filter(
    filter_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    watch_filter = await db.get(WatchFilter, filter_id)
    if watch_filter is None or watch_filter.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Not found")
    await db.delete(watch_filter)
    await db.commit()
