from sqlalchemy import and_, func, or_, select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.models import AreaType, Listing, Notification, WatchFilter
from app.services.geo import distance_m_expr


async def match_listing_to_filters(listing: Listing, db: AsyncSession) -> None:
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
        select(WatchFilter.id, WatchFilter.user_id, score_expr.label("score"))
        .where(WatchFilter.is_active.is_(True))
        .where(WatchFilter.user_id != listing.author_id)
        .where(area_match)
        .where(score_expr >= func.coalesce(WatchFilter.min_score, settings.match_threshold_low))
    )

    rows = (await db.execute(stmt)).all()

    for filter_id, user_id, score in rows:
        insert_stmt = (
            pg_insert(Notification)
            .values(user_id=user_id, listing_id=listing.id, filter_id=filter_id, score=score)
            .on_conflict_do_nothing(index_elements=["user_id", "listing_id"])
        )
        await db.execute(insert_stmt)

    await db.commit()
