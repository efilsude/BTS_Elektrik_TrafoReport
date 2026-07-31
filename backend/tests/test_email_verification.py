import os
import pytest
from datetime import datetime, timezone, timedelta
from fastapi.testclient import TestClient

from app.core.config import settings
settings.DATABASE_URL = "sqlite:///./test_traforeport_email.db"
settings.EMAIL_ENABLED = False

from app.main import app
from app.db.session import engine, Base, SessionLocal
from create_initial_admin import seed_data
from app.models.code import RegistrationCode
from app.models.email_verification import EmailVerificationCode
from app.services.email_service import send_email, notify_admins

client = TestClient(app)

@pytest.fixture(scope="session", autouse=True)
def setup_test_db():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    seed_data()
    yield
    Base.metadata.drop_all(bind=engine)

    if os.path.exists("./test_traforeport_email.db"):
        try:
            os.remove("./test_traforeport_email.db")
        except PermissionError:
            pass


def get_admin_token():
    resp = client.post("/api/v1/auth/login", json={"identifier": "05000000000", "password": "Admin123!"})
    return resp.json()["access_token"]


def generate_invite_code(code_str=None):
    token = get_admin_token()
    headers = {"Authorization": f"Bearer {token}"}
    payload = {"code": code_str} if code_str else {}
    res = client.post("/api/v1/admin/codes", json=payload, headers=headers)
    return res.json()["code"]


def test_console_email_sink():
    # Test that send_email returns True when EMAIL_ENABLED=false
    settings.EMAIL_ENABLED = False
    res = send_email(
        to="test@btselektrik.com",
        subject="Test Konu",
        html_body="<h1>Test İçerik</h1>"
    )
    assert res is True


def test_request_verification_invalid_invite_code():
    res = client.post("/api/v1/auth/request-verification", json={
        "email": "yeniuser@btselektrik.com",
        "invite_code": "INVALID_CODE_999"
    })
    assert res.status_code == 400
    assert res.json()["error"]["code"] == "INVITE_CODE_INVALID"


def test_request_verification_success_and_rate_limit():
    invite_code = generate_invite_code("INV_RATE_1")
    settings.EMAIL_ENABLED = False
    # 1. Request verification code for new user (EMAIL_ENABLED=false -> debug_code is present)
    res = client.post("/api/v1/auth/request-verification", json={
        "email": "rate_user@btselektrik.com",
        "invite_code": invite_code
    })
    assert res.status_code == 200
    data = res.json()
    assert "expires_in_seconds" in data
    assert data["expires_in_seconds"] == 600
    assert "debug_code" in data
    assert data["debug_code"] is not None
    assert len(data["debug_code"]) == 6

    # Verify code matches DB
    db = SessionLocal()
    ver_rec = db.query(EmailVerificationCode).filter(
        EmailVerificationCode.email == "rate_user@btselektrik.com"
    ).order_by(EmailVerificationCode.created_at.desc()).first()
    assert ver_rec is not None
    assert ver_rec.code == data["debug_code"]
    db.close()

    # 2. Try requesting again immediately (<60s rate limit)
    res_rate = client.post("/api/v1/auth/request-verification", json={
        "email": "rate_user@btselektrik.com",
        "invite_code": invite_code
    })
    assert res_rate.status_code == 400
    assert res_rate.json()["error"]["code"] == "RATE_LIMIT_EXCEEDED"


def test_request_verification_email_enabled_smtp_failure():
    invite_code = generate_invite_code("INV_SMTP_FAIL")
    settings.EMAIL_ENABLED = True
    settings.SMTP_HOST = "invalid.smtp.domain.nonexistent"
    settings.SMTP_PORT = 587

    res = client.post("/api/v1/auth/request-verification", json={
        "email": "smtp_fail_user@btselektrik.com",
        "invite_code": invite_code
    })
    # Reset EMAIL_ENABLED to False for remaining tests
    settings.EMAIL_ENABLED = False

    assert res.status_code == 400
    assert res.json()["error"]["code"] == "EMAIL_SEND_FAILED"



def test_register_invalid_verification_code():
    invite_code = generate_invite_code("INV_WRONG_VER")
    res = client.post("/api/v1/auth/register", json={
        "full_name": "Test User",
        "phone": "05551110000",
        "email": "wrong_ver@btselektrik.com",
        "invite_code": invite_code,
        "verification_code": "999999",  # Wrong code
        "password": "Password123!"
    })
    assert res.status_code == 400
    assert res.json()["error"]["code"] == "VERIFICATION_CODE_INVALID"


def test_register_expired_verification_code():
    invite_code = generate_invite_code("INV_EXPIRED_VER")
    db = SessionLocal()
    # Create an expired code in DB
    expired_code = EmailVerificationCode(
        email="expired_user@btselektrik.com",
        code="888888",
        purpose="register",
        expires_at=datetime.now(timezone.utc) - timedelta(minutes=5),
        created_at=datetime.now(timezone.utc) - timedelta(minutes=15)
    )
    db.add(expired_code)
    db.commit()
    db.close()

    res = client.post("/api/v1/auth/register", json={
        "full_name": "Expired User",
        "phone": "05552220000",
        "email": "expired_user@btselektrik.com",
        "invite_code": invite_code,
        "verification_code": "888888",
        "password": "Password123!"
    })
    assert res.status_code == 400
    assert res.json()["error"]["code"] == "VERIFICATION_CODE_EXPIRED"


def test_register_success_with_valid_verification_code():
    invite_code = generate_invite_code("INV_VALID_REG")

    # 1. Request verification code
    client.post("/api/v1/auth/request-verification", json={
        "email": "valid_user@btselektrik.com",
        "invite_code": invite_code
    })

    db = SessionLocal()
    ver_rec = db.query(EmailVerificationCode).filter(
        EmailVerificationCode.email == "valid_user@btselektrik.com"
    ).first()
    code = ver_rec.code
    db.close()

    # 2. Register user with valid code
    res = client.post("/api/v1/auth/register", json={
        "full_name": "Yeni Calisan",
        "phone": "05553334455",
        "email": "valid_user@btselektrik.com",
        "sicil_no": "SICIL999",
        "invite_code": invite_code,
        "verification_code": code,
        "password": "Password123!"
    })
    assert res.status_code == 201
    user_data = res.json()
    assert user_data["email"] == "valid_user@btselektrik.com"

    # 3. Check code is marked used
    db = SessionLocal()
    ver_rec_used = db.query(EmailVerificationCode).filter(
        EmailVerificationCode.email == "valid_user@btselektrik.com"
    ).first()
    assert ver_rec_used.used_at is not None
    db.close()

    # 4. Try re-using the same verification code with a fresh invite code -> should fail with VERIFICATION_CODE_INVALID
    invite_code_2 = generate_invite_code("INV_VALID_REG2")
    res_reuse = client.post("/api/v1/auth/register", json={
        "full_name": "Tekrar User",
        "phone": "05554445566",
        "email": "valid_user@btselektrik.com",
        "invite_code": invite_code_2,
        "verification_code": code,
        "password": "Password123!"
    })
    assert res_reuse.status_code == 400
    assert res_reuse.json()["error"]["code"] == "VERIFICATION_CODE_INVALID"

