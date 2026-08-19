import os
import sys
import openpyxl

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
BACKEND_DIR = os.path.join(REPO_ROOT, "backend")
sys.path.insert(0, BACKEND_DIR)

from app.services.excel_engine import generate_excel_report

class MockReport:
    def __init__(self, report_type, data_dict):
        self.report_type = report_type
        self.transformer_type = report_type
        self.customer_name = data_dict.get("customer_name", "BREAKER DC TEST A.S.")
        self.trafo_label = data_dict.get("trafo_label", "TR-BRK-01")
        self.data_json = data_dict

def test_breaker_dc_voltage():
    all_passed = True

    # Scenario 1: Breaker included, no breaker DC voltage selected, main trafo has 24 VDC
    data1 = {
        "has_breaker": True,
        "breaker_included": True,
        "dc_redresor_voltage": "24 VDC", # Main page G31
        "breaker_dc_redresor_voltage": None, # Breaker page G26 -> MUST BE NONE
        "breaker_control_dc_redresor": True,
    }

    # Scenario 2: Breaker included, breaker DC voltage 110 VDC, main trafo unselected (None)
    data2 = {
        "has_breaker": True,
        "breaker_included": True,
        "dc_redresor_voltage": None, # Main page G31 -> MUST BE NONE
        "breaker_dc_redresor_voltage": "110 VDC", # Breaker page G26 -> MUST BE "110 VDC"
        "breaker_control_dc_redresor": True,
    }

    # Scenario 3: Breaker included, breaker DC voltage 24 VDC, main trafo 110 VDC
    data3 = {
        "has_breaker": True,
        "breaker_included": True,
        "dc_redresor_voltage": "110 VDC", # Main page G31 -> MUST BE "110 VDC"
        "breaker_dc_redresor_voltage": "24 VDC", # Breaker page G26 -> MUST BE "24 VDC"
        "breaker_control_dc_redresor": False,
    }

    scenarios = [
        ("Scenario 1 (Breaker Voltage=None, Main Voltage=24 VDC)", data1, None, "24 VDC", "ü", None),
        ("Scenario 2 (Breaker Voltage=110 VDC, Main Voltage=None)", data2, "110 VDC", None, "ü", None),
        ("Scenario 3 (Breaker Voltage=24 VDC, Main Voltage=110 VDC)", data3, "24 VDC", "110 VDC", None, "ü"),
    ]

    for label, data, exp_brk_g26, exp_main_g31, exp_i26, exp_j26 in scenarios:
        print(f"\n==================================================")
        print(f"TESTING {label}")
        print(f"==================================================")
        out_file = os.path.join(REPO_ROOT, "tools", "test_out_breaker_dc.xlsx")
        report = MockReport("HERMETIK", data)
        generate_excel_report(report, photos=[], output_path=out_file)

        wb = openpyxl.load_workbook(out_file, data_only=False)

        # 1. Verify ANA SAYFA G31 (Main Trafo DC Voltage)
        ws_main = wb["ANA SAYFA"]
        g31_val = ws_main["G31"].value
        print(f"[ANA SAYFA] Cell G31 (Main DC Voltage): {g31_val!r} (Expected: {exp_main_g31!r})")
        if g31_val != exp_main_g31:
            print(f"  FAIL: Main G31 mismatch! Got {g31_val!r}, expected {exp_main_g31!r}")
            all_passed = False

        # 2. Verify ANA SAYFA KESİCİ G26 (Breaker DC Voltage) & I26/J26 Checkmarks
        ws_brk = wb["ANA SAYFA KESİCİ"]
        g26_val = ws_brk["G26"].value
        i26_val = ws_brk["I26"].value
        j26_val = ws_brk["J26"].value

        print(f"[ANA SAYFA KESİCİ] Cell G26 (Breaker DC Voltage): {g26_val!r} (Expected: {exp_brk_g26!r})")
        if g26_val != exp_brk_g26:
            print(f"  FAIL: Breaker G26 mismatch! Got {g26_val!r}, expected {exp_brk_g26!r}")
            all_passed = False

        print(f"[ANA SAYFA KESİCİ] I26/J26 Checkmarks: Evet={i26_val!r}, Hayir={j26_val!r} (Expected Evet={exp_i26!r}, Hayir={exp_j26!r})")
        if i26_val != exp_i26 or j26_val != exp_j26:
            print(f"  FAIL: Breaker I26/J26 checkmark mismatch!")
            all_passed = False

    print("\n==================================================")
    print(f"ALL BREAKER DC VOLTAGE TESTS PASSED: {all_passed}")
    print(f"==================================================")
    return all_passed

if __name__ == "__main__":
    if not test_breaker_dc_voltage():
        sys.exit(1)
