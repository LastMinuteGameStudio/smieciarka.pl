import uuid
from datetime import datetime

from pydantic import BaseModel

from app.models.watch_filter import AreaType
from app.schemas.listing import LocationIn


class AreaIn(BaseModel):
    type: AreaType
    center: LocationIn | None = None
    radius_m: int | None = None


class FilterCreate(BaseModel):
    query: str
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
