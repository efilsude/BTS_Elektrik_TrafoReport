import os
import uuid
from fastapi import APIRouter, Depends, UploadFile, File, Form, status
from sqlalchemy.orm import Session

from app.api.deps import get_db, get_current_user
from app.core.config import settings
from app.core.security import verify_password, get_password_hash
from app.core.exceptions import BadRequestException, InvalidCredentialsException
from app.models.user import User
from app.schemas.user import UserResponse, UserPasswordUpdate

router = APIRouter()

@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    user_resp = UserResponse.model_validate(current_user)
    user_resp.has_signature = bool(current_user.signature_path)
    return user_resp

@router.put("/me/password")
def update_password(
    password_in: UserPasswordUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not verify_password(password_in.current_password, current_user.password_hash):
        raise InvalidCredentialsException("Mevcut şifreniz hatalı.")

    current_user.password_hash = get_password_hash(password_in.new_password)
    db.commit()
    return {"message": "Şifreniz başarıyla değiştirildi."}

@router.put("/me/signature")
async def upload_signature(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not file.content_type.startswith("image/"):
        raise BadRequestException(code="INVALID_FILE_TYPE", message="Yalnızca görsel dosyaları (PNG) yüklenebilir.")

    os.makedirs(os.path.join(settings.UPLOAD_DIR, "signatures"), exist_ok=True)
    filename = f"signature_user_{current_user.id}_{uuid.uuid4().hex[:8]}.png"
    filepath = os.path.join(settings.UPLOAD_DIR, "signatures", filename)

    content = await file.read()
    with open(filepath, "wb") as f:
        f.write(content)

    current_user.signature_path = filepath
    db.commit()

    return {"message": "İmza başarıyla yüklendi.", "has_signature": True}
