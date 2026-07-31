import random
from datetime import datetime, timezone, timedelta
from fastapi import APIRouter, Depends, status, BackgroundTasks
from sqlalchemy.orm import Session
from sqlalchemy import or_

from app.api.deps import get_db
from app.core.config import settings
from app.core.security import (
    verify_password,
    get_password_hash,
    create_access_token,
    create_refresh_token,
    decode_token
)
from app.core.exceptions import (
    InviteCodeInvalidException,
    VerificationCodeInvalidException,
    VerificationCodeExpiredException,
    UserAlreadyExistsException,
    InvalidCredentialsException,
    UnauthorizedException,
    BadRequestException
)
from app.models.user import User
from app.models.code import RegistrationCode
from app.models.email_verification import EmailVerificationCode
from app.schemas.user import UserCreate, UserResponse
from app.schemas.auth import (
    LoginRequest,
    TokenResponse,
    RefreshTokenRequest,
    RefreshTokenResponse,
    VerificationRequest,
    VerificationResponse
)
from app.services.email_service import send_email, notify_admins_for_new_user

router = APIRouter()

@router.post("/request-verification", response_model=VerificationResponse)
def request_verification_code(
    ver_in: VerificationRequest,
    db: Session = Depends(get_db)
):
    email_clean = ver_in.email.strip().lower()
    invite_code_clean = ver_in.invite_code.strip().upper()

    # 1. Validate invite code
    code_record = db.query(RegistrationCode).filter(
        RegistrationCode.code == invite_code_clean
    ).first()

    if not code_record or not code_record.is_valid:
        raise InviteCodeInvalidException()

    # 2. Check if email is already registered to an active user
    existing_user = db.query(User).filter(User.email == email_clean).first()
    if existing_user:
        raise UserAlreadyExistsException("Bu e-posta adresi ile kayıtlı kullanıcı zaten var.")

    # 3. Simple rate limiting: max 1 code per 60 seconds per email
    now = datetime.now(timezone.utc)
    last_code = db.query(EmailVerificationCode).filter(
        EmailVerificationCode.email == email_clean
    ).order_by(EmailVerificationCode.created_at.desc()).first()

    if last_code:
        created = last_code.created_at
        if created.tzinfo is None:
            created = created.replace(tzinfo=timezone.utc)
        if (now - created).total_seconds() < 60:
            raise BadRequestException(
                code="RATE_LIMIT_EXCEEDED",
                message="Lütfen yeni doğrulama kodu istemeden önce 60 saniye bekleyin."
            )

    # 4. Generate 6-digit verification code
    generated_code = f"{random.randint(100000, 999999)}"
    ttl_minutes = settings.VERIFICATION_CODE_TTL_MINUTES
    expires_at = now + timedelta(minutes=ttl_minutes)

    ver_record = EmailVerificationCode(
        email=email_clean,
        code=generated_code,
        purpose="register",
        expires_at=expires_at,
        created_at=now
    )
    db.add(ver_record)

    # 5. Send Turkish email
    subject = "[TrafoReport] E-posta Doğrulama Kodunuz"
    html_body = f"""
    <div style="font-family: Arial, sans-serif; padding: 20px; color: #333;">
      <h2 style="color: #1E3A8A;">TrafoReport E-posta Doğrulama</h2>
      <p>TrafoReport kayıt işleminizi tamamlamak için doğrulama kodunuz:</p>
      <div style="background-color: #F8FAFC; border: 1px solid #E2E8F0; padding: 15px; text-align: center; border-radius: 8px; margin: 20px 0;">
        <span style="font-size: 28px; font-weight: bold; letter-spacing: 6px; color: #1E3A8A;">{generated_code}</span>
      </div>
      <p>Bu kod <b>{ttl_minutes} dakika</b> süreyle geçerlidir.</p>
      <p style="font-size: 12px; color: #64748B;">Eğer bu isteği siz yapmadıysanız, lütfen bu e-postayı dikkate almayın.</p>
    </div>
    """

    send_email(
        to=email_clean,
        subject=subject,
        html_body=html_body,
        raise_on_error=True
    )

    db.commit()

    debug_code = generated_code if not settings.EMAIL_ENABLED else None

    return VerificationResponse(
        message="Doğrulama kodu e-posta adresinize gönderildi.",
        expires_in_seconds=ttl_minutes * 60,
        debug_code=debug_code
    )



@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(
    user_in: UserCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    email_clean = user_in.email.strip().lower()
    invite_code_clean = user_in.invite_code.strip().upper()
    ver_code_clean = user_in.verification_code.strip()

    # 1. Validate invite code
    code_record = db.query(RegistrationCode).filter(
        RegistrationCode.code == invite_code_clean
    ).first()

    if not code_record or not code_record.is_valid:
        raise InviteCodeInvalidException()

    # 2. Validate email verification code
    ver_record = db.query(EmailVerificationCode).filter(
        EmailVerificationCode.email == email_clean,
        EmailVerificationCode.code == ver_code_clean,
        EmailVerificationCode.purpose == "register"
    ).order_by(EmailVerificationCode.created_at.desc()).first()

    if not ver_record or ver_record.used_at is not None:
        raise VerificationCodeInvalidException()

    if not ver_record.is_valid:
        raise VerificationCodeExpiredException()

    # 3. Check if user already exists with phone, email, or sicil_no
    conditions = [User.phone == user_in.phone.strip(), User.email == email_clean]
    if user_in.sicil_no:
        conditions.append(User.sicil_no == user_in.sicil_no.strip())
    
    existing_user = db.query(User).filter(or_(*conditions)).first()
    if existing_user:
        raise UserAlreadyExistsException()

    # 4. Create user
    new_user = User(
        full_name=user_in.full_name.strip(),
        phone=user_in.phone.strip(),
        email=email_clean,
        sicil_no=user_in.sicil_no.strip() if user_in.sicil_no else None,
        password_hash=get_password_hash(user_in.password),
        role="employee",
        is_active=True
    )
    db.add(new_user)
    db.flush()  # get new_user.id

    # 5. Mark verification code and invite code as used
    now = datetime.now(timezone.utc)
    ver_record.used_at = now
    code_record.used_at = now
    code_record.used_by_user_id = new_user.id
    
    db.commit()
    db.refresh(new_user)

    # 6. Notify admins in background
    background_tasks.add_task(notify_admins_for_new_user, new_user.id)

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
