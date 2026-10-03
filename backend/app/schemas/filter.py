import uuid
from datetime import datetime

from pydantic import BaseModel, Field

from app.models.watch_filter import AreaType
from app.schemas.listing import LocationIn


class AreaIn(BaseModel):
    type: AreaType
    center: LocationIn | None = None
    radius_m: int | None = Field(None, ge=100, le=500_000)


class FilterCreate(BaseModel):
    query: str = Field(..., min_length=1, max_length=200)
    area: AreaIn


class FilterOut(BaseModel):
    id: uuid.UUID
    query: str
    area_type: AreaType
    center_lat: float | None
    center_lng: float | None
    radius_m: int | None
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True
