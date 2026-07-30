import json
from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.db.session import Base

class Report(Base):
    __tablename__ = "reports"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False)
    report_type = Column(String(50), nullable=False)  # HERMETIK, KURU_TIP, GT
    maintenance_type = Column(String(50), nullable=False, default="maintenance")  # maintenance, test
    status = Column(String(20), nullable=False, default="draft", index=True)  # draft, final
    
    created_by = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    creator_display_name = Column(String(150), nullable=False)
    
    customer_name = Column(String(255), nullable=False, index=True)
    trafo_label = Column(String(150), nullable=False)
    test_date = Column(String(20), nullable=True)
    report_date = Column(String(20), nullable=True)
    
    data_json_raw = Column("data_json", Text, nullable=False)
    excel_path = Column(String(255), nullable=True)
    
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)

    creator = relationship("User", foreign_keys=[created_by])
    photos = relationship("Photo", back_populates="report", cascade="all, delete-orphan")

    @property
    def data_json(self) -> dict:
        try:
            return json.loads(self.data_json_raw) if self.data_json_raw else {}
        except Exception:
            return {}

    @data_json.setter
    def data_json(self, value: dict):
        self.data_json_raw = json.dumps(value, ensure_ascii=False)
