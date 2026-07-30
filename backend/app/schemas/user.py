from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field, EmailStr, ConfigDict

class UserBase(BaseModel):
    full_name: str = Field(..., min_length=2, max_length=150)
    phone: str = Field(..., min_length=5, max_length=30)
    email: Optional[EmailStr] = None
    sicil_no: Optional[str] = None

class UserCreate(UserBase):
    invite_code: str = Field(..., min_length=4, max_length=20)
    password: str = Field(..., min_length=8)

class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    full_name: str
    phone: str
    email: Optional[str] = None
    sicil_no: Optional[str] = None
    role: str
    is_active: bool
    has_signature: bool = False
    created_at: datetime


class UserPasswordUpdate(BaseModel):
    current_password: str
    new_password: str = Field(..., min_length=8)

class UserListResponse(BaseModel):
    items: List[UserResponse]
    total: int
    page: int
    limit: int
