import os
import re
from datetime import datetime
from typing import List, Optional, Dict
import openpyxl
from openpyxl.drawing.image import Image as OpenPyXLImage

from app.core.config import settings
from app.models.report import Report
from app.models.photo import Photo

# Template file mappings
TEMPLATE_PATHS = {
    "HERMETIK": os.path.join("templates", "HERMETİK TRAFO BAKIM RAPORU HİLMİ.xlsx"),
    "KURU_TIP": os.path.join("templates", "KURU TİP HİLMİ.xlsx"),
    "GT": os.path.join("templates", "TR BAKIM RAPORU GT HİLMİ.xlsx")
}

# Type-specific cell mappings per sheet
TYPE_CELL_MAPPINGS: Dict[str, Dict[str, Dict[str, str]]] = {
    "HERMETIK": {
        "KAPAK SAYFASI": {
            "D9": "customer_name",
            "D10": "trafo_label",
            "D11": "address",
            "D12": "report_date",
            "D14": "test_date",
            "A31": "summary_text",
            "D56": "operator_title",
            "D57": "sicil_no",
            "D58": "ekipnet_no",
            "G56": "operator_name",
        },
        "ANA SAYFA": {
            "G11": "brand",
            "O11": "tap_info_1",
            "Q11": "tap_info_2",
            "S11": "tap_info_3",
            "G13": "power_kva",
            "O13": "manufacture_year",
            "G15": "voltage",
            "O15": "serial_no",
            "G17": "oil_brand",
            "O17": "oil_weight",
            "G19": "connection_group",
            "O19": "short_circuit_imp_pct",
            "G21": "tank_type",
            "I21": "tank_mark_hermetik",
            "P21": "tank_mark_gt",
            "U21": "tank_mark_kuru",
            "J27": "checklist_1",
            "J28": "checklist_2",
            "J29": "checklist_3",
            "J30": "checklist_4",
            "J31": "checklist_5",
            "J32": "checklist_6",
            "J33": "checklist_7",
            "J34": "checklist_8",
            "J35": "checklist_9",
            "J36": "checklist_10",
            "J37": "checklist_11",
            "J38": "checklist_12",
            "J39": "checklist_13",
            "J40": "checklist_14",
            "J41": "checklist_15",
            "J42": "checklist_16",
            "U27": "checklist_17",
            "U28": "checklist_18",
            "U29": "checklist_19",
            "U30": "checklist_20",
            "U31": "checklist_21",
            "U32": "checklist_22",
            "U33": "checklist_23",
            "U34": "checklist_24",
            "U35": "checklist_25",
            "U36": "checklist_26",
            "U37": "checklist_27",
            "U38": "checklist_28",
            "U39": "checklist_29",
            "U40": "checklist_30",
            "U41": "checklist_31",
            "U42": "checklist_32",
            "C55": "og_rab",
            "C57": "og_rbc",
            "C59": "og_rca",
            "J55": "ag_ran",
            "J57": "ag_rbn",
            "J59": "ag_rcn",
            "O55": "ag_rab",
            "O57": "ag_rbc",
            "O59": "ag_rca",
            "C61": "ground_r_trafo_body",
            "F61": "ground_r_neutral",
            "J61": "ground_r_tank",
            "C63": "ground_r_og_lightning",
            "F63": "ground_r_panel",
            "J63": "ground_r_fence",
            "B73": "notes",
            "F80": "operator_title",
            "F81": "sicil_no",
            "F82": "ekipnet_no",
            "K79": "operator_name",
        },
        "OG SARGI MEVCUT KADEME": {
            "D11": "operator_name",
            "J11": "device_model",
            "O11": "device_serial",
        },
        "AG SARGI": {
            "D11": "operator_name",
            "J11": "device_model",
            "O11": "device_serial",
        },
        "İZOLASYON ": {
            "D11": "operator_name",
            "J11": "device_model",
            "O11": "device_serial",
            "D16": "iso_og_gnd",
            "D17": "iso_ag_gnd",
            "D30": "iso_temp",
            "D31": "iso_humidity",
        },
        "Ç.O 34500": {
            "D11": "operator_name",
            "J11": "device_model",
            "O11": "device_serial",
            "B16": "ttr_tap1_a",
            "C16": "ttr_tap1_b",
            "D16": "ttr_tap1_c",
            "B17": "ttr_tap2_a",
            "C17": "ttr_tap2_b",
            "D17": "ttr_tap2_c",
            "B18": "ttr_tap3_a",
            "C18": "ttr_tap3_b",
            "D18": "ttr_tap3_c",
            "B19": "ttr_tap4_a",
            "C19": "ttr_tap4_b",
            "D19": "ttr_tap4_c",
            "B20": "ttr_tap5_a",
            "C20": "ttr_tap5_b",
            "D20": "ttr_tap5_c",
        },
        "TOPRAKLAMALAR": {
            "D9": "operator_name",
            "J9": "device_model",
            "O9": "device_serial",
            "D17": "ground_r_trafo_body",
            "D18": "ground_r_neutral",
            "D19": "ground_r_tank",
            "D32": "ground_r_og_lightning",
            "D33": "ground_r_panel",
            "D34": "ground_r_fence",
        },
        "HV PF": {
            "D11": "operator_name",
            "J11": "device_model",
            "O11": "device_serial",
            "P17": "pf_hv_humidity",
        },
        "LV PF": {
            "D11": "operator_name",
            "J11": "device_model",
            "O11": "device_serial",
            "P17": "pf_lv_humidity",
        },
        "ANA SAYFA KESİCİ": {
            "G11": "breaker_brand",
            "O11": "breaker_serial_no",
            "G13": "breaker_model",
            "O13": "breaker_year",
        },
        "KESİCİ İZOLASYON": {
            "D10": "operator_name",
            "J10": "device_model",
            "O10": "device_serial",
            "D10_VAL": "breaker_iso_r_gnd",
        },
        "KESİCİ KONTAK": {
            "D10": "operator_name",
            "J10": "device_model",
            "O10": "device_serial",
            "D10_VAL": "breaker_contact_r",
        },
        "AÇMA-KAPAMA": {
            "D9": "operator_name",
            "J9": "device_model",
            "O9": "device_serial",
            "D10": "breaker_timing_open",
        },
        "DİĞER": {
            "D9": "operator_name",
            "J9": "device_model",
            "O9": "device_serial",
            "D16": "device_model",
            "D17": "device_serial",
        },
        "AKIM TRAFOLARI": {
            "D9": "operator_name",
            "J9": "device_model",
            "O9": "device_serial",
            "D16": "ct_ratio",
        },
        "HERMETİK YAĞ DİLEKÇESİ": {
            "D16": "oil_test_breakdown_voltage",
            "D18": "oil_test_water_content",
        }
    },
    "KURU_TIP": {
        "KAPAK SAYFASI": {
            "D9": "customer_name",
            "D10": "trafo_label",
            "D11": "address",
            "D12": "report_date",
            "D14": "test_date",
            "A31": "summary_text",
            "D56": "operator_title",
            "D57": "sicil_no",
            "D58": "ekipnet_no",
            "G56": "operator_name",
        },
        "ANA SAYFA": {
            "G11": "brand",
            "O11": "tap_info_1",
            "Q11": "tap_info_2",
            "S11": "tap_info_3",
            "G13": "power_kva",
            "O13": "manufacture_year",
            "G15": "voltage",
            "O15": "serial_no",
            "G17": "connection_group",
            "O17": "short_circuit_imp_pct",
            "G19": "tank_type",
            "I19": "tank_mark_hermetik",
            "P19": "tank_mark_gt",
            "U19": "tank_mark_kuru",
            "J24": "checklist_1",
            "J25": "checklist_2",
            "J26": "checklist_3",
            "J27": "checklist_4",
            "J28": "checklist_5",
            "J29": "checklist_6",
            "J30": "checklist_7",
            "J31": "checklist_8",
            "J32": "checklist_9",
            "J33": "checklist_10",
            "J34": "checklist_11",
            "J35": "checklist_12",
            "J36": "checklist_13",
            "J37": "checklist_14",
            "J38": "checklist_15",
            "J39": "checklist_16",
            "U24": "checklist_17",
            "U25": "checklist_18",
            "U26": "checklist_19",
            "U27": "checklist_20",
            "U28": "checklist_21",
            "U29": "checklist_22",
            "U30": "checklist_23",
            "U31": "checklist_24",
            "U32": "checklist_25",
            "U33": "checklist_26",
            "U34": "checklist_27",
            "U35": "checklist_28",
            "U36": "checklist_29",
            "U37": "checklist_30",
            "U38": "checklist_31",
            "U39": "checklist_32",
            "C49": "og_rab",
            "C51": "og_rbc",
            "C53": "og_rca",
            "J49": "ag_ran",
            "J51": "ag_rbn",
            "J53": "ag_rcn",
            "O49": "ag_rab",
            "O51": "ag_rbc",
            "O53": "ag_rca",
            "C55": "ground_r_trafo_body",
            "F55": "ground_r_neutral",
            "J55": "ground_r_tank",
            "C57": "ground_r_og_lightning",
            "F57": "ground_r_panel",
            "J57": "ground_r_fence",
            "B67": "notes",
            "F74": "operator_title",
            "F75": "sicil_no",
            "F76": "ekipnet_no",
            "K73": "operator_name",
        },
        "OG SARGI MEVCUT KADEME": {
            "D11": "operator_name",
            "J11": "device_model",
            "O11": "device_serial",
        },
        "AG SARGI": {
            "D11": "operator_name",
            "J11": "device_model",
            "O11": "device_serial",
        },
        "İZOLASYON ": {
            "D11": "operator_name",
            "J11": "device_model",
            "O11": "device_serial",
            "D16": "iso_og_gnd",
            "D17": "iso_ag_gnd",
            "D30": "iso_temp",
            "D31": "iso_humidity",
        },
        "Ç.O 34500": {
            "D11": "operator_name",
            "J11": "device_model",
            "O11": "device_serial",
            "B16": "ttr_tap1_a",
            "C16": "ttr_tap1_b",
            "D16": "ttr_tap1_c",
            "B17": "ttr_tap2_a",
            "C17": "ttr_tap2_b",
            "D17": "ttr_tap2_c",
            "B18": "ttr_tap3_a",
            "C18": "ttr_tap3_b",
            "D18": "ttr_tap3_c",
            "B19": "ttr_tap4_a",
            "C19": "ttr_tap4_b",
            "D19": "ttr_tap4_c",
            "B20": "ttr_tap5_a",
            "C20": "ttr_tap5_b",
            "D20": "ttr_tap5_c",
        },
        "TOPRAKLAMALAR": {
            "D9": "operator_name",
            "J9": "device_model",
            "O9": "device_serial",
            "D17": "ground_r_trafo_body",
            "D18": "ground_r_neutral",
            "D19": "ground_r_tank",
            "D32": "ground_r_og_lightning",
            "D33": "ground_r_panel",
            "D34": "ground_r_fence",
        },
        "HV PF": {
            "D11": "operator_name",
            "J11": "device_model",
            "O11": "device_serial",
            "P17": "pf_hv_humidity",
        },
        "LV PF": {
            "D11": "operator_name",
            "J11": "device_model",
            "O11": "device_serial",
            "P17": "pf_lv_humidity",
        },
        "ANA SAYFA KESİCİ": {
            "G11": "breaker_brand",
            "O11": "breaker_serial_no",
            "G13": "breaker_model",
            "O13": "breaker_year",
        },
        "KESİCİ İZOLASYON": {
            "D10": "operator_name",
            "J10": "device_model",
            "O10": "device_serial",
            "D10_VAL": "breaker_iso_r_gnd",
        },
        "KESİCİ KONTAK": {
            "D10": "operator_name",
            "J10": "device_model",
            "O10": "device_serial",
            "D10_VAL": "breaker_contact_r",
        },
        "AÇMA-KAPAMA": {
            "D9": "operator_name",
            "J9": "device_model",
            "O9": "device_serial",
            "D10": "breaker_timing_open",
        },
        "DİĞER": {
            "D9": "operator_name",
            "J9": "device_model",
            "O9": "device_serial",
            "D16": "device_model",
            "D17": "device_serial",
        },
        "AKIM TRAFOLARI": {
            "D9": "operator_name",
            "J9": "device_model",
            "O9": "device_serial",
            "D16": "ct_ratio",
        }
    },
    "GT": {
        "KAPAK SAYFASI": {
            "D9": "customer_name",
            "D10": "trafo_label",
            "D11": "address",
            "D12": "report_date",
            "D14": "test_date",
            "A31": "summary_text",
            "D56": "operator_title",
            "D57": "sicil_no",
            "D58": "ekipnet_no",
            "G56": "operator_name",
        },
        "ANA SAYFA": {
            "G11": "brand",
            "O11": "tap_info_1",
            "Q11": "tap_info_2",
            "S11": "tap_info_3",
            "G13": "power_kva",
            "O13": "manufacture_year",
            "G15": "voltage",
            "O15": "serial_no",
            "G17": "oil_brand",
            "O17": "oil_weight",
            "G19": "connection_group",
            "O19": "short_circuit_imp_pct",
            "G21": "tank_type",
            "I21": "tank_mark_hermetik",
            "P21": "tank_mark_gt",
            "U21": "tank_mark_kuru",
            "J27": "checklist_1",
            "J28": "checklist_2",
            "J29": "checklist_3",
            "J30": "checklist_4",
            "J31": "checklist_5",
            "J32": "checklist_6",
            "J33": "checklist_7",
            "J34": "checklist_8",
            "J35": "checklist_9",
            "J36": "checklist_10",
            "J37": "checklist_11",
            "J38": "checklist_12",
            "J39": "checklist_13",
            "J40": "checklist_14",
            "J41": "checklist_15",
            "J42": "checklist_16",
            "U27": "checklist_17",
            "U28": "checklist_18",
            "U29": "checklist_19",
            "U30": "checklist_20",
            "U31": "checklist_21",
            "U32": "checklist_22",
            "U33": "checklist_23",
            "U34": "checklist_24",
            "U35": "checklist_25",
            "U36": "checklist_26",
            "U37": "checklist_27",
            "U38": "checklist_28",
            "U39": "checklist_29",
            "U40": "checklist_30",
            "U41": "checklist_31",
            "U42": "checklist_32",
            "C55": "og_rab",
            "C57": "og_rbc",
            "C59": "og_rca",
            "J55": "ag_ran",
            "J57": "ag_rbn",
            "J59": "ag_rcn",
            "O55": "ag_rab",
            "O57": "ag_rbc",
            "O59": "ag_rca",
            "C61": "ground_r_trafo_body",
            "F61": "ground_r_neutral",
            "J61": "ground_r_tank",
            "C63": "ground_r_og_lightning",
            "F63": "ground_r_panel",
            "J63": "ground_r_fence",
            "B73": "notes",
            "F80": "operator_title",
            "F81": "sicil_no",
            "F82": "ekipnet_no",
            "K79": "operator_name",
        },
        "OG SARGI MEVCUT KADEME": {
            "D11": "operator_name",
            "J11": "device_model",
            "O11": "device_serial",
        },
        "AG SARGI": {
            "D11": "operator_name",
            "J11": "device_model",
            "O11": "device_serial",
        },
        "İZOLASYON ": {
            "D11": "operator_name",
            "J11": "device_model",
            "O11": "device_serial",
            "D16": "iso_og_gnd",
            "D17": "iso_ag_gnd",
            "D30": "iso_temp",
            "D31": "iso_humidity",
        },
        "Ç.O 34500": {
            "D11": "operator_name",
            "J11": "device_model",
            "O11": "device_serial",
            "B16": "ttr_tap1_a",
            "C16": "ttr_tap1_b",
            "D16": "ttr_tap1_c",
            "B17": "ttr_tap2_a",
            "C17": "ttr_tap2_b",
            "D17": "ttr_tap2_c",
            "B18": "ttr_tap3_a",
            "C18": "ttr_tap3_b",
            "D18": "ttr_tap3_c",
            "B19": "ttr_tap4_a",
            "C19": "ttr_tap4_b",
            "D19": "ttr_tap4_c",
            "B20": "ttr_tap5_a",
            "C20": "ttr_tap5_b",
            "D20": "ttr_tap5_c",
        },
        "TOPRAKLAMALAR": {
            "D9": "operator_name",
            "J9": "device_model",
            "O9": "device_serial",
            "D17": "ground_r_trafo_body",
            "D18": "ground_r_neutral",
            "D19": "ground_r_tank",
            "D32": "ground_r_og_lightning",
            "D33": "ground_r_panel",
            "D34": "ground_r_fence",
        },
        "ANA SAYFA KESİCİ": {
            "G11": "breaker_brand",
            "O11": "breaker_serial_no",
            "G13": "breaker_model",
            "O13": "breaker_year",
        },
        "KESİCİ İZOLASYON": {
            "D10": "operator_name",
            "J10": "device_model",
            "O10": "device_serial",
            "D10_VAL": "breaker_iso_r_gnd",
        },
        "KESİCİ KONTAK": {
            "D10": "operator_name",
            "J10": "device_model",
            "O10": "device_serial",
            "D10_VAL": "breaker_contact_r",
        },
        "AÇMA-KAPAMA": {
            "D9": "operator_name",
            "J9": "device_model",
            "O9": "device_serial",
            "D10": "breaker_timing_open",
        },
        "YAĞ RAPORU": {
            "D16": "oil_test_breakdown_voltage",
            "D18": "oil_test_water_content",
        },
        "HERMETİK YAĞ DİLEKÇESİ": {
            "D16": "oil_test_breakdown_voltage",
            "D18": "oil_test_water_content",
        }
    }
}

