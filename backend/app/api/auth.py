import logging
import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.config import settings
from app.core.security import (
    MOCK_OTP_CODE,
    create_access_token,
    create_refresh_token,
    decode_token,
)
from app.db import get_db
from app.models import User
from app.schemas.auth import (
    PhoneStartRequest,
    PhoneVerifyRequest,
    RefreshRequest,
    TokenResponse,
    UserOut,
)

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post("/auth/phone/start", status_code=status.HTTP_200_OK)
async def phone_start(body: PhoneStartRequest):
    if settings.otp_mock:
        logger.info("OTP code for %s is %s (mock mode)", body.phone_number, MOCK_OTP_CODE)
        return {"ok": True}
    raise HTTPException(status_code=501, detail="Real SMS provider not configured")


@router.post("/auth/phone/verify", response_model=TokenResponse)
async def phone_verify(body: PhoneVerifyRequest, db: AsyncSession = Depends(get_db)):
    if not settings.otp_mock or body.code != MOCK_OTP_CODE:
        raise HTTPException(status_code=400, detail="Invalid code")

    result = await db.execute(select(User).where(User.phone_number == body.phone_number))
    user = result.scalar_one_or_none()
    if user is None:
        user = User(phone_number=body.phone_number)
        db.add(user)
        await db.flush()

    if user.phone_verified_at is None:
        from datetime import datetime, timezone

        user.phone_verified_at = datetime.now(timezone.utc)

    await db.commit()

    return TokenResponse(
        access_token=create_access_token(user.id),
        refresh_token=create_refresh_token(user.id),
    )


@router.post("/auth/refresh", response_model=TokenResponse)
async def refresh(body: RefreshRequest):
    try:
        payload = decode_token(body.refresh_token)
        if payload.get("type") != "refresh":
            raise ValueError("wrong token type")
        user_id = uuid.UUID(payload["sub"])
    except Exception as exc:
        raise HTTPException(status_code=401, detail="Invalid refresh token") from exc

    return TokenResponse(
        access_token=create_access_token(user_id),
        refresh_token=create_refresh_token(user_id),
    )


@router.post("/auth/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout():
    return None


@router.get("/me", response_model=UserOut)
async def me(current_user: User = Depends(get_current_user)):
    return current_user
