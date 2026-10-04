"""Embedding provider abstraction.

Two providers, chosen by EMBEDDING_PROVIDER:

- jina: hosted jina-embeddings-v3, 1024-dim, asymmetric query/passage tasks.
  What the matcher is calibrated against.
- fastembed: local multilingual MiniLM, 384-dim, no network. Ranking is usable
  but absolute scores are not separable, so the reranked matcher is required
  for notifications to behave. Kept as an offline fallback.

Switching provider changes the vector dimension, so it needs a migration and a
reindex of every listing and filter -- vectors from different models are not
comparable (spec section 11).
"""

import asyncio

from app.config import settings
from app.services import jina

_local_model = None


def _get_local_model():
    global _local_model
    if _local_model is None:
        from fastembed import TextEmbedding

        _local_model = TextEmbedding(model_name=settings.embedding_model)
    return _local_model


def _embed_local_sync(text: str) -> list[float]:
    model = _get_local_model()
    (embedding,) = model.embed([text])
    return embedding.tolist()


def _use_jina() -> bool:
    if settings.embedding_provider != "jina":
        return False
    if not jina.is_configured():
        # Falling back silently would emit 384-dim vectors into a 1024-dim
        # column and surface as an opaque pgvector dimension error on insert.
        raise RuntimeError(
            "EMBEDDING_PROVIDER=jina but JINA_API_KEY is empty. Set the key "
            "(free: https://jina.ai/embeddings), or switch to the local model "
            "with EMBEDDING_PROVIDER=fastembed + EMBEDDING_DIM=384 and run "
            "'alembic downgrade f810b33664ea' to resize the vector columns."
        )
    return True


def listing_text(title: str, description: str | None, image_caption: str | None) -> str:
    """Build the text a listing is embedded from (spec section 5.1).

    One place for the format, because it is built twice: when the listing is
    created, and again after a photo upload adds a caption. The two must agree
    or a reindex would silently change what a listing means.
    """
    parts = [title, description, image_caption]
    return ". ".join(part.strip() for part in parts if part and part.strip())


async def embed_passage(text: str) -> list[float]:
    """Embed a listing (the indexed side)."""
    if _use_jina():
        (vector,) = await jina.embed([text], task="retrieval.passage")
        return vector
    return await asyncio.to_thread(_embed_local_sync, text)


async def embed_query(text: str) -> list[float]:
    """Embed a search query or filter need (the querying side)."""
    if _use_jina():
        (vector,) = await jina.embed([text], task="retrieval.query")
        return vector
    return await asyncio.to_thread(_embed_local_sync, text)
