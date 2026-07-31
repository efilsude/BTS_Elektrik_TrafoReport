"""
DEV / TEST ONLY — Initial seed script for TrafoReport Backend.
Prod ortamında seed script yerine uçtan uca güvenli 'GET /auth/bootstrap-status'
ve 'POST /auth/bootstrap' akışı kullanılmalıdır.
"""

from datetime import datetime, timezone, timedelta
from app.db.session import SessionLocal, engine, Base
from app.models.user import User
from app.models.code import RegistrationCode
from app.core.security import get_password_hash

def seed_data():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        # Check if admin user exists
        admin = db.query(User).filter(User.phone == "05000000000").first()
        if not admin:
            admin = User(
                full_name="Sistem Yöneticisi",
                phone="05000000000",
                email="admin@btselektrik.com",
                sicil_no="ADM001",
                password_hash=get_password_hash("Admin123!"),
                role="admin",
                is_active=True
            )
            db.add(admin)
            db.flush()
            print(f"[SEED] Admin kullanıcısı oluşturuldu ID: {admin.id}")
        else:
            print("[SEED] Admin kullanıcısı zaten mevcut.")

        # Check if active registration code exists
        code = db.query(RegistrationCode).filter(RegistrationCode.code == "BTS2026").first()
        if not code:
            code = RegistrationCode(
                code="BTS2026",
                created_by=admin.id,
                expires_at=datetime.now(timezone.utc) + timedelta(days=365),  # long TTL for initial setup
                created_at=datetime.now(timezone.utc)
            )
            db.add(code)
            print("[SEED] İlk davet kodu oluşturuldu: BTS2026")
        else:
            print("[SEED] İlk davet kodu zaten mevcut.")

        db.commit()
    finally:
        db.close()

if __name__ == "__main__":
    seed_data()
