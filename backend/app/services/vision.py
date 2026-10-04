"""Describe a listing photo with Gemini (spec section 5.1).

The caption exists to make a listing findable by what is in its picture, for
the common case where someone photographs an item and writes a two-word
title. It is appended to the embedding text, never shown as the author's own
description.

The thumbnail is sent, not the full image: the caption only needs to name
objects, and the smaller payload keeps the call fast and cheap.

Failure is not fatal. The upload has already succeeded by the time this runs,
so a caption that cannot be produced is logged and skipped -- the listing
keeps working with whatever text it had.
"""

import base64
import logging

import httpx

from app.config import settings

logger = logging.getLogger(__name__)

GEMINI_URL_TEMPLATE = (
    "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
)

PROMPT = """Opisz krótko, co widzisz na zdjęciu przedmiotu oddawanego za darmo.
Wypisz nazwę przedmiotu, kolor, materiał i stan, jeśli są widoczne.
Jedno zdanie, maksymalnie 20 słów, bez komentarza i bez oceny wartości."""

MAX_CAPTION_CHARS = 300


def is_configured() -> bool:
    return settings.vision_enabled and bool(settings.gemini_api_key)


async def caption(image_bytes: bytes, content_type: str = "image/webp") -> str | None:
    """Return a one-sentence description, or None if unavailable or failed."""
    if not is_configured():
        return None

    payload = {
        "contents": [
            {
                "parts": [
                    {"text": PROMPT},
                    {
                        "inline_data": {
                            "mime_type": content_type,
                            "data": base64.b64encode(image_bytes).decode("ascii"),
                        }
                    },
                ]
            }
        ],
        "generationConfig": {"temperature": 0.2, "maxOutputTokens": 2048},
    }

    try:
        async with httpx.AsyncClient(timeout=httpx.Timeout(30.0)) as client:
            response = await client.post(
                GEMINI_URL_TEMPLATE.format(model=settings.gemini_vision_model),
                json=payload,
                headers={
                    "x-goog-api-key": settings.gemini_api_key,
                    "Content-Type": "application/json",
                },
            )
            response.raise_for_status()
            data = response.json()
        text = data["candidates"][0]["content"]["parts"][0]["text"]
    except Exception:
        logger.exception("vision captioning failed, listing keeps its current text")
        return None

    collapsed = " ".join(text.split())[:MAX_CAPTION_CHARS]
    return collapsed or None
