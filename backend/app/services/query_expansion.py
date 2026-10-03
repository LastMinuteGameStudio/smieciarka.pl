"""Expand a short filter query into concrete item names (spec section 6.2).

Not optional. A filter like "rzeczy do gry w piłkę nożną" is abstract, and both
the embedder and the reranker score it poorly against concrete listings like
"rękawice bramkarskie". Measured on our eval set: with the raw query the
reranker cannot separate matches from non-matches at any threshold (worst-case
separation -0.116); with expansion it separates cleanly (+0.041).

Phrasing templates were tried instead and all failed -- the gain comes from
world knowledge about which objects belong to a need, not from wording.

Expansion runs once per filter at creation and is stored, so this costs a
handful of LLM calls per user, not one per listing.
"""

import logging

import httpx

from app.config import settings

logger = logging.getLogger(__name__)

GEMINI_URL_TEMPLATE = (
    "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
)

PROMPT = """Użytkownik szuka rzeczy oddawanych za darmo i opisał swoją potrzebę tak:
"{query}"

Wypisz po przecinku 8-12 konkretnych nazw przedmiotów, które pasują do tej potrzeby.
Używaj nazw, jakie ludzie wpisują w ogłoszeniach. Bez numeracji, bez komentarza.
Odpowiedz jedną linią w formacie: {query}: przedmiot1, przedmiot2, przedmiot3"""


def is_configured() -> bool:
    return bool(settings.gemini_api_key)


async def expand_query(query: str) -> str | None:
    """Return the expanded query, or None if expansion is unavailable or fails.

    Callers fall back to the raw query: matching degrades but stays functional.
    """
    if not is_configured():
        return None

    payload = {
        "contents": [{"parts": [{"text": PROMPT.format(query=query)}]}],
        "generationConfig": {"temperature": 0.2, "maxOutputTokens": 2048},
    }
    try:
        async with httpx.AsyncClient(timeout=httpx.Timeout(20.0)) as client:
            response = await client.post(
                GEMINI_URL_TEMPLATE.format(model=settings.gemini_model),
                json=payload,
                headers={
                    "x-goog-api-key": settings.gemini_api_key,
                    "Content-Type": "application/json",
                },
            )
            response.raise_for_status()
            data = response.json()
        text = data["candidates"][0]["content"]["parts"][0]["text"].strip()
    except Exception:
        logger.exception("query expansion failed for %r, falling back to raw query", query)
        return None

    # Collapse to one line: the embedder and reranker both take a single string.
    expanded = " ".join(text.split())
    return expanded or None
