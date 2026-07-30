from datetime import datetime
from typing import Optional, List, Any, Dict
from pydantic import BaseModel, ConfigDict, Field
from app.schemas.photo import PhotoResponse

class ReportBase(BaseModel):
    title: str = Field(..., min_length=2, max_length=255)
    report_type: str = Field(..., description="HERMETIK, KURU_TIP, GT")
    maintenance_type: str = Field("maintenance", description="maintenance or test")
    customer_name: str = Field(..., min_length=2, max_length=255)
    trafo_label: str = Field(..., min_length=1, max_length=150)
    test_date: Optional[str] = None
    report_date: Optional[str] = None
    data_json: Dict[str, Any] = Field(default_factory=dict)

class ReportCreate(ReportBase):
    status: str = Field("draft", description="draft or final")

class ReportUpdate(BaseModel):
    title: Optional[str] = None
    customer_name: Optional[str] = None
    trafo_label: Optional[str] = None
    test_date: Optional[str] = None
    report_date: Optional[str] = None
    data_json: Optional[Dict[str, Any]] = None
    status: Optional[str] = None

class ReportResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    report_type: str
    maintenance_type: str
    status: str
    created_by: Optional[int] = None
    creator_display_name: str
    customer_name: str
    trafo_label: str
    test_date: Optional[str] = None
    report_date: Optional[str] = None
    data_json: Dict[str, Any] = Field(default_factory=dict)
    excel_path: Optional[str] = None
    photos: List[PhotoResponse] = Field(default_factory=list)
    created_at: datetime
    updated_at: datetime

class ReportListResponse(BaseModel):
    items: List[ReportResponse]
    total: int
    page: int
    limit: int
