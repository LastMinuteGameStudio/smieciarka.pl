import uuid
from datetime import datetime

from pydantic import BaseModel

from app.models.listing import ListingStatus


class LocationIn(BaseModel):
    lat: float
    lng: float


class ListingCreate(BaseModel):
    title: str
    description: str | None = None
    location: LocationIn
    location_label: str | None = None


class ListingStatusUpdate(BaseModel):
    status: ListingStatus


class ListingOut(BaseModel):
    id: uuid.UUID
    title: str
    description: str | None
    lat: float
    lng: float
    location_label: str | None
    status: ListingStatus
    created_at: datetime
    expires_at: datetime | None

    class Config:
        from_attributes = True
