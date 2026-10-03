"""Reversed search: a new listing is the query, saved filters are the corpus.

Two stages, because the two jobs need different tools:

1. Cosine prefilter in Postgres. pgvector ranks filters well and cheaply, and
   the area predicate runs in the same query. The threshold here is loose on
   purpose -- cosine scores are uncalibrated, so this stage only nominates
   candidates.
2. Reranker decides. Reranker scores are calibrated, so a fixed threshold is
   meaningful. This is the stage that says "notify".

Without stage 2 the matcher is unusable: on the eval set no cosine threshold
separated matches from non-matches for any model tried (best worst-case
separation -0.007). With it, separation is +0.041.

If the reranker is unavailable the matcher falls back to cosine with a loose
threshold, which over-notifies rather than silently notifying nobody.
"""

import asyncio
import logging

from sqlalchemy import and_, func, or_, select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.models import AreaType, Listing, Notification, WatchFilter
from app.services import jina
from app.services.geo import distance_m_expr

logger = logging.getLogger(__name__)

# One rerank call per candidate filter, so cap in-flight calls per listing.
_RERANK_CONCURRENCY = 10


async def match_listing_to_filters(listing: Listing, db: AsyncSession) -> int:
    """Notify users whose filters match this listing. Returns notifications created."""
    candidates = await _candidate_filters(listing, db)
    if not candidates:
        return 0

    if jina.is_configured():
        matches = await _decide_by_rerank(listing, candidates)
    else:
        logger.warning("Jina not configured: falling back to uncalibrated cosine matching")
        matches = [
            (f_id, user_id, score)
            for f_id, user_id, score, _ in candidates
            if score >= settings.match_threshold_low
        ]

    created = 0
    for filter_id, user_id, score in matches:
        result = await db.execute(
            pg_insert(Notification)
            .values(user_id=user_id, listing_id=listing.id, filter_id=filter_id, score=score)
            .on_conflict_do_nothing(index_elements=["user_id", "listing_id"])
        )
        created += result.rowcount or 0

    await db.commit()
    return created


async def _candidate_filters(listing: Listing, db: AsyncSession):
    """Area-eligible filters whose cosine score clears the loose prefilter."""
    score_expr = 1 - WatchFilter.embedding.cosine_distance(listing.embedding)

    area_match = or_(
        WatchFilter.area_type == AreaType.nationwide,
        and_(
            WatchFilter.area_type == AreaType.radius,
            WatchFilter.center_lat.is_not(None),
            WatchFilter.center_lng.is_not(None),
            WatchFilter.radius_m.is_not(None),
            distance_m_expr(listing.lat, listing.lng, WatchFilter.center_lat, WatchFilter.center_lng)
            <= WatchFilter.radius_m,
        ),
    )

    stmt = (
        select(
            WatchFilter.id,
            WatchFilter.user_id,
            score_expr.label("score"),
            func.coalesce(WatchFilter.expanded_query, WatchFilter.query).label("need"),
        )
        .where(WatchFilter.is_active.is_(True))
        .where(WatchFilter.user_id != listing.author_id)
        .where(area_match)
        .where(score_expr >= settings.match_candidate_threshold)
        .order_by(score_expr.desc())
        .limit(settings.match_candidate_limit)
    )
    return (await db.execute(stmt)).all()


async def _decide_by_rerank(listing: Listing, candidates):
    """Score the listing against each candidate need, keep those over threshold.

    One call per candidate, because the reranker is not symmetric and only one
    direction is calibrated: the need must be the query and the listing title
    the document. Measured on the eval set -- need-as-query separates (+0.041),
    listing-as-query does not (-0.215). Batching every need into one call would
    use the broken direction, so the calls are made in parallel instead.

    The document is the title alone: appending the description measurably
    dilutes reranker scores (see services/jina.py).
    """
    semaphore = asyncio.Semaphore(_RERANK_CONCURRENCY)

    async def score_one(need: str) -> float | None:
        async with semaphore:
            try:
                (score,) = await jina.rerank(need, [listing.title])
                return score
            except Exception:
                logger.exception("rerank failed for listing %s need %r", listing.id, need)
                return None

    scores = await asyncio.gather(*(score_one(need) for _, _, _, need in candidates))

    matches = []
    for (filter_id, user_id, _, _), score in zip(candidates, scores):
        if score is not None and score >= settings.match_rerank_threshold:
            matches.append((filter_id, user_id, score))
    return matches
