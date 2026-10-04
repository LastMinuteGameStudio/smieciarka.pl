import uuid
from datetime import datetime

from pydantic import BaseModel, Field

# E.164: leading +, country code, 7-14 more digits.
E164_PATTERN = r"^\+[1-9]\d{7,14}$"


class PhoneStartRequest(BaseModel):
    phone_number: str = Field(..., pattern=E164_PATTERN)


class PhoneVerifyRequest(BaseModel):
    phone_number: str = Field(..., pattern=E164_PATTERN)
    code: str = Field(..., pattern=r"^\d{6}$")


class RefreshRequest(BaseModel):
    refresh_token: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class UserOut(BaseModel):
    id: uuid.UUID
    phone_number: str
    display_name: str | None
    is_subscribed: bool
    created_at: datetime

    class Config:
        from_attributes = True
