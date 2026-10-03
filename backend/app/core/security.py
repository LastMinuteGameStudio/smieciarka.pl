import uuid
from datetime import datetime, timedelta, timezone

import jwt

from app.config import settings

ALGORITHM = "HS256"

MOCK_OTP_CODE = "123456"


def _create_token(user_id: uuid.UUID, ttl_seconds: int, token_type: str) -> str:
    now = datetime.now(timezone.utc)
    payload = {
        "sub": str(user_id),
        "type": token_type,
        "iat": now,
        "exp": now + timedelta(seconds=ttl_seconds),
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=ALGORITHM)


def create_access_token(user_id: uuid.UUID) -> str:
    return _create_token(user_id, settings.jwt_access_ttl, "access")


def create_refresh_token(user_id: uuid.UUID) -> str:
    return _create_token(user_id, settings.jwt_refresh_ttl, "refresh")


def decode_token(token: str) -> dict:
    return jwt.decode(token, settings.jwt_secret, algorithms=[ALGORITHM])
