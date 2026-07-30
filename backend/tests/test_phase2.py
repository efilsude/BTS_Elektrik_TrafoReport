import os
import io
import pytest
from fastapi.testclient import TestClient

os.environ["DATABASE_URL"] = "sqlite:///./test_traforeport_phase2.db"

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
    if os.path.exists("./test_traforeport_phase2.db"):
        try:
            os.remove("./test_traforeport_phase2.db")
        except PermissionError:
            pass

def get_auth_token(identifier, password):
    resp = client.post("/api/v1/auth/login", json={"identifier": identifier, "password": password})
    return resp.json()["access_token"]

def test_report_lifecycle_and_drafts():
    # 1. Register employee
    reg_resp = client.post("/api/v1/auth/register", json={
        "full_name": "Ahmet Teknisyen",
        "phone": "05321112233",
        "invite_code": "BTS2026",
        "password": "Password123"
    })
    assert reg_resp.status_code == 201

    token = get_auth_token("05321112233", "Password123")
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Create draft report
    create_resp = client.post("/api/v1/reports", json={
        "title": "ABC Fabrikası - TR1 - 30.07.2026",
        "report_type": "HERMETIK",
        "maintenance_type": "maintenance",
        "status": "draft",
        "customer_name": "ABC Fabrikası",
        "trafo_label": "TR1",
        "test_date": "2026-07-30",
        "report_date": "2026-07-30",
        "data_json": {
            "brand": "Schneider",
            "power_kva": "1600",
            "serial_no": "SN-12345"
        }
    }, headers=headers)
    assert create_resp.status_code == 201
    report_data = create_resp.json()
    report_id = report_data["id"]
    assert report_data["creator_display_name"] == "Ahmet Teknisyen"
    assert report_data["status"] == "draft"

    # 3. Check GET /drafts
    drafts_resp = client.get("/api/v1/drafts", headers=headers)
    assert drafts_resp.status_code == 200
    drafts = drafts_resp.json()
    assert len(drafts) >= 1
    assert drafts[0]["id"] == report_id

    # 4. Upload photo to report
    fake_img = io.BytesIO(b"fake image bytes")
    photo_resp = client.post(
        f"/api/v1/reports/{report_id}/photos",
        data={"photo_type": "before"},
        files={"file": ("before.jpg", fake_img, "image/jpeg")},
        headers=headers
    )
    assert photo_resp.status_code == 201
    assert photo_resp.json()["photo_type"] == "before"

    # 5. Get report details
    detail_resp = client.get(f"/api/v1/reports/{report_id}", headers=headers)
    assert detail_resp.status_code == 200
    detail = detail_resp.json()
    assert len(detail["photos"]) == 1
    assert detail["data_json"]["brand"] == "Schneider"

    # 6. Update report
    update_resp = client.put(f"/api/v1/reports/{report_id}", json={
        "title": "ABC Fabrikası - TR1 GÜNCELLENDİ",
        "data_json": {
            "brand": "Schneider",
            "power_kva": "1600",
            "serial_no": "SN-12345",
            "notes": "Tüm kontroller tamamlandı."
        }
    }, headers=headers)
    assert update_resp.status_code == 200
    assert update_resp.json()["title"] == "ABC Fabrikası - TR1 GÜNCELLENDİ"

    # 7. Search in Rapor Havuzu (GET /reports)
    search_resp = client.get("/api/v1/reports?search=ABC", headers=headers)
    assert search_resp.status_code == 200
    assert search_resp.json()["total"] >= 1

def test_creator_display_name_preservation():
    admin_token = get_auth_token("05000000000", "Admin123!")
    admin_headers = {"Authorization": f"Bearer {admin_token}"}

    # Fetch report created by Ahmet Teknisyen
    reports = client.get("/api/v1/reports?search=ABC", headers=admin_headers).json()["items"]
    assert len(reports) >= 1
    report = reports[0]
    emp_user_id = report["created_by"]

    # Deactivate employee
    deact_resp = client.delete(f"/api/v1/admin/users/{emp_user_id}", headers=admin_headers)
    assert deact_resp.status_code == 200

    # Fetch report again - creator_display_name must be preserved!
    report_after = client.get(f"/api/v1/reports/{report['id']}", headers=admin_headers).json()
    assert report_after["creator_display_name"] == "Ahmet Teknisyen"
