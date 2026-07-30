from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Boolean, DateTime
from sqlalchemy.orm import relationship
from app.db.session import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String(150), nullable=False)
    phone = Column(String(30), nullable=False, unique=True, index=True)
    email = Column(String(150), nullable=True, unique=True, index=True)
    sicil_no = Column(String(50), nullable=True, unique=True, index=True)
    password_hash = Column(String(255), nullable=False)
    role = Column(String(20), nullable=False, default="employee")
    is_active = Column(Boolean, nullable=False, default=True)
    signature_path = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)

    created_codes = relationship("RegistrationCode", foreign_keys="RegistrationCode.created_by", back_populates="creator")
    used_codes = relationship("RegistrationCode", foreign_keys="RegistrationCode.used_by_user_id", back_populates="used_by_user")