# Global fallback mapping
CELL_MAPPING = TYPE_CELL_MAPPINGS["HERMETIK"]


def date_to_excel_serial(date_input: Optional[str]) -> Optional[float]:
    """Converts a date string (YYYY-MM-DD or DD.MM.YYYY) into an Excel serial date number (epoch: 1899-12-30)."""
    if not date_input:
        return None
    try:
        s_date = str(date_input).strip()
        if "." in s_date:
            parts = s_date.split(".")
            d_obj = datetime(int(parts[2]), int(parts[1]), int(parts[0])).date()
        elif "-" in s_date:
            parts = s_date.split("-")
            d_obj = datetime(int(parts[0]), int(parts[1]), int(parts[2])).date()
        else:
            return None
        epoch = datetime(1899, 12, 30).date()
        return float((d_obj - epoch).days)
    except Exception:
        return None


def sanitize_filename(filename: str) -> str:
    """Removes invalid OS filename characters."""
    return re.sub(r'[\\/*?:"<>|]', '_', filename)


def format_date_display(date_input: Optional[str]) -> str:
    """Formats date to DD.MM.YYYY for filenames."""
    if not date_input:
        return datetime.now().strftime("%d.%m.%Y")
    try:
        s_date = str(date_input).strip()
        if "." in s_date:
            parts = s_date.split(".")
            return f"{int(parts[0]):02d}.{int(parts[1]):02d}.{parts[2]}"
        elif "-" in s_date:
            parts = s_date.split("-")
            return f"{int(parts[2]):02d}.{int(parts[1]):02d}.{parts[0]}"
    except Exception:
        pass
    return datetime.now().strftime("%d.%m.%Y")


