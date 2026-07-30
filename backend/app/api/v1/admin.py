import random
import string
from datetime import datetime, timezone, timedelta
from typing import Optional, List
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import or_

from app.api.deps import get_db, get_current_active_admin
from app.core.config import settings
from app.core.exceptions import NotFoundException, BadRequestException
from app.models.user import User
from app.models.code import RegistrationCode
from app.schemas.user import UserResponse, UserListResponse
from app.schemas.code import CodeCreate, CodeResponse

router = APIRouter()

def generate_random_code(length: int = 8) -> str:
    chars = string.ascii_uppercase + string.digits
    return ''.join(random.choice(chars) for _ in range(length))

@router.post("/codes", response_model=CodeResponse, status_code=status.HTTP_201_CREATED)
def create_registration_code(
    code_in: Optional[CodeCreate] = None,
    current_admin: User = Depends(get_current_active_admin),
    db: Session = Depends(get_db)
):
    code_str = code_in.code.strip().upper() if (code_in and code_in.code) else generate_random_code()
    
    # Check if code already exists
    existing = db.query(RegistrationCode).filter(RegistrationCode.code == code_str).first()
    if existing:
        raise BadRequestException(code="CODE_EXISTS", message="Bu davet kodu zaten mevcut.")

    now = datetime.now(timezone.utc)
    expires_at = now + timedelta(minutes=settings.INVITE_CODE_TTL_MINUTES)

    reg_code = RegistrationCode(
        code=code_str,
        created_by=current_admin.id,
        expires_at=expires_at,
        created_at=now
    )
    db.add(reg_code)
    db.commit()
    db.refresh(reg_code)

    resp = CodeResponse.model_validate(reg_code)
    resp.is_valid = reg_code.is_valid
    return resp

@router.get("/codes", response_model=List[CodeResponse])
def list_registration_codes(
    current_admin: User = Depends(get_current_active_admin),
    db: Session = Depends(get_db)
):
    codes = db.query(RegistrationCode).order_by(RegistrationCode.created_at.desc()).limit(50).all()
    results = []
    for c in codes:
        item = CodeResponse.model_validate(c)
        item.is_valid = c.is_valid
        results.append(item)
    return results

@router.get("/users", response_model=UserListResponse)
def list_users(
    search: Optional[str] = Query(None, description="İsim, telefon veya sicil no araması"),
    role: Optional[str] = Query(None, description="admin veya employee"),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    current_admin: User = Depends(get_current_active_admin),
    db: Session = Depends(get_db)
):
    query = db.query(User)
    
    if search:
        search_pattern = f"%{search.strip()}%"
        query = query.filter(
            or_(
                User.full_name.ilike(search_pattern),
                User.phone.ilike(search_pattern),
                User.email.ilike(search_pattern),
                User.sicil_no.ilike(search_pattern)
            )
        )
    
    if role:
        query = query.filter(User.role == role.strip())

    total = query.count()
    users = query.order_by(User.created_at.desc()).offset((page - 1) * limit).limit(limit).all()

    items = []
    for u in users:
        item = UserResponse.model_validate(u)
        item.has_signature = bool(u.signature_path)
        items.append(item)

    return UserListResponse(items=items, total=total, page=page, limit=limit)

@router.delete("/users/{user_id}")
def deactivate_user(
    user_id: int,
    current_admin: User = Depends(get_current_active_admin),
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise NotFoundException("Kullanıcı bulunamadı.")
    
    if user.id == current_admin.id:
        raise BadRequestException(code="CANNOT_DELETE_SELF", message="Kendi admin hesabınızı devre dışı bırakamazsınız.")

    # Soft delete / deactivate user (preserves reports creator_display_name ownership)
    user.is_active = False
    db.commit()

    return {"message": "Kullanıcı devre dışı bırakıldı.", "user_id": user_id}
