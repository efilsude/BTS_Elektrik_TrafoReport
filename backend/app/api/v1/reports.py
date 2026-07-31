import os
import uuid
from typing import Optional, List
from fastapi import APIRouter, Depends, Query, UploadFile, File, Form, status, BackgroundTasks

from sqlalchemy.orm import Session
from sqlalchemy import or_

from app.api.deps import get_db, get_current_user
from app.core.config import settings
from app.core.exceptions import NotFoundException, ForbiddenException, BadRequestException
from app.models.user import User
from app.models.report import Report
from app.models.photo import Photo
from app.schemas.report import ReportCreate, ReportUpdate, ReportResponse, ReportListResponse
from app.schemas.photo import PhotoResponse

router = APIRouter()

@router.get("", response_model=ReportListResponse)
def list_reports(
    search: Optional[str] = Query(None, description="Müşteri adı, trafo etiketi veya oluşturan adı araması"),
    report_type: Optional[str] = Query(None, description="HERMETIK, KURU_TIP, GT"),
    maintenance_type: Optional[str] = Query(None, description="maintenance veya test"),
    status_filter: Optional[str] = Query(None, alias="status", description="draft veya final"),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    query = db.query(Report)

    if search:
        pattern = f"%{search.strip()}%"
        query = query.filter(
            or_(
                Report.customer_name.ilike(pattern),
                Report.trafo_label.ilike(pattern),
                Report.creator_display_name.ilike(pattern),
                Report.title.ilike(pattern),
                Report.data_json_raw.ilike(pattern)
            )
        )

    if report_type:
        query = query.filter(Report.report_type == report_type.strip())

    if maintenance_type:
        query = query.filter(Report.maintenance_type == maintenance_type.strip())

    if status_filter:
        query = query.filter(Report.status == status_filter.strip())

    total = query.count()
    reports = query.order_by(Report.updated_at.desc()).offset((page - 1) * limit).limit(limit).all()

    items = [ReportResponse.model_validate(r) for r in reports]
    return ReportListResponse(items=items, total=total, page=page, limit=limit)

drafts_router = APIRouter()

@drafts_router.get("", response_model=List[ReportResponse])
@router.get("/drafts", response_model=List[ReportResponse])
def get_user_drafts(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    drafts = db.query(Report).filter(
        Report.created_by == current_user.id,
        Report.status == "draft"
    ).order_by(Report.updated_at.desc()).all()

    return [ReportResponse.model_validate(r) for r in drafts]


@router.post("", response_model=ReportResponse, status_code=status.HTTP_201_CREATED)
def create_report(
    report_in: ReportCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    new_report = Report(
        title=report_in.title.strip(),
        report_type=report_in.report_type.strip().upper(),
        maintenance_type=report_in.maintenance_type.strip().lower(),
        status=report_in.status.strip().lower(),
        created_by=current_user.id,
        creator_display_name=current_user.full_name,
        customer_name=report_in.customer_name.strip(),
        trafo_label=report_in.trafo_label.strip(),
        test_date=report_in.test_date,
        report_date=report_in.report_date,
        data_json=report_in.data_json
    )

    db.add(new_report)
    db.commit()
    db.refresh(new_report)

    return ReportResponse.model_validate(new_report)

@router.get("/{report_id}", response_model=ReportResponse)
def get_report(
    report_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    report = db.query(Report).filter(Report.id == report_id).first()
    if not report:
        raise NotFoundException("Rapor bulunamadı.")

    return ReportResponse.model_validate(report)

@router.put("/{report_id}", response_model=ReportResponse)
def update_report(
    report_id: int,
    report_in: ReportUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    report = db.query(Report).filter(Report.id == report_id).first()
    if not report:
        raise NotFoundException("Rapor bulunamadı.")

    # Authorization check: Owner can edit drafts; Admin can edit any report
    if current_user.role != "admin" and (report.created_by != current_user.id or report.status != "draft"):
        raise ForbiddenException("Bu raporu düzenleme yetkiniz bulunmamaktadır.")

    if report_in.title is not None:
        report.title = report_in.title.strip()
    if report_in.customer_name is not None:
        report.customer_name = report_in.customer_name.strip()
    if report_in.trafo_label is not None:
        report.trafo_label = report_in.trafo_label.strip()
    if report_in.test_date is not None:
        report.test_date = report_in.test_date
    if report_in.report_date is not None:
        report.report_date = report_in.report_date
    if report_in.data_json is not None:
        report.data_json = report_in.data_json
    if report_in.status is not None:
        report.status = report_in.status.strip().lower()

    db.commit()
    db.refresh(report)

    return ReportResponse.model_validate(report)

@router.delete("/{report_id}")
def delete_report(
    report_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    report = db.query(Report).filter(Report.id == report_id).first()
    if not report:
        raise NotFoundException("Rapor bulunamadı.")

    # Authorization check: Owner can delete own draft; Admin can delete any report
    if current_user.role != "admin" and (report.created_by != current_user.id or report.status != "draft"):
        raise ForbiddenException("Bu raporu silme yetkiniz bulunmamaktadır.")

    db.delete(report)
    db.commit()

    return {"message": "Rapor başarıyla silindi.", "report_id": report_id}

@router.post("/{report_id}/photos", response_model=PhotoResponse, status_code=status.HTTP_201_CREATED)
async def upload_report_photo(
    report_id: int,
    photo_type: str = Form(..., description="before, after, label, signature"),
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    report = db.query(Report).filter(Report.id == report_id).first()
    if not report:
        raise NotFoundException("Rapor bulunamadı.")

    if current_user.role != "admin" and report.created_by != current_user.id:
        raise ForbiddenException("Bu rapora fotoğraf ekleme yetkiniz bulunmamaktadır.")

    if not file.content_type.startswith("image/"):
        raise BadRequestException(code="INVALID_FILE_TYPE", message="Yalnızca görsel dosyaları yüklenebilir.")

    os.makedirs(os.path.join(settings.UPLOAD_DIR, "photos"), exist_ok=True)
    filename = f"report_{report_id}_{photo_type}_{uuid.uuid4().hex[:8]}.jpg"
    filepath = os.path.join(settings.UPLOAD_DIR, "photos", filename)

    content = await file.read()
    with open(filepath, "wb") as f:
        f.write(content)

    photo = Photo(
        report_id=report_id,
        photo_type=photo_type.strip().lower(),
        file_path=filepath
    )
    db.add(photo)
    db.commit()
    db.refresh(photo)

    return PhotoResponse.model_validate(photo)

from fastapi.responses import FileResponse
from app.services.excel_engine import generate_report_excel
from app.services.email_service import notify_admins_for_finalize



@router.post("/{report_id}/finalize", response_model=ReportResponse)
def finalize_report(
    report_id: int,
    background_tasks: BackgroundTasks = BackgroundTasks(),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):

    report = db.query(Report).filter(Report.id == report_id).first()
    if not report:
        raise NotFoundException("Rapor bulunamadı.")

    if current_user.role != "admin" and report.created_by != current_user.id:
        raise ForbiddenException("Bu raporu kesinleştirme yetkiniz bulunmamaktadır.")

    photos = db.query(Photo).filter(Photo.report_id == report_id).all()
    signature_path = current_user.signature_path

    # Generate Excel file using openpyxl engine
    try:
        excel_file_path = generate_report_excel(report, photos, signature_path)
        report.excel_path = excel_file_path
        report.status = "final"
        db.commit()
        db.refresh(report)
    except Exception as e:
        db.rollback()
        raise BadRequestException(code="EXCEL_GENERATION_FAILED", message=f"Excel raporu üretilirken hata oluştu: {str(e)}")

    # Notify admins in background
    background_tasks.add_task(notify_admins_for_finalize, report.id)

    return ReportResponse.model_validate(report)


@router.get("/{report_id}/download")
def download_report_excel(
    report_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    report = db.query(Report).filter(Report.id == report_id).first()
    if not report:
        raise NotFoundException("Rapor bulunamadı.")

    # Generate if not already generated
    if not report.excel_path or not os.path.exists(report.excel_path):
        photos = db.query(Photo).filter(Photo.report_id == report_id).all()
        signature_path = current_user.signature_path
        excel_file_path = generate_report_excel(report, photos, signature_path)
        report.excel_path = excel_file_path
        db.commit()

    filename = os.path.basename(report.excel_path)
    return FileResponse(
        path=report.excel_path,
        filename=filename,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    )

