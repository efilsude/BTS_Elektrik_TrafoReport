from typing import Optional
from pydantic import BaseModel, EmailStr, Field
from app.schemas.user import UserResponse

class BootstrapStatusResponse(BaseModel):
    needs_bootstrap: bool

class VerificationRequestBootstrap(BaseModel):
    email: EmailStr

class BootstrapCreate(BaseModel):
    full_name: str = Field(..., min_length=2, max_length=100)
    phone: str = Field(..., min_length=10, max_length=20)
    email: EmailStr
    sicil_no: Optional[str] = Field(None, max_length=50)
    password: str = Field(..., min_length=8)
    verification_code: str = Field(..., min_length=6, max_length=6)

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
