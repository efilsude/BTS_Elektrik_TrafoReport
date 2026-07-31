import os
import io
import pytest
import openpyxl
from fastapi.testclient import TestClient

os.environ["DATABASE_URL"] = "sqlite:///./test_traforeport_e2e.db"

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
    if os.path.exists("./test_traforeport_e2e.db"):
        try:
            os.remove("./test_traforeport_e2e.db")
        except PermissionError:
            pass

def test_full_end_to_end_workflow():
    # 1. Admin Login
    admin_login_resp = client.post("/api/v1/auth/login", json={
        "identifier": "05000000000",
        "password": "Admin123!"
    })
    assert admin_login_resp.status_code == 200
    admin_token = admin_login_resp.json()["access_token"]
    admin_headers = {"Authorization": f"Bearer {admin_token}"}

    # 2. Admin creates single-use registration code
    code_resp = client.post("/api/v1/admin/codes", json={"code": "E2E2026CODE"}, headers=admin_headers)
    assert code_resp.status_code == 201
    reg_code = code_resp.json()["code"]

    # 3. Employee requests verification code and registers using invite code
    ver_req_resp = client.post("/api/v1/auth/request-verification", json={
        "email": "caner@btselektrik.com",
        "invite_code": reg_code
    })
    assert ver_req_resp.status_code == 200

    from app.db.session import SessionLocal
    from app.models.email_verification import EmailVerificationCode
    db = SessionLocal()
    ver_rec = db.query(EmailVerificationCode).filter(EmailVerificationCode.email == "caner@btselektrik.com").first()
    ver_code = ver_rec.code
    db.close()

    register_resp = client.post("/api/v1/auth/register", json={
        "full_name": "Caner Teknisyen",
        "phone": "05557776655",
        "email": "caner@btselektrik.com",
        "sicil_no": "TEK777",
        "invite_code": reg_code,
        "verification_code": ver_code,
        "password": "Password123!"
    })
    assert register_resp.status_code == 201
    emp_user_id = register_resp.json()["id"]


    # 4. Employee logs in & obtains JWT token
    emp_login_resp = client.post("/api/v1/auth/login", json={
        "identifier": "05557776655",
        "password": "Password123!"
    })
    assert emp_login_resp.status_code == 200
    emp_token = emp_login_resp.json()["access_token"]
    emp_headers = {"Authorization": f"Bearer {emp_token}"}

    # 5. Employee uploads handwritten signature PNG
    fake_png = io.BytesIO(b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15c4")
    sig_resp = client.put(
        "/api/v1/users/me/signature",
        files={"file": ("signature.png", fake_png, "image/png")},
        headers=emp_headers
    )
    assert sig_resp.status_code == 200
    assert sig_resp.json()["has_signature"] is True

    # 6. Employee creates Hermetic draft maintenance report
    create_report_resp = client.post("/api/v1/reports", json={
        "title": "E2E Sanayi A.Ş. - TR-100 - 30.07.2026",
        "report_type": "HERMETIK",
        "maintenance_type": "maintenance",
        "status": "draft",
        "customer_name": "E2E Sanayi A.Ş.",
        "trafo_label": "TR-100",
        "test_date": "2026-07-30",
        "report_date": "2026-07-30",
        "data_json": {
            "brand": "Schneider Electric",
            "power_kva": 2500,
            "voltage": "34500 / 400",
            "serial_no": "SN-2026-99",
            "manufacture_year": "2022",
            "connection_group": "Dyn11",
            "short_circuit_imp_pct": 6.15,
            "tank_type": "Hermetik",
            "og_r_a": 3.12,
            "og_r_b": 3.14,
            "og_r_c": 3.13,
            "ag_r_a": 0.0012,
            "ag_r_b": 0.0013,
            "ag_r_c": 0.00125
        }
    }, headers=emp_headers)
    assert create_report_resp.status_code == 201
    report_id = create_report_resp.json()["id"]

    # 7. Employee uploads before/after/label photos
    for photo_type in ["before", "after", "label"]:
        fake_photo = io.BytesIO(b"fake JPEG photo content")
        p_resp = client.post(
            f"/api/v1/reports/{report_id}/photos",
            data={"photo_type": photo_type},
            files={"file": (f"{photo_type}.jpg", fake_photo, "image/jpeg")},
            headers=emp_headers
        )
        assert p_resp.status_code == 201

    # 8. Employee finalizes report (generates Excel file)
    fin_resp = client.post(f"/api/v1/reports/{report_id}/finalize", headers=emp_headers)
    assert fin_resp.status_code == 200
    fin_report = fin_resp.json()
    assert fin_report["status"] == "final"
    excel_path = fin_report["excel_path"]
    assert os.path.exists(excel_path)

    # 9. Verify generated Excel formatting and values
    wb = openpyxl.load_workbook(excel_path, data_only=True)
    ws_kapak = wb["KAPAK SAYFASI"]
    ws_ana = wb["ANA SAYFA"]

    assert ws_kapak["D9"].value == "E2E Sanayi A.Ş."
    assert ws_kapak["D10"].value == "TR-100"
    assert ws_ana["G11"].value == "Schneider Electric"
    assert ws_ana["G13"].value == 2500

    # 10. Employee downloads generated Excel report
    dl_resp = client.get(f"/api/v1/reports/{report_id}/download", headers=emp_headers)
    assert dl_resp.status_code == 200
    assert len(dl_resp.content) > 2000

    # 11. Admin views dashboard stats
    stats_resp = client.get("/api/v1/admin/stats", headers=admin_headers)
    assert stats_resp.status_code == 200
    stats = stats_resp.json()
    assert stats["total_reports"] >= 1
    assert stats["final_reports"] >= 1
    assert stats["reports_by_type"]["HERMETIK"] >= 1

    # 12. Admin deactivates employee account
    del_user_resp = client.delete(f"/api/v1/admin/users/{emp_user_id}", headers=admin_headers)
    assert del_user_resp.status_code == 200

    # 13. Deactivated employee cannot log in
    failed_login = client.post("/api/v1/auth/login", json={
        "identifier": "05557776655",
        "password": "Password123!"
    })
    assert failed_login.status_code == 401

    # 14. Report still retains original creator_display_name
    final_report_check = client.get(f"/api/v1/reports/{report_id}", headers=admin_headers).json()
    assert final_report_check["creator_display_name"] == "Caner Teknisyen"
