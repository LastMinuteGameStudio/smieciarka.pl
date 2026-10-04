from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db import get_db
from app.models import User
from app.schemas.auth import UserOut

router = APIRouter()


async def _set_subscribed(user: User, value: bool, db: AsyncSession) -> User:
    user.is_subscribed = value
    await db.commit()
    await db.refresh(user)
    return user


@router.post("/subscription", response_model=UserOut)
async def subscribe(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await _set_subscribed(current_user, True, db)


@router.delete("/subscription", response_model=UserOut)
async def cancel_subscription(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await _set_subscribed(current_user, False, db)
