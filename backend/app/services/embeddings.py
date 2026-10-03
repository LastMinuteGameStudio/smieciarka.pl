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
    return settings.embedding_provider == "jina" and jina.is_configured()


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
