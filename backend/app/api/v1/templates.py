import os
import uuid
from typing import List
from fastapi import APIRouter, Depends, UploadFile, File, Form, status
from sqlalchemy.orm import Session

from app.api.deps import get_db, get_current_user, get_current_active_admin
from app.core.config import settings
from app.core.exceptions import BadRequestException
from app.models.template import Template
from app.models.user import User
from app.schemas.template import TemplateResponse

router = APIRouter()

@router.get("", response_model=List[TemplateResponse])
def list_templates(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    templates = db.query(Template).order_by(Template.uploaded_at.desc()).all()
    
    # Initial fallback if DB is empty: seed default canonical templates
    if not templates:
        defaults = [
            ("HERMETİK TRAFO BAKIM RAPORU HİLMİ.xlsx", "HERMETIK", "templates/HERMETİK TRAFO BAKIM RAPORU HİLMİ.xlsx"),
            ("KURU TİP HİLMİ.xlsx", "KURU_TIP", "templates/KURU TİP HİLMİ.xlsx"),
            ("TR BAKIM RAPORU GT HİLMİ.xlsx", "GT", "templates/TR BAKIM RAPORU GT HİLMİ.xlsx")
        ]
        for name, r_type, path in defaults:
            t = Template(name=name, report_type=r_type, file_path=path, version="1.0")
            db.add(t)
        db.commit()
        templates = db.query(Template).order_by(Template.uploaded_at.desc()).all()

    return [TemplateResponse.model_validate(t) for t in templates]

@router.post("/admin/upload", response_model=TemplateResponse, status_code=status.HTTP_201_CREATED)
async def upload_template(
    name: str = Form(..., min_length=2),
    report_type: str = Form(..., description="HERMETIK, KURU_TIP, GT"),
    version: str = Form("1.1"),
    file: UploadFile = File(...),
    current_admin: User = Depends(get_current_active_admin),
    db: Session = Depends(get_db)
):
    if not file.filename.endswith(".xlsx"):
        raise BadRequestException(code="INVALID_TEMPLATE", message="Yalnızca .xlsx uzantılı Excel şablon dosyaları yüklenebilir.")

    os.makedirs(os.path.join(settings.UPLOAD_DIR, "templates"), exist_ok=True)
    filename = f"template_{report_type.lower()}_{uuid.uuid4().hex[:8]}.xlsx"
    filepath = os.path.join(settings.UPLOAD_DIR, "templates", filename)

    content = await file.read()
    with open(filepath, "wb") as f:
        f.write(content)

    new_template = Template(
        name=name.strip(),
        report_type=report_type.strip().upper(),
        file_path=filepath,
        version=version.strip()
    )
    db.add(new_template)
    db.commit()
    db.refresh(new_template)

    return TemplateResponse.model_validate(new_template)
