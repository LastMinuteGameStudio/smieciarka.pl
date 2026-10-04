"""Decode, sanitize and resize an uploaded photo.

The privacy-critical part is EXIF removal (spec section 9 and 12). Phone
photos routinely carry GPS coordinates of where they were taken, which for a
listing is usually the author's home -- the very thing the blurred public
coordinates exist to hide. Keeping the original bytes would leak the exact
address through the image while the JSON says ~100 m.

Stripping is done by re-encoding, not by deleting EXIF tags: a fresh WebP is
written from the decoded pixels, so no metadata block survives by accident.
Rotation is applied first, because it lives in EXIF and would otherwise be
lost along with it, leaving sideways photos.

Pillow work is CPU-bound and runs in a thread so the event loop keeps
serving.
"""

import asyncio
import io
import logging

import pillow_heif
from PIL import Image, ImageOps, UnidentifiedImageError

from app.config import settings

logger = logging.getLogger(__name__)

# iPhones upload HEIC by default; Pillow needs this plugin to decode it.
pillow_heif.register_heif_opener()

# Content types accepted from the client. The real check is whether Pillow can
# decode the bytes -- a declared type is only a hint.
ALLOWED_CONTENT_TYPES = {
    "image/jpeg",
    "image/png",
    "image/webp",
    "image/heic",
    "image/heif",
}

OUTPUT_CONTENT_TYPE = "image/webp"
OUTPUT_EXTENSION = "webp"

_FULL_QUALITY = 82
_THUMB_QUALITY = 75


class ImageRejected(Exception):
    """Upload is not usable. The message is safe to return to the client."""


def _render(data: bytes) -> tuple[bytes, bytes]:
    """Return (full, thumbnail) WebP bytes, both free of metadata."""
    try:
        with Image.open(io.BytesIO(data)) as source:
            # Honour EXIF orientation before it is discarded, then drop the
            # alpha/palette variations so WebP encoding is predictable.
            image = ImageOps.exif_transpose(source)
            if image.mode not in ("RGB", "RGBA"):
                image = image.convert("RGB")

            full = image.copy()
            full.thumbnail((settings.image_max_px, settings.image_max_px))

            thumb = image.copy()
            thumb.thumbnail((settings.thumb_max_px, settings.thumb_max_px))
    except (UnidentifiedImageError, OSError) as exc:
        raise ImageRejected("File is not a readable image") from exc

    def encode(img: Image.Image, quality: int) -> bytes:
        buffer = io.BytesIO()
        # No exif= argument: a new file is written from pixels only.
        img.save(buffer, format="WEBP", quality=quality, method=4)
        return buffer.getvalue()

    return encode(full, _FULL_QUALITY), encode(thumb, _THUMB_QUALITY)


async def process(data: bytes, content_type: str | None) -> tuple[bytes, bytes]:
    """Validate and convert an upload. Raises ImageRejected on bad input."""
    if not data:
        raise ImageRejected("File is empty")
    if len(data) > settings.max_image_bytes:
        limit_mb = settings.max_image_bytes // (1024 * 1024)
        raise ImageRejected(f"File exceeds the {limit_mb} MB limit")
    if content_type and content_type not in ALLOWED_CONTENT_TYPES:
        allowed = ", ".join(sorted(ALLOWED_CONTENT_TYPES))
        raise ImageRejected(f"Unsupported content type {content_type}. Allowed: {allowed}")

    return await asyncio.to_thread(_render, data)


def has_exif(data: bytes) -> bool:
    """True when the bytes still carry EXIF. Used by tests and manual checks."""
    try:
        with Image.open(io.BytesIO(data)) as image:
            return bool(image.getexif())
    except (UnidentifiedImageError, OSError):
        return False
