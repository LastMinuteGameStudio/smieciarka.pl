import uuid
from datetime import datetime

from pydantic import BaseModel


class NotificationOut(BaseModel):
    id: uuid.UUID
    listing_id: uuid.UUID
    filter_id: uuid.UUID
    score: float
    read_at: datetime | None
    created_at: datetime

    class Config:
        from_attributes = True
