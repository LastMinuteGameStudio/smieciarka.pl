import uuid
from datetime import datetime

from pydantic import BaseModel


class PhoneStartRequest(BaseModel):
    phone_number: str


class PhoneVerifyRequest(BaseModel):
    phone_number: str
    code: str


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
    created_at: datetime

    class Config:
        from_attributes = True
