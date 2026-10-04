import uuid
from datetime import date, datetime

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
    address: str | None = Field(None, max_length=200)
    pickup_date: date | None = None


class ListingStatusUpdate(BaseModel):
    status: ListingStatus


class ListingImageOut(BaseModel):
    """One photo. URLs are presigned and expire, so they are not persisted."""

    id: uuid.UUID
    position: int
    url: str
    thumb_url: str
    caption: str | None


class ListingOut(BaseModel):
    id: uuid.UUID
    title: str
    description: str | None
    image_caption: str | None
    lat: float
    lng: float
    location_label: str | None
    address: str | None
    pickup_date: date | None
    author_phone: str | None
    status: ListingStatus
    created_at: datetime
    expires_at: datetime | None
    images: list[ListingImageOut] = []

    class Config:
        from_attributes = True


def listing_out(listing, *, exact: bool, images=()) -> ListingOut:
    """Serialize a listing, blurring coordinates unless the viewer is its author.

    Images are passed in rather than lazy-loaded: presigning touches no
    network but the rows must already be fetched, and an async session will
    not load a relationship on attribute access.
    """
    # Imported here: app.services.storage builds a boto3 client, and schemas
    # are imported by Alembic's env.py, which must not need object storage.
    from app.services import storage

    data = ListingOut.model_validate(listing)
    if not exact:
        data.lat = round(data.lat, PUBLIC_COORD_DECIMALS)
        data.lng = round(data.lng, PUBLIC_COORD_DECIMALS)

    data.images = [
        ListingImageOut(
            id=image.id,
            position=image.position,
            url=storage.presigned_get(image.storage_key),
            thumb_url=storage.presigned_get(image.thumb_key),
            caption=image.caption,
        )
        for image in sorted(images, key=lambda i: i.position)
    ]
    return data
