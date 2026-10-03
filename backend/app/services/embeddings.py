import asyncio

from fastembed import TextEmbedding

from app.config import settings

_model: TextEmbedding | None = None


def _get_model() -> TextEmbedding:
    global _model
    if _model is None:
        _model = TextEmbedding(model_name=settings.embedding_model)
    return _model


def _embed_sync(text: str) -> list[float]:
    model = _get_model()
    (embedding,) = model.embed([text])
    return embedding.tolist()


async def embed_passage(text: str) -> list[float]:
    return await asyncio.to_thread(_embed_sync, text)


async def embed_query(text: str) -> list[float]:
    return await asyncio.to_thread(_embed_sync, text)
