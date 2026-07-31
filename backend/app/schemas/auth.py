from typing import Optional
from pydantic import BaseModel, EmailStr, Field
from app.schemas.user import UserResponse

class VerificationRequest(BaseModel):
    email: EmailStr
    invite_code: str = Field(..., min_length=4, max_length=20)

class VerificationResponse(BaseModel):
    message: str
    expires_in_seconds: int
    debug_code: Optional[str] = None


class LoginRequest(BaseModel):
    identifier: str
    password: str

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserResponse

class RefreshTokenRequest(BaseModel):
    refresh_token: str

class RefreshTokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
