import uuid

from sqlalchemy import ForeignKey, SmallInteger, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db import Base


class ListingImage(Base):
    __tablename__ = "listing_images"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    listing_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("listings.id", ondelete="CASCADE"), nullable=False, index=True
    )
    # Keys in the object store, not URLs: the bucket and endpoint can change
    # without rewriting rows, and read URLs are presigned per request anyway.
    storage_key: Mapped[str] = mapped_column(String, nullable=False)
    thumb_key: Mapped[str] = mapped_column(String, nullable=False)
    position: Mapped[int] = mapped_column(SmallInteger, nullable=False, default=0)
    # Vision description of this one photo. A listing can hold several, so the
    # caption belongs here; listings.image_caption is the joined form kept for
    # the embedding text. NULL means captioning was off or it failed.
    caption: Mapped[str | None] = mapped_column(Text, nullable=True)
