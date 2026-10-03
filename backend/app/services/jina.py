"""Jina AI embeddings and reranking.

Why a reranker at all: embedding cosine scores are not calibrated, so no fixed
cutoff can separate a match from a non-match (measured: every candidate model
had negative separation on our eval set). Reranker scores are calibrated, which
is what makes the fixed threshold in the matcher viable.

Measured caveat: the reranker is diluted by extra tokens in a document. A bare
"Piłka nożna" scores 0.40 against a football query, "Piłka nożna Adidas,
rozmiar 5" scores 0.06 -- below an unrelated bookshelf. So rerank documents are
listing titles only, never title+description.
"""

import httpx

from app.config import settings

EMBED_URL = "https://api.jina.ai/v1/embeddings"
RERANK_URL = "https://api.jina.ai/v1/rerank"

EMBED_MODEL = "jina-embeddings-v3"
RERANK_MODEL = "jina-reranker-v2-base-multilingual"

TIMEOUT = httpx.Timeout(20.0)


def is_configured() -> bool:
    return bool(settings.jina_api_key)


def _headers() -> dict[str, str]:
    return {
        "Authorization": f"Bearer {settings.jina_api_key}",
        "Content-Type": "application/json",
    }


async def embed(texts: list[str], *, task: str) -> list[list[float]]:
    """Embed texts. `task` is retrieval.query for needs, retrieval.passage for listings."""
    payload = {"model": EMBED_MODEL, "task": task, "input": texts}
    async with httpx.AsyncClient(timeout=TIMEOUT) as client:
        response = await client.post(EMBED_URL, json=payload, headers=_headers())
        response.raise_for_status()
        data = response.json()
    rows = sorted(data["data"], key=lambda r: r["index"])
    return [row["embedding"] for row in rows]


async def rerank(query: str, documents: list[str]) -> list[float]:
    """Score each document against the query. Returns scores in input order."""
    if not documents:
        return []
    payload = {
        "model": RERANK_MODEL,
        "query": query,
        "documents": documents,
        "top_n": len(documents),
    }
    async with httpx.AsyncClient(timeout=TIMEOUT) as client:
        response = await client.post(RERANK_URL, json=payload, headers=_headers())
        response.raise_for_status()
        data = response.json()

    scores = [0.0] * len(documents)
    for result in data["results"]:
        scores[result["index"]] = result["relevance_score"]
    return scores
