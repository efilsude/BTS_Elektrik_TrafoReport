from datetime import datetime, timezone, timedelta
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from sqlalchemy import or_

from app.api.deps import get_db
from app.db.session import SessionLocal
from app.core.security import (
    verify_password,
    get_password_hash,
    create_access_token,
    create_refresh_token,
    decode_token
)
from app.core.exceptions import (
    InviteCodeInvalidException,
    UserAlreadyExistsException,
    InvalidCredentialsException,
    UnauthorizedException
)
from app.models.user import User
from app.models.code import RegistrationCode
from app.schemas.user import UserCreate, UserResponse
from app.schemas.auth import LoginRequest, TokenResponse, RefreshTokenRequest, RefreshTokenResponse

router = APIRouter()

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(
    user_in: UserCreate,
    db: Session = Depends(get_db)
):
    # 1. Validate invite code
    code_record = db.query(RegistrationCode).filter(
        RegistrationCode.code == user_in.invite_code.strip().upper()
    ).first()

    if not code_record or not code_record.is_valid:
        raise InviteCodeInvalidException()

    # 2. Check if user already exists with phone, email, or sicil_no
    conditions = [User.phone == user_in.phone.strip()]
    if user_in.email:
        conditions.append(User.email == user_in.email.strip())
    if user_in.sicil_no:
        conditions.append(User.sicil_no == user_in.sicil_no.strip())
    
    existing_user = db.query(User).filter(or_(*conditions)).first()
    if existing_user:
        raise UserAlreadyExistsException()

    # 3. Create user
    new_user = User(
        full_name=user_in.full_name.strip(),
        phone=user_in.phone.strip(),
        email=user_in.email.strip() if user_in.email else None,
        sicil_no=user_in.sicil_no.strip() if user_in.sicil_no else None,
        password_hash=get_password_hash(user_in.password),
        role="employee",
        is_active=True
    )
    db.add(new_user)
    db.flush()  # get new_user.id

    # 4. Mark code as used
    now = datetime.now(timezone.utc)
    code_record.used_at = now
    code_record.used_by_user_id = new_user.id
    
    db.commit()
    db.refresh(new_user)

    user_resp = UserResponse.model_validate(new_user)
    user_resp.has_signature = bool(new_user.signature_path)
    return user_resp

@router.post("/login", response_model=TokenResponse)
def login(
    login_in: LoginRequest,
    db: Session = Depends(get_db)
):
    identifier = login_in.identifier.strip()
    
    # User can login with phone, email, or sicil_no
    user = db.query(User).filter(
        or_(
            User.phone == identifier,
            User.email == identifier,
            User.sicil_no == identifier
        )
    ).first()

    if not user or not verify_password(login_in.password, user.password_hash):
        raise InvalidCredentialsException()

    if not user.is_active:
        raise UnauthorizedException("Kullanıcı hesabı devre dışı bırakılmış.")

    access_token = create_access_token(subject=user.id)
    refresh_token = create_refresh_token(subject=user.id)

    user_resp = UserResponse.model_validate(user)
    user_resp.has_signature = bool(user.signature_path)

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        user=user_resp
    )

@router.post("/refresh", response_model=RefreshTokenResponse)
def refresh_token(
    refresh_in: RefreshTokenRequest,
    db: Session = Depends(get_db)
):
    payload = decode_token(refresh_in.refresh_token)
    if not payload or payload.get("type") != "refresh":
        raise UnauthorizedException("Geçersiz veya süresi dolmuş refresh token.")

    user_id = payload.get("sub")
    user = db.query(User).filter(User.id == int(user_id)).first()
    if not user or not user.is_active:
        raise UnauthorizedException("Kullanıcı aktif değil veya bulunamadı.")

    new_access_token = create_access_token(subject=user.id)
    return RefreshTokenResponse(access_token=new_access_token, token_type="bearer")
