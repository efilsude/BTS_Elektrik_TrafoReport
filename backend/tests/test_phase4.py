import os
import io
import pytest
from fastapi.testclient import TestClient

# DATABASE_URL artık tests/conftest.py içinde tüm test oturumu için tek
# seferde ayarlanıyor (bkz. conftest.py docstring'i).

from app.main import app
from app.db.session import engine, Base
from create_initial_admin import seed_data

client = TestClient(app)

@pytest.fixture(scope="session", autouse=True)
def setup_test_db():
    # Dosyanın kendisi burada SİLİNMEZ — paylaşılan engine'e bağlı diğer
    # modüllerin bağlantılarını bozar; fiziksel temizlik tek seferlik
    # olarak conftest.py'de yapılır.
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    seed_data()
    yield

def get_auth_token(identifier, password):
    resp = client.post("/api/v1/auth/login", json={"identifier": identifier, "password": password})
    return resp.json()["access_token"]

def test_templates_and_admin_stats():
    admin_token = get_auth_token("05000000000", "Admin123!")
    admin_headers = {"Authorization": f"Bearer {admin_token}"}

    # 1. GET /templates
    tmpl_resp = client.get("/api/v1/templates", headers=admin_headers)
    assert tmpl_resp.status_code == 200
    templates = tmpl_resp.json()
    assert len(templates) >= 3

    # 2. POST /admin/templates/upload (upload template with admin)
    fake_xlsx = io.BytesIO(b"fake excel content")
    upload_resp = client.post(
        "/api/v1/templates/admin/upload",
        data={"name": "Özel Hermetik Şablonu", "report_type": "HERMETIK", "version": "1.2"},
        files={"file": ("custom_hermetik.xlsx", fake_xlsx, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")},
        headers=admin_headers
    )
    assert upload_resp.status_code == 201
    assert upload_resp.json()["name"] == "Özel Hermetik Şablonu"

    # 3. GET /admin/stats
    stats_resp = client.get("/api/v1/admin/stats", headers=admin_headers)
    assert stats_resp.status_code == 200
    stats = stats_resp.json()
    assert "total_reports" in stats
    assert "reports_by_type" in stats
    assert "total_active_users" in stats
    assert "active_invite_codes" in stats

def test_non_admin_forbidden_access():
    # Register employee
    client.post("/api/v1/auth/request-verification", json={
        "email": "siradan@btselektrik.com",
        "invite_code": "BTS2026"
    })
    from app.db.session import SessionLocal
    from app.models.email_verification import EmailVerificationCode
    db = SessionLocal()
    ver_rec = db.query(EmailVerificationCode).filter(EmailVerificationCode.email == "siradan@btselektrik.com").order_by(EmailVerificationCode.created_at.desc()).first()
    ver_code = ver_rec.code
    db.close()

    client.post("/api/v1/auth/register", json={
        "full_name": "Sıradan Çalışan",
        "phone": "05330001122",
        "email": "siradan@btselektrik.com",
        "invite_code": "BTS2026",
        "verification_code": ver_code,
        "password": "Password123"
    })
    emp_token = get_auth_token("05330001122", "Password123")

    emp_headers = {"Authorization": f"Bearer {emp_token}"}

    # Non-admin attempting to access /admin/stats
    stats_resp = client.get("/api/v1/admin/stats", headers=emp_headers)
    assert stats_resp.status_code == 403

    # Non-admin attempting to upload template
    fake_xlsx = io.BytesIO(b"fake excel content")
    upload_resp = client.post(
        "/api/v1/templates/admin/upload",
        data={"name": "Yetkisiz Deneme", "report_type": "HERMETIK"},
        files={"file": ("test.xlsx", fake_xlsx, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")},
        headers=emp_headers
    )
    assert upload_resp.status_code == 403
