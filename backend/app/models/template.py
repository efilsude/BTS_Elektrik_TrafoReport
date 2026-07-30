from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, DateTime
from app.db.session import Base

class Template(Base):
    __tablename__ = "templates"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(150), nullable=False)
    report_type = Column(String(50), nullable=False, index=True)  # HERMETIK, KURU_TIP, GT
    file_path = Column(String(255), nullable=False)
    version = Column(String(20), nullable=False, default="1.0")
    uploaded_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