def generate_report_excel(
    report: Report,
    photos: List[Photo],
    signature_path: Optional[str] = None
) -> str:
    report_type = report.report_type.upper().strip()
    if report_type not in TYPE_CELL_MAPPINGS:
        if "KURU" in report_type:
            report_type = "KURU_TIP"
        elif "GT" in report_type or "TANK" in report_type:
            report_type = "GT"
        else:
            report_type = "HERMETIK"

    template_rel_path = TEMPLATE_PATHS.get(report_type, TEMPLATE_PATHS["HERMETIK"])
    
    # Try finding template relative to backend directory or project root
    template_full_path = os.path.abspath(os.path.join(os.getcwd(), template_rel_path))
    if not os.path.exists(template_full_path):
        template_full_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", template_rel_path))

    if not os.path.exists(template_full_path):
        raise FileNotFoundError(f"Şablon dosyası bulunamadı: {template_full_path}")

    # Load workbook preserving formulas and styles
    wb = openpyxl.load_workbook(template_full_path, data_only=False)

    # Flatten values dictionary from Report attributes and data_json
    data_dict = {}
    if report.data_json and isinstance(report.data_json, dict):
        data_dict.update(report.data_json)

    # Standard attributes override
    data_dict["customer_name"] = report.customer_name
    data_dict["trafo_label"] = report.trafo_label
    data_dict["report_date"] = report.report_date
    data_dict["test_date"] = report.test_date

    op_name = str(data_dict.get("operator_name") or data_dict.get("creator_display_name") or "").strip()
    if not op_name:
        raise ValueError("Operatör adı (operator_name) eksik veya boş. Lütfen profil bilgilerinizi güncelleyin.")
    data_dict["operator_name"] = op_name

    op_title = str(data_dict.get("operator_title") or data_dict.get("title") or "").strip()
    if not op_title:
        raise ValueError("Operatör unvanı (operator_title) eksik veya boş. Lütfen profil bilgilerinizi güncelleyin.")
    data_dict["operator_title"] = op_title

    if not data_dict.get("creator_display_name"):
        data_dict["creator_display_name"] = f"{op_name} ({op_title})"

    notes_text = data_dict.get("notes") or data_dict.get("notes_text") or ""
    if notes_text:
        notes_str = str(notes_text).strip()
        if not notes_str.upper().startswith("NOTLAR"):
            data_dict["notes"] = f"NOTLAR : {notes_str}"
        else:
            data_dict["notes"] = notes_str

    cell_mapping_to_use = TYPE_CELL_MAPPINGS.get(report_type, TYPE_CELL_MAPPINGS["HERMETIK"])

    force_overwrite_keys = {
        "operator_name", "operator_title", "creator_display_name", "sicil_no",
        "ekipnet_no", "notes", "device_model", "device_serial"
    }

    # Fill mapped cells across sheets
    for target_sheet_name, cell_map in cell_mapping_to_use.items():
        matched_sheet = None
        for sname in wb.sheetnames:
            if sname.strip() == target_sheet_name.strip():
                matched_sheet = sname
                break
        
        if matched_sheet:
            ws = wb[matched_sheet]
            for cell_ref, field_key in cell_map.items():
                if field_key in data_dict:
                    val = data_dict[field_key]
                    if val is not None:
                        cell_obj = ws[cell_ref]
                        if cell_obj.value is not None and str(cell_obj.value).strip().startswith("="):
                            if field_key not in force_overwrite_keys:
                                continue

                        if field_key in ["report_date", "test_date"]:
                            serial_val = date_to_excel_serial(val)
                            if serial_val is not None:
                                ws[cell_ref] = serial_val
                            else:
                                ws[cell_ref] = str(val)
                        else:
                            try:
                                if isinstance(val, (int, float)):
                                    ws[cell_ref] = val
                                elif str(val).replace('.', '', 1).replace('-', '', 1).isdigit():
                                    ws[cell_ref] = float(val) if '.' in str(val) else int(val)
                                else:
                                    ws[cell_ref] = str(val)
                            except Exception:
                                ws[cell_ref] = str(val)

    # Insert signature image if present (Anchor G56)
    if signature_path and os.path.exists(signature_path) and "KAPAK SAYFASI" in wb.sheetnames:
        ws_kapak = wb["KAPAK SAYFASI"]
        if hasattr(ws_kapak, '_images') and ws_kapak._images:
            filtered_images = []
            for img in ws_kapak._images:
                is_old_sig = False
                if hasattr(img, 'anchor') and hasattr(img.anchor, '_from'):
                    c = img.anchor._from.col
                    r = img.anchor._from.row
                    if c >= 6 and r >= 50:
                        is_old_sig = True
                if not is_old_sig:
                    filtered_images.append(img)
            ws_kapak._images = filtered_images
        try:
            img = OpenPyXLImage(signature_path)
            img.width = 140
            img.height = 60
            ws_kapak.add_image(img, "G56")
        except Exception:
            pass

    # Insert photos if present into existing cover page area without creating new sheet
    if photos and "KAPAK SAYFASI" in wb.sheetnames:
        ws_kapak = wb["KAPAK SAYFASI"]
        photo_cells = ["A35", "F35", "A43", "F43"]
        for idx, photo in enumerate(photos):
            if idx < len(photo_cells) and os.path.exists(photo.file_path):
                try:
                    img = OpenPyXLImage(photo.file_path)
                    img.width = 180
                    img.height = 120
                    ws_kapak.add_image(img, photo_cells[idx])
                except Exception:
                    pass

    # Fail-safe sweep for Hilmi text
    for sname in wb.sheetnames:
        ws = wb[sname]
        for row in ws.iter_rows():
            for cell in row:
                if cell.value is not None and isinstance(cell.value, str):
                    cval = cell.value
                    cval_u = cval.upper()
                    if "HİLMİ" in cval_u or "HILMI" in cval_u:
                        for old_term in ["Hilmi GÜL", "Hilmi GUL", "Hilmi"]:
                            cval = cval.replace(old_term, op_name)
                        cell.value = cval

    # Generate output directory and filename
    output_dir = os.path.join(settings.UPLOAD_DIR, "reports")
    os.makedirs(output_dir, exist_ok=True)

    date_str = format_date_display(report.report_date or report.test_date)
    raw_filename = f"{report.customer_name} - {report.trafo_label} - {date_str}.xlsx"
    clean_filename = sanitize_filename(raw_filename)
    output_file_path = os.path.join(output_dir, clean_filename)

    wb.save(output_file_path)
    return output_file_path
