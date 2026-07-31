from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, DateTime
from app.db.session import Base

class EmailVerificationCode(Base):
    __tablename__ = "email_verification_codes"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(150), nullable=False, index=True)
    code = Column(String(6), nullable=False, index=True)
    purpose = Column(String(30), default="register", nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    used_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    @property
    def is_valid(self) -> bool:
        if self.used_at is not None:
            return False
        now = datetime.now(timezone.utc)
        exp = self.expires_at
        if exp.tzinfo is None:
            exp = exp.replace(tzinfo=timezone.utc)
        return exp > now
