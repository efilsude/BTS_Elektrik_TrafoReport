from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict

class CodeCreate(BaseModel):
    code: Optional[str] = None

class CodeResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    code: str
    created_by: int
    expires_at: datetime
    created_at: datetime
    used_at: Optional[datetime] = None
    used_by_user_id: Optional[int] = None
    is_valid: bool

