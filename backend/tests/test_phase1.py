import os
import pytest
from fastapi.testclient import TestClient

# Set temporary test SQLite DB environment
os.environ["DATABASE_URL"] = "sqlite:///./test_traforeport.db"

from app.main import app
from app.db.session import engine, Base
from create_initial_admin import seed_data

client = TestClient(app)

@pytest.fixture(scope="session", autouse=True)
def setup_test_db():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    seed_data()
    yield
    Base.metadata.drop_all(bind=engine)
    if os.path.exists("./test_traforeport.db"):
        try:
            os.remove("./test_traforeport.db")
        except PermissionError:
            pass

def test_admin_login():
    response = client.post("/api/v1/auth/login", json={
        "identifier": "05000000000",
        "password": "Admin123!"
    })
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["user"]["role"] == "admin"

def test_register_with_valid_invite_code():
    response = client.post("/api/v1/auth/register", json={
        "full_name": "Mehmet Teknisyen",
        "phone": "05559998877",
        "email": "mehmet@btselektrik.com",
        "sicil_no": "TEK001",
        "invite_code": "BTS2026",
        "password": "Teknisyen123!"
    })
    assert response.status_code == 201
    data = response.json()
    assert data["full_name"] == "Mehmet Teknisyen"
    assert data["role"] == "employee"

def test_register_with_used_invite_code_fails():
    response = client.post("/api/v1/auth/register", json={
        "full_name": "İkinci Teknisyen",
        "phone": "05558887766",
        "invite_code": "BTS2026",
        "password": "Teknisyen123!"
    })
    assert response.status_code == 400
    data = response.json()
    assert data["error"]["code"] == "INVITE_CODE_INVALID"

def test_employee_login_and_refresh():
    # Login
    response = client.post("/api/v1/auth/login", json={
        "identifier": "05559998877",
        "password": "Teknisyen123!"
    })
    assert response.status_code == 200
    data = response.json()
    access_token = data["access_token"]
    refresh_token = data["refresh_token"]

    # Profile check (/users/me)
    headers = {"Authorization": f"Bearer {access_token}"}
    me_resp = client.get("/api/v1/users/me", headers=headers)
    assert me_resp.status_code == 200
    assert me_resp.json()["phone"] == "05559998877"

    # Refresh token
    ref_resp = client.post("/api/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert ref_resp.status_code == 200
    assert "access_token" in ref_resp.json()

def test_admin_generate_code_and_list_users():
    # Admin login
    admin_login = client.post("/api/v1/auth/login", json={
        "identifier": "05000000000",
        "password": "Admin123!"
    }).json()
    admin_token = admin_login["access_token"]
    headers = {"Authorization": f"Bearer {admin_token}"}

    # Generate registration code
    code_resp = client.post("/api/v1/admin/codes", json={"code": "NEWCODE123"}, headers=headers)
    assert code_resp.status_code == 201
    assert code_resp.json()["code"] == "NEWCODE123"

    # List registration codes
    codes_list = client.get("/api/v1/admin/codes", headers=headers)
    assert codes_list.status_code == 200
    assert len(codes_list.json()) >= 2

    # List users
    users_resp = client.get("/api/v1/admin/users", headers=headers)
    assert users_resp.status_code == 200
    assert users_resp.json()["total"] >= 2

def test_deactivate_user():
    admin_token = client.post("/api/v1/auth/login", json={
        "identifier": "05000000000",
        "password": "Admin123!"
    }).json()["access_token"]
    headers = {"Authorization": f"Bearer {admin_token}"}

    # Get employee user ID
    users_resp = client.get("/api/v1/admin/users?role=employee", headers=headers).json()
    emp_id = users_resp["items"][0]["id"]

    # Deactivate employee
    del_resp = client.delete(f"/api/v1/admin/users/{emp_id}", headers=headers)
    assert del_resp.status_code == 200
    assert del_resp.json()["user_id"] == emp_id

    # Verify deactivated employee cannot login
    emp_login = client.post("/api/v1/auth/login", json={
        "identifier": "05559998877",
        "password": "Teknisyen123!"
    })
    assert emp_login.status_code == 401
