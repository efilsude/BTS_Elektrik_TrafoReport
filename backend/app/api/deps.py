from typing import Generator
from fastapi import Depends, Header
from sqlalchemy.orm import Session
from app.db.session import SessionLocal
from app.core.security import decode_token
from app.core.exceptions import UnauthorizedException, ForbiddenException
from app.models.user import User

def get_db() -> Generator:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_current_user(
    authorization: str = Header(..., description="Bearer <token>"),
    db: Session = Depends(get_db)
) -> User:
    if not authorization or not authorization.startswith("Bearer "):
        raise UnauthorizedException("Giriş başlığı geçersiz (Bearer token gerekli).")
    
    token = authorization.split(" ")[1]
    payload = decode_token(token)
    
    if not payload or payload.get("type") != "access":
        raise UnauthorizedException("Geçersiz veya süresi dolmuş access token.")
    
    user_id = payload.get("sub")
    if not user_id:
        raise UnauthorizedException("Geçersiz token içeriği.")
    
    user = db.query(User).filter(User.id == int(user_id)).first()
    if not user:
        raise UnauthorizedException("Kullanıcı bulunamadı.")
    
    if not user.is_active:
        raise UnauthorizedException("Kullanıcı hesabı devre dışı bırakılmış.")
    
    return user

def get_current_active_admin(
    current_user: User = Depends(get_current_user)
) -> User:
    if current_user.role != "admin":
        raise ForbiddenException("Bu işlem için yönetici (admin) yetkisi gereklidir.")
    return current_user
