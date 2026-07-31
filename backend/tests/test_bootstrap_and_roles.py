import os
import pytest
from datetime import datetime, timezone, timedelta
from fastapi.testclient import TestClient

from app.core.config import settings
settings.DATABASE_URL = "sqlite:///./test_traforeport_bootstrap.db"
settings.EMAIL_ENABLED = False

from app.main import app
from app.db.session import engine, Base, SessionLocal
from app.models.user import User
from app.models.code import RegistrationCode

client = TestClient(app)

@pytest.fixture(scope="module", autouse=True)
def setup_test_db():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)

    if os.path.exists("./test_traforeport_bootstrap.db"):
        try:
            os.remove("./test_traforeport_bootstrap.db")
        except PermissionError:
            pass


def test_empty_db_bootstrap_flow():
    # 1. Check bootstrap status on empty DB
    res = client.get("/api/v1/auth/bootstrap-status")
    assert res.status_code == 200
    assert res.json()["needs_bootstrap"] is True

    # 2. Request verification code for bootstrap
    res_req = client.post("/api/v1/auth/request-verification-bootstrap", json={
        "email": "first_admin@btselektrik.com"
    })
    assert res_req.status_code == 200
    data_req = res_req.json()
    assert "debug_code" in data_req
    debug_code = data_req["debug_code"]
    assert len(debug_code) == 6

    # 3. Fail bootstrap with wrong code
    res_fail = client.post("/api/v1/auth/bootstrap", json={
        "full_name": "İlk Admin",
        "phone": "05559998877",
        "email": "first_admin@btselektrik.com",
        "password": "Password123!",
        "verification_code": "000000"
    })
    assert res_fail.status_code == 400
    assert res_fail.json()["error"]["code"] == "VERIFICATION_CODE_INVALID"

    # 4. Successful bootstrap
    res_succ = client.post("/api/v1/auth/bootstrap", json={
        "full_name": "İlk Admin",
        "phone": "05559998877",
        "email": "first_admin@btselektrik.com",
        "password": "Password123!",
        "verification_code": debug_code
    })
    assert res_succ.status_code == 201
    user_data = res_succ.json()
    assert user_data["email"] == "first_admin@btselektrik.com"
    assert user_data["role"] == "admin"

    # 5. Check bootstrap status is now False
    res_st = client.get("/api/v1/auth/bootstrap-status")
    assert res_st.status_code == 200
    assert res_st.json()["needs_bootstrap"] is False

    # 6. Subsequent bootstrap attempt fails with BOOTSTRAP_NOT_ALLOWED
    res_sec = client.post("/api/v1/auth/request-verification-bootstrap", json={
        "email": "second_admin@btselektrik.com"
    })
    assert res_sec.status_code == 400
    assert res_sec.json()["error"]["code"] == "BOOTSTRAP_NOT_ALLOWED"


def test_invite_codes_with_roles_and_registration():
    # 1. Login as the newly bootstrapped Admin
    res_login = client.post("/api/v1/auth/login", json={
        "identifier": "05559998877",
        "password": "Password123!"
    })
    assert res_login.status_code == 200
    admin_token = res_login.json()["access_token"]
    headers = {"Authorization": f"Bearer {admin_token}"}

    # 2. Generate admin-role invite code
    res_c1 = client.post("/api/v1/admin/codes", json={
        "code": "ADM_CODE_1",
        "role": "admin"
    }, headers=headers)
    assert res_c1.status_code == 201
    data_c1 = res_c1.json()
    assert data_c1["code"] == "ADM_CODE_1"
    assert data_c1["role"] == "admin"

    # 3. Generate employee-role invite code
    res_c2 = client.post("/api/v1/admin/codes", json={
        "code": "EMP_CODE_1",
        "role": "employee"
    }, headers=headers)
    assert res_c2.status_code == 201
    data_c2 = res_c2.json()
    assert data_c2["code"] == "EMP_CODE_1"
    assert data_c2["role"] == "employee"

    # 4. List invite codes and check role
    res_list = client.get("/api/v1/admin/codes", headers=headers)
    assert res_list.status_code == 200
    codes_list = res_list.json()
    role_map = {c["code"]: c["role"] for c in codes_list}
    assert role_map["ADM_CODE_1"] == "admin"
    assert role_map["EMP_CODE_1"] == "employee"

    # 5. Register new Admin user using ADM_CODE_1
    req_ver1 = client.post("/api/v1/auth/request-verification", json={
        "email": "second_admin@btselektrik.com",
        "invite_code": "ADM_CODE_1"
    })
    assert req_ver1.status_code == 200
    ver_code1 = req_ver1.json()["debug_code"]

    reg_res1 = client.post("/api/v1/auth/register", json={
        "full_name": "İkinci Admin",
        "phone": "05558887766",
        "email": "second_admin@btselektrik.com",
        "invite_code": "ADM_CODE_1",
        "verification_code": ver_code1,
        "password": "Password123!"
    })
    assert reg_res1.status_code == 201
    u1 = reg_res1.json()
    assert u1["role"] == "admin"

    # 6. Register new Employee user using EMP_CODE_1
    req_ver2 = client.post("/api/v1/auth/request-verification", json={
        "email": "employee1@btselektrik.com",
        "invite_code": "EMP_CODE_1"
    })
    assert req_ver2.status_code == 200
    ver_code2 = req_ver2.json()["debug_code"]

    reg_res2 = client.post("/api/v1/auth/register", json={
        "full_name": "Saha Teknisyeni",
        "phone": "05557776655",
        "email": "employee1@btselektrik.com",
        "invite_code": "EMP_CODE_1",
        "verification_code": ver_code2,
        "password": "Password123!"
    })
    assert reg_res2.status_code == 201
    u2 = reg_res2.json()
    assert u2["role"] == "employee"


def test_last_active_admin_deactivation_protection():
    # 1. Login as First Admin
    res_login = client.post("/api/v1/auth/login", json={
        "identifier": "05559998877",
        "password": "Password123!"
    })
    admin1_token = res_login.json()["access_token"]
    headers1 = {"Authorization": f"Bearer {admin1_token}"}

    # 2. Get user IDs
    db = SessionLocal()
    admin1 = db.query(User).filter(User.phone == "05559998877").first()
    admin2 = db.query(User).filter(User.phone == "05558887766").first()
    emp = db.query(User).filter(User.phone == "05557776655").first()
    db.close()

    # 3. Admin1 deactivates Admin2 (Active admin count goes from 2 to 1) -> Success
    res_deact2 = client.delete(f"/api/v1/admin/users/{admin2.id}", headers=headers1)
    assert res_deact2.status_code == 200

    # 4. Admin1 tries to deactivate Admin1 (Self deletion) -> Fails with CANNOT_DELETE_SELF
    res_self = client.delete(f"/api/v1/admin/users/{admin1.id}", headers=headers1)
    assert res_self.status_code == 400
    assert res_self.json()["error"]["code"] == "CANNOT_DELETE_SELF"

    # 5. Admin2 logs in (now inactive) -> Fails
    res_login2 = client.post("/api/v1/auth/login", json={
        "identifier": "05558887766",
        "password": "Password123!"
    })
    assert res_login2.status_code == 401
