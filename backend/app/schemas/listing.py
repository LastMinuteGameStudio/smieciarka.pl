import uuid
from datetime import datetime

from pydantic import BaseModel, Field

from app.models.listing import ListingStatus

# Spec section 12: the exact point is visible only to the author. Public
# responses snap coordinates to a ~100m grid so a listing cannot be traced
# back to a specific house.
PUBLIC_COORD_DECIMALS = 3


class LocationIn(BaseModel):
    lat: float = Field(..., ge=-90, le=90)
    lng: float = Field(..., ge=-180, le=180)


class ListingCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=120)
    description: str | None = Field(None, max_length=2000)
    location: LocationIn
    location_label: str | None = Field(None, max_length=120)


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


def listing_out(listing, *, exact: bool) -> ListingOut:
    """Serialize a listing, blurring coordinates unless the viewer is its author."""
    data = ListingOut.model_validate(listing)
    if not exact:
        data.lat = round(data.lat, PUBLIC_COORD_DECIMALS)
        data.lng = round(data.lng, PUBLIC_COORD_DECIMALS)
    return data
