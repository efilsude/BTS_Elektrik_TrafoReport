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
            "A29": "summary_text",
            "D52": "operator_name",
            "D55": "operator_title",
            "D56": "sicil_no",
            "D57": "ekipnet_no",
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
            "C55": "og_rab",
            "C57": "og_rbc",
            "C59": "og_rca",
            "J55": "ag_ran",
            "J57": "ag_rbn",
            "J59": "ag_rcn",
            "O55": "ag_rab",
            "O57": "ag_rbc",
            "O59": "ag_rca",
            "B73": "notes",
            "F81": "operator_title",
            "F82": "sicil_no",
            "F83": "ekipnet_no",
            "K78": "operator_name",
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
            "G50": "breaker_iso_r_gnd",
            "O50": "breaker_contact_r",
            "F76": "operator_title",
            "F77": "sicil_no",
            "F78": "ekipnet_no",
            "K75": "operator_name",
        },
        "KESİCİ İZOLASYON": {
            "D10": "operator_name",
            "J10": "device_model",
            "O10": "device_serial",
        },
        "KESİCİ KONTAK": {
            "D10": "operator_name",
            "J10": "device_model",
            "O10": "device_serial",
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
            "A29": "summary_text",
            "D55": "operator_title",
            "D56": "sicil_no",
            "D57": "ekipnet_no",
            "G52": "operator_name",
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
            "G50": "breaker_iso_r_gnd",
            "O50": "breaker_contact_r",
            "F76": "operator_title",
            "F77": "sicil_no",
            "F78": "ekipnet_no",
            "K75": "operator_name",
        },
        "KESİCİ İZOLASYON": {
            "D10": "operator_name",
            "J10": "device_model",
            "O10": "device_serial",
        },
        "KESİCİ KONTAK": {
            "D10": "operator_name",
            "J10": "device_model",
            "O10": "device_serial",
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
            "A29": "summary_text",
            "D55": "operator_title",
            "D56": "sicil_no",
            "D57": "ekipnet_no",
            "G52": "operator_name",
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
            "C55": "og_rab",
            "C57": "og_rbc",
            "C59": "og_rca",
            "J55": "ag_ran",
            "J57": "ag_rbn",
            "J59": "ag_rcn",
            "O55": "ag_rab",
            "O57": "ag_rbc",
            "O59": "ag_rca",
            "J63": "ground_r_fence",
            "B73": "notes",
            "F81": "operator_title",
            "F82": "sicil_no",
            "F83": "ekipnet_no",
            "K78": "operator_name",
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
            "G50": "breaker_iso_r_gnd",
            "O50": "breaker_contact_r",
            "F76": "operator_title",
            "F77": "sicil_no",
            "F78": "ekipnet_no",
            "K75": "operator_name",
        },
        "KESİCİ İZOLASYON": {
            "D10": "operator_name",
            "J10": "device_model",
            "O10": "device_serial",
        },
        "KESİCİ KONTAK": {
            "D10": "operator_name",
            "J10": "device_model",
            "O10": "device_serial",
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

SHEET_SIGNATURE_ANCHORS = {
    "HERMETIK": {
        "ANA SAYFA": "K78",
        "ANA SAYFA KESİCİ": "K75",
        "OG SARGI MEVCUT KADEME": "J46",
        "AG SARGI": "J46",
        "İZOLASYON ": "J51",
        "Ç.O 34500": "J51",
        "TOPRAKLAMALAR": "J48",
        "HV PF": "J45",
        "LV PF": "J45",
        "KESİCİ İZOLASYON": "J41",
        "KESİCİ KONTAK": "J51",
        "AÇMA-KAPAMA": "J49",
        "DİĞER": "J45",
        "AKIM TRAFOLARI": "J45",
        "HERMETİK YAĞ DİLEKÇESİ": "J53",
    },
    "KURU_TIP": {
        "ANA SAYFA": "K73",
        "ANA SAYFA KESİCİ": "K75",
        "OG SARGI MEVCUT KADEME": "J46",
        "AG SARGI": "J46",
        "İZOLASYON ": "J51",
        "Ç.O 34500": "J51",
        "TOPRAKLAMALAR": "J48",
        "HV PF": "J45",
        "LV PF": "J45",
        "KESİCİ İZOLASYON": "J51",
        "KESİCİ KONTAK": "J51",
        "AÇMA-KAPAMA": "J49",
        "DİĞER": "J45",
        "AKIM TRAFOLARI": "J45",
    },
    "GT": {
        "ANA SAYFA": "K78",
        "ANA SAYFA KESİCİ": "K75",
        "OG SARGI MEVCUT KADEME": "J46",
        "AG SARGI": "J46",
        "İZOLASYON ": "J51",
        "Ç.O 34500": "J51",
        "TOPRAKLAMALAR": "J48",
        "KESİCİ İZOLASYON": "J51",
        "KESİCİ KONTAK": "J51",
        "AÇMA-KAPAMA": "J49",
        "YAĞ RAPORU": "J53",
        "HERMETİK YAĞ DİLEKÇESİ": "J53",
    }
}

CHECKLIST_PAIRS = {
    "HERMETIK": {
        "checklist_1": {"evet": "I27", "hayir": "J27"},
        "checklist_2": {"evet": "I29", "hayir": "J29"},
        "checklist_3": {"evet": "I31", "hayir": "J31"},
        "checklist_4": {"evet": "I33", "hayir": "J33"},
        "checklist_5": {"evet": "I35", "hayir": "J35"},
        "checklist_6": {"evet": "I37", "hayir": "J37"},
        "checklist_7": {"evet": "I39", "hayir": "J39"},
        "checklist_8": {"evet": "I41", "hayir": "J41"},
        "checklist_9": {"evet": "R27", "hayir": "S27"},
        "checklist_10": {"evet": "R29", "hayir": "S29"},
        "checklist_11": {"evet": "R31", "hayir": "S31"},
        "checklist_12": {"evet": "R33", "hayir": "S33"},
        "checklist_13": {"evet": "R35", "hayir": "S35"},
        "checklist_14": {"evet": "R37", "hayir": "S37"},
        "checklist_15": {"evet": "R39", "hayir": "S39"},
        "checklist_16": {"evet": "R41", "hayir": "S41"},
    },
    "KURU_TIP": {
        "checklist_1": {"evet": "I26", "hayir": "J26"},
        "checklist_2": {"evet": "I28", "hayir": "J28"},
        "checklist_3": {"evet": "I30", "hayir": "J30"},
        "checklist_4": {"evet": "I32", "hayir": "J32"},
        "checklist_5": {"evet": "I34", "hayir": "J34"},
        "checklist_6": {"evet": "I36", "hayir": "J36"},
        "checklist_7": {"evet": "R26", "hayir": "S26"},
        "checklist_8": {"evet": "R28", "hayir": "S28"},
        "checklist_9": {"evet": "R30", "hayir": "S30"},
        "checklist_10": {"evet": "R32", "hayir": "S32"},
        "checklist_11": {"evet": "R34", "hayir": "S34"},
        "checklist_12": {"evet": "R36", "hayir": "S36"},
    },
    "GT": {
        "checklist_1": {"evet": "I27", "hayir": "J27"},
        "checklist_2": {"evet": "I29", "hayir": "J29"},
        "checklist_3": {"evet": "I31", "hayir": "J31"},
        "checklist_4": {"evet": "I33", "hayir": "J33"},
        "checklist_5": {"evet": "I35", "hayir": "J35"},
        "checklist_6": {"evet": "I37", "hayir": "J37"},
        "checklist_7": {"evet": "I39", "hayir": "J39"},
        "checklist_8": {"evet": "I41", "hayir": "J41"},
        "checklist_9": {"evet": "R27", "hayir": "S27"},
        "checklist_10": {"evet": "R29", "hayir": "S29"},
        "checklist_11": {"evet": "R31", "hayir": "S31"},
        "checklist_12": {"evet": "R33", "hayir": "S33"},
        "checklist_13": {"evet": "R35", "hayir": "S35"},
        "checklist_14": {"evet": "R37", "hayir": "S37"},
        "checklist_15": {"evet": "R39", "hayir": "S39"},
        "checklist_16": {"evet": "R41", "hayir": "S41"},
    }
}


def process_checklist_pairs(ws, report_type, data_dict):
    """
    Sets Evet/Hayır checkmarks for checklist items and clears residual template sample checkmarks.
    Also clears 3.0 pt divider row cells C61, F61, J61, C63, F63, J63 on ANA SAYFA to prevent ghost text.
    """
    for cref in ["C61", "F61", "J61", "C63", "F63", "J63"]:
        if cref in ws:
            ws[cref].value = None

    pairs_map = CHECKLIST_PAIRS.get(report_type, CHECKLIST_PAIRS["HERMETIK"])
    for key, pair in pairs_map.items():
        evet_cell = ws[pair["evet"]]
        hayir_cell = ws[pair["hayir"]]

        val = data_dict.get(key)
        if val is None:
            evet_cell.value = None
            hayir_cell.value = None
        else:
            is_true = (val is True or str(val).strip().lower() in ["true", "ü", "1", "evet"])
            is_false = (val is False or str(val).strip().lower() in ["false", "0", "hayir", "hayır"])
            if is_true:
                evet_cell.value = "ü"
                hayir_cell.value = None
            elif is_false:
                evet_cell.value = None
                hayir_cell.value = "ü"
            else:
                evet_cell.value = None
                hayir_cell.value = None


def process_sheet_signature(ws, target_anchor: Optional[str], sig_path: Optional[str]):
    """
    Cleans old sample signature images from worksheet (row >= 30, col 5..13)
    and inserts the user signature image at target_anchor if sig_path exists.
    For KAPAK SAYFASI: Skip signature insertion completely and clean right side artifacts.
    """
    if ws.title == "KAPAK SAYFASI":
        if hasattr(ws, '_images') and ws._images:
            filtered = []
            for img in ws._images:
                is_right_side = False
                if hasattr(img, 'anchor') and hasattr(img.anchor, '_from'):
                    c = img.anchor._from.col
                    r = img.anchor._from.row
                    if r >= 30 and c >= 5:
                        is_right_side = True
                if not is_right_side:
                    filtered.append(img)
            ws._images = filtered
        # Clean any sample texts in rows 53..57, cols G..M
        for r in range(53, 58):
            for c_let in ["G", "H", "I", "J", "K", "L", "M"]:
                cell = ws[f"{c_let}{r}"]
                if type(cell).__name__ != 'MergedCell':
                    if cell.value is not None and isinstance(cell.value, str):
                        cval_u = cell.value.upper()
                        if any(term in cval_u for term in ["HİLMİ", "HILMI", "EMO", "DIPLOMA"]):
                            cell.value = None
        return

    if hasattr(ws, '_images') and ws._images:
        filtered = []
        for img in ws._images:
            is_old_sig = False
            if hasattr(img, 'anchor') and hasattr(img.anchor, '_from'):
                c = img.anchor._from.col
                r = img.anchor._from.row
                if r >= 30 and 5 <= c <= 13 and (getattr(img, 'width', 0) > 350 or getattr(img, 'height', 0) > 180):
                    is_old_sig = True
            if not is_old_sig:
                filtered.append(img)
        ws._images = filtered

    if sig_path and target_anchor and os.path.exists(sig_path):
        try:
            img = OpenPyXLImage(sig_path)
            img.width = 140
            img.height = 60
            ws.add_image(img, target_anchor)
        except Exception:
            pass


def apply_format_and_column_width_fixes(wb):
    """
    Ensures date cells, GΩ 20°C calculated cells, and V DC [V] cells have explicit number_format
    and sufficient column width to eliminate '#####' display issues.
    """
    # 1. KAPAK SAYFASI & ANA SAYFA (Col D for Dates)
    for sname in ["KAPAK SAYFASI", "ANA SAYFA"]:
        if sname in wb.sheetnames:
            ws = wb[sname]
            ws.column_dimensions["D"].width = max(ws.column_dimensions["D"].width or 0, 14.0)
            for cref in ["D12", "D14", "D54", "D55"]:
                if cref in ws:
                    ws[cref].number_format = "dd.mm.yyyy"

    # 2. İZOLASYON sheet (Cols B, D, F for measured GΩ; Cols H, J, L for 20°C calculated GΩ)
    for sname in wb.sheetnames:
        if "İZOLASYON" in sname.upper():
            ws = wb[sname]
            for col_let in ["B", "D", "F", "H", "J", "L"]:
                ws.column_dimensions[col_let].width = max(ws.column_dimensions[col_let].width or 0, 13.0)
            for r in range(16, 32):
                for col_let in ["B", "D", "F", "H", "J", "L"]:
                    cell = ws[f"{col_let}{r}"]
                    if cell.value is not None:
                        if cell.number_format in ["General", "0.000000"]:
                            cell.number_format = "0.00"

    # 3. AG SARGI & OG SARGI MEVCUT KADEME (Col G for V DC [V])
    for sname in wb.sheetnames:
        if any(k in sname.upper() for k in ["AG SARGI", "OG SARGI"]):
            ws = wb[sname]
            ws.column_dimensions["G"].width = max(ws.column_dimensions["G"].width or 0, 15.0)
            for r in [24, 25, 26]:
                cell = ws[f"G{r}"]
                if cell.number_format in ["General", "0.000000"]:
                    cell.number_format = "0.00"


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

    type_filename_map = {
        "HERMETIK": ("hermetik_hybrid.xlsx", "HERMETİK TRAFO BAKIM RAPORU HİLMİ.xlsx", "hermetik.xlsx"),
        "GT": ("gt_hybrid.xlsx", "TR BAKIM RAPORU GT HİLMİ.xlsx", "gt.xlsx"),
        "KURU_TIP": ("kuru_tip_hybrid.xlsx", "KURU TİP HİLMİ.xlsx", "kuru_tip.xlsx"),
    }
    
    hybrid_fname, old_fname, mobile_fname = type_filename_map.get(report_type, type_filename_map["HERMETIK"])
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

    candidates = [
        os.path.abspath(os.path.join(repo_root, "backend", "templates", "hybrid", hybrid_fname)),
        os.path.abspath(os.path.join(repo_root, "backend", "templates", old_fname)),
        os.path.abspath(os.path.join(repo_root, "mobile", "assets", "templates", mobile_fname)),
        os.path.abspath(os.path.join(repo_root, "mobile", "assets", "templates", old_fname)),
    ]

    template_full_path = None
    for cand in candidates:
        if os.path.exists(cand):
            template_full_path = cand
            sys.stderr.write(f"DEBUG (backend): Resolved template for {report_type}: {cand} (exists=True)\n")
            break

    if not template_full_path:
        raise FileNotFoundError(f"Şablon dosyası bulunamadı: {candidates[0]}")

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
            if target_sheet_name.strip() == "ANA SAYFA":
                process_checklist_pairs(ws, report_type, data_dict)

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
                            cell_obj.number_format = "dd.mm.yyyy"
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

    # Insert signature image across all sheets
    sig_path = signature_path or data_dict.get("signature_path") or data_dict.get("signature")
    sheet_signature_map = SHEET_SIGNATURE_ANCHORS.get(report_type, SHEET_SIGNATURE_ANCHORS["HERMETIK"])

    for sname in wb.sheetnames:
        ws = wb[sname]
        target_anchor = None
        for k_sheet, a_cell in sheet_signature_map.items():
            if k_sheet.strip() == sname.strip():
                target_anchor = a_cell
                break
        process_sheet_signature(ws, target_anchor, sig_path)

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

    # Breaker Sheet Pruning (remove breaker sheets if has_breaker is False)
    BREAKER_SHEETS = ["ANA SAYFA KESİCİ", "KESİCİ İZOLASYON", "KESİCİ KONTAK", "AÇMA-KAPAMA"]
    has_breaker = data_dict.get("has_breaker")
    if has_breaker is None:
        has_breaker = data_dict.get("breaker_included")
    if has_breaker is None:
        has_breaker = bool(data_dict.get("breaker_brand") or data_dict.get("breaker_iso_r_gnd") or data_dict.get("breaker_contact_r"))
    
    is_breaker_enabled = (has_breaker is True or str(has_breaker).strip().lower() in ["true", "1", "yes", "evet"])
    if not is_breaker_enabled:
        for b_sheet in BREAKER_SHEETS:
            if b_sheet in wb.sheetnames:
                del wb[b_sheet]

    # Fail-safe sweep for Hilmi and ULUSOY text
    b_brand = str(data_dict.get("breaker_brand") or "").strip()
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
                    if "ULUSOY" in cval_u:
                        cval = cval.replace("ULUSOY", b_brand)
                        if "ULusoy" in cval:
                            cval = cval.replace("ULusoy", b_brand)
                    cell.value = cval

    # Apply column width & number format fixes
    apply_format_and_column_width_fixes(wb)

    # Generate output directory and filename
    output_dir = os.path.join(settings.UPLOAD_DIR, "reports")
    os.makedirs(output_dir, exist_ok=True)

    date_str = format_date_display(report.report_date or report.test_date)
    raw_filename = f"{report.customer_name} - {report.trafo_label} - {date_str}.xlsx"
    clean_filename = sanitize_filename(raw_filename)
    output_file_path = os.path.join(output_dir, clean_filename)

    wb.save(output_file_path)
    return output_file_path
