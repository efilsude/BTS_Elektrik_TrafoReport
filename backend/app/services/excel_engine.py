import os
import re
from datetime import datetime
from typing import List, Optional, Dict
import openpyxl
from openpyxl.drawing.image import Image as OpenPyXLImage
from openpyxl.styles import Font, Alignment

from app.core.config import settings
from app.models.report import Report
from app.models.photo import Photo

# Template file mappings
TEMPLATE_PATHS = {
    "HERMETIK": os.path.join("templates", "HERMETİK TRAFO BAKIM RAPORU HİLMİ.xlsx"),
    "KURU_TIP": os.path.join("templates", "KURU TİP HİLMİ.xlsx"),
    "GT": os.path.join("templates", "TR BAKIM RAPORU GT HİLMİ.xlsx")
}

# Type-specific cell mappings per TYPE_CELL_MAPPINGS: Dict[str, Dict[str, Dict[str, str]]] = {
    "HERMETIK": {
        "KAPAK SAYFASI": {
            "D9": "customer_name",
            "D10": "trafo_label",
            "D11": "address",
            "D12": "report_date",
            "D14": "test_date",
            "A29": "summary_text",
            "D55": "operator_title",
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
            "F82": "operator_name",
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
        "HERMETİK YAĞ DİLEKÇESİ": {}
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
            "F75": "operator_name",
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
            "F82": "operator_name",
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
        "YAĞ RAPORU": {
            "D16": "oil_test_breakdown_voltage",
            "D18": "oil_test_water_content",
        },
        "HERMETİK YAĞ DİLEKÇESİ": {}
    }
}

SHEET_SIGNATURE_ANCHORS = {
    "HERMETIK": {},
    "KURU_TIP": {},
    "GT": {}
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


def date_to_excel_serial(date_input) -> Optional[float]:
    if date_input is None:
        return None
    try:
        if isinstance(date_input, (int, float)):
            return float(date_input)

        s_date = str(date_input).strip()
        if not s_date:
            return None

        dt_obj = None
        if "." in s_date:
            parts = s_date.split(".")
            if len(parts) == 3:
                p1, p2, p3 = int(parts[0]), int(parts[1]), int(parts[2])
                if p3 > 1000:
                    dt_obj = datetime(p3, p2, p1)
                elif p1 > 1000:
                    dt_obj = datetime(p1, p2, p3)
        elif "-" in s_date:
            parts = s_date.split("-")
            if len(parts) == 3:
                dt_obj = datetime(int(parts[0]), int(parts[1]), int(parts[2]))

        if dt_obj is not None:
            epoch = datetime(1899, 12, 30)
            return float((dt_obj - epoch).days)
    except Exception:
        pass
    return None


def get_writable_cell(ws, cell_ref: str):
    cell = ws[cell_ref]
    if type(cell).__name__ == 'MergedCell':
        for rng in ws.merged_cells.ranges:
            if cell_ref in rng:
                return ws.cell(rng.min_row, rng.min_col)
    return cell


def process_checklist_pairs(ws, report_type, data_dict):
    for cref in ["C61", "F61", "J61", "C63", "F63", "J63"]:
        try:
            cell = get_writable_cell(ws, cref)
            cell.value = None
        except Exception:
            pass

    pairs_map = CHECKLIST_PAIRS.get(report_type, CHECKLIST_PAIRS["HERMETIK"])
    for key, pair in pairs_map.items():
        evet_cell = get_writable_cell(ws, pair["evet"])
        hayir_cell = get_writable_cell(ws, pair["hayir"])

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
    for r in range(40, min(86, ws.max_row + 1)):
        for c in range(5, 15):
            cell = ws.cell(row=r, column=c)
            if type(cell).__name__ != 'MergedCell' and cell.value is not None:
                cval_str = str(cell.value).strip()
                cval_u = cval_str.upper()
                if "ONAYLAYAN" in cval_u:
                    for br in range(r + 1, min(r + 7, ws.max_row + 1)):
                        for bc in range(c, min(c + 7, 20)):
                            bcell = ws.cell(row=br, column=bc)
                            if type(bcell).__name__ != 'MergedCell':
                                bcell.value = None


def process_kapak_photos(ws_kapak, data_dict, photos: Optional[List[Photo]] = None):

    p_before = data_dict.get("photo_before")
    p_after = data_dict.get("photo_after")
    p_label = data_dict.get("photo_label")
    p_extra = data_dict.get("photo_extra")

    if photos:
        for p in photos:
            if hasattr(p, 'photo_type') and hasattr(p, 'file_path'):
                ptype = str(p.photo_type).lower()
                if 'before' in ptype:
                    p_before = p.file_path
                elif 'after' in ptype:
                    p_after = p.file_path
                elif 'label' in ptype or 'tag' in ptype:
                    p_label = p.file_path
                elif 'extra' in ptype:
                    p_extra = p.file_path

    photos_to_place = []
    if p_before and isinstance(p_before, str) and os.path.exists(p_before):
        photos_to_place.append((p_before, "Bakım Öncesi"))
    if p_after and isinstance(p_after, str) and os.path.exists(p_after):
        photos_to_place.append((p_after, "Bakım Sonrası"))
    if p_label and isinstance(p_label, str) and os.path.exists(p_label):
        photos_to_place.append((p_label, "Trafo Etiket / Plaka"))
    if p_extra and isinstance(p_extra, str) and os.path.exists(p_extra):
        photos_to_place.append((p_extra, "Ek Fotoğraf"))

    slots = [
        ("A32", "A38", 200, 120),
        ("G32", "G38", 200, 120),
        ("A40", "A47", 200, 115),
        ("G40", "G47", 200, 115),
    ]

    for _, caption_ref, _, _ in slots:
        try:
            cell = get_writable_cell(ws_kapak, caption_ref)
            cell.value = None
        except Exception:
            pass

    font_bold = Font(name="Calibri", size=10, bold=True)
    align_center = Alignment(horizontal="center", vertical="center")

    caption_merges = [("A38", "A38:D38"), ("G38", "G38:J38"), ("A47", "A47:D47"), ("G47", "G47:J47")]
    for cref, mrange in caption_merges:
        try:
            ws_kapak.merge_cells(mrange)
        except Exception:
            pass

    for idx, (p_path, label_text) in enumerate(photos_to_place):
        if idx < len(slots):
            anchor_cell, caption_ref, w_px, h_px = slots[idx]
            try:
                img = OpenPyXLImage(p_path)
                img.width = w_px
                img.height = h_px
                ws_kapak.add_image(img, anchor_cell)

                cell = get_writable_cell(ws_kapak, caption_ref)
                cell.value = label_text
                cell.font = font_bold
                cell.alignment = align_center
            except Exception:
                pass


def clean_5070_text(wb):
    for sname in wb.sheetnames:
        ws = wb[sname]
        for row in ws.iter_rows():
            for cell in row:
                if cell.value is not None and isinstance(cell.value, str):
                    cval_u = cell.value.upper()
                    if "5070" in cval_u or "ELEKTRONİK İMZA KANUNU" in cval_u or "ELEKTRONIK IMZA KANUNU" in cval_u:
                        cell.value = None


def clean_left_personnel_block(wb, op_name: str, op_title: str, test_date: Optional[str] = None, report_date: Optional[str] = None, data_dict: Optional[Dict[str, Any]] = None):
    """
    Ensures KAPAK sol kutu has ONLY:
      - Test Tarihi : {test_date}
      - Rapor Tarihi : {report_date}
      - Unvan : {operator_title}
    (İsim Soyad row at A52 is removed/cleared as requested by user).

    Cleans and standardizes personnel blocks and footers across ALL sub-pages:
      - UNVAN: written verbatim from operator_title
      - TEST TARİHİ: test_date
      - ODA SİCİL NO / EKİPNET NO: written ONLY if valid sicil_no / ekipnet_no exists in data_dict, otherwise CLEARED to prevent showing operator_name/title.
    """
    if data_dict is None:
        data_dict = {}

    real_sicil = str(data_dict.get("sicil_no") or "").strip()
    real_ekipnet = str(data_dict.get("ekipnet_no") or "").strip()

    if real_sicil == op_name or real_sicil == op_title:
        real_sicil = ""
    if real_ekipnet == op_name or real_ekipnet == op_title:
        real_ekipnet = ""

    for sname in wb.sheetnames:
        ws = wb[sname]
        if sname == "KAPAK SAYFASI":
            # Clear A52:F52 (Remove operator_name / İsim Soyad from KAPAK left box)
            for c_let in ["A", "B", "C", "D", "E", "F"]:
                try:
                    get_writable_cell(ws, f"{c_let}52").value = None
                except Exception:
                    pass

            get_writable_cell(ws, "A53").value = "Test Tarihi"
            get_writable_cell(ws, "C53").value = ":"
            if test_date:
                s_val = date_to_excel_serial(test_date)
                cell_d53 = get_writable_cell(ws, "D53")
                cell_d53.value = s_val if s_val is not None else str(test_date)
                cell_d53.number_format = "dd.mm.yyyy"

            get_writable_cell(ws, "A54").value = "Rapor Tarihi"
            get_writable_cell(ws, "C54").value = ":"
            if report_date:
                s_val = date_to_excel_serial(report_date)
                cell_d54 = get_writable_cell(ws, "D54")
                cell_d54.value = s_val if s_val is not None else str(report_date)
                cell_d54.number_format = "dd.mm.yyyy"

            get_writable_cell(ws, "A55").value = "Unvan"
            get_writable_cell(ws, "C55").value = ":"
            get_writable_cell(ws, "D55").value = op_title

            # Clear A56:F57 residuals
            for r in [56, 57]:
                for c_let in ["A", "B", "C", "D", "E", "F"]:
                    try:
                        get_writable_cell(ws, f"{c_let}{r}").value = None
                    except Exception:
                        pass

        elif "ANA SAYFA" in sname and sname != "ANA SAYFA KESİCİ":
            get_writable_cell(ws, "B79").value = "Test Tarihi"
            get_writable_cell(ws, "E79").value = ":"
            if test_date:
                s_val = date_to_excel_serial(test_date)
                cell_f79 = get_writable_cell(ws, "F79")
                cell_f79.value = s_val if s_val is not None else str(test_date)
                cell_f79.number_format = "dd.mm.yyyy"

            get_writable_cell(ws, "B80").value = "Rapor Tarihi"
            get_writable_cell(ws, "E80").value = ":"
            if report_date:
                s_val = date_to_excel_serial(report_date)
                cell_f80 = get_writable_cell(ws, "F80")
                cell_f80.value = s_val if s_val is not None else str(report_date)
                cell_f80.number_format = "dd.mm.yyyy"

            get_writable_cell(ws, "B81").value = "Unvan"
            get_writable_cell(ws, "E81").value = ":"
            get_writable_cell(ws, "F81").value = op_title

            # Clear rows 82, 83, 84 (A82:F84) - remove operator_name / İsim
            for r in [82, 83, 84]:
                for c_let in ["A", "B", "C", "D", "E", "F"]:
                    try:
                        get_writable_cell(ws, f"{c_let}{r}").value = None
                    except Exception:
                        pass

        # Sweep and clean sub-page personnel footers
        if sname != "KAPAK SAYFASI":
            for r in range(1, ws.max_row + 1):
                col_b_val = str(ws.cell(row=r, column=2).value or "").strip().upper()
                col_a_val = str(ws.cell(row=r, column=1).value or "").strip().upper()
                label_val = col_b_val if col_b_val else col_a_val
                if not label_val:
                    continue

                if label_val in ["UNVAN", "ÜNVAN"]:
                    target_cell = get_writable_cell(ws, f"F{r}")
                    target_cell.value = op_title
                elif label_val in ["TEST TARİHİ", "TEST TARIHI"]:
                    target_cell = get_writable_cell(ws, f"F{r}")
                    target_cell.value = "='KAPAK SAYFASI'!D53"
                    target_cell.number_format = "dd.mm.yyyy"
                elif any(kw in label_val for kw in ["ODA SİCİL NO", "ODA SICIL NO", "SICIL NO", "SİCİL NO", "EKİPNET NO", "EKIPNET NO"]):
                    # Clear entire row label & value cells for sicil_no / ekipnet_no
                    for c_let in ["A", "B", "C", "D", "E", "F"]:
                        try:
                            get_writable_cell(ws, f"{c_let}{r}").value = None
                        except Exception:
                            pass



def fix_subpage_dates(wb, test_date: Optional[str] = None, report_date: Optional[str] = None):
    """
    Fixes sub-page OTURUM TARİHİ cells across all worksheets (TOPRAKLAMALAR, HV PF, LV PF, DİĞER, AKIM TRAFOLARI, etc.)
    by pointing them to 'KAPAK SAYFASI'!D53 formula and applying number_format 'dd.mm.yyyy'.
    Ensures date cell never evaluates to 0 or '00.01.1900'.
    """
    subpage_date_cells = {
        "OG SARGI MEVCUT KADEME": "J9",
        "AG SARGI": "J9",
        "İZOLASYON ": "J9",
        "Ç.O 34500": "J9",
        "TOPRAKLAMALAR": "J7",
        "HV PF": "J9",
        "LV PF": "J9",
        "KESİCİ İZOLASYON": "J8",
        "KESİCİ KONTAK": "J8",
        "AÇMA-KAPAMA": "J7",
        "DİĞER": "J7",
        "AKIM TRAFOLARI": "J7",
    }
    for sname in wb.sheetnames:
        ws = wb[sname]
        cell_ref = subpage_date_cells.get(sname)
        if cell_ref:
            try:
                cell = get_writable_cell(ws, cell_ref)
                cell.value = "='KAPAK SAYFASI'!D53"
                cell.number_format = "dd.mm.yyyy"
            except Exception:
                pass
        else:
            for r in range(1, 15):
                for c in range(1, 10):
                    val = ws.cell(row=r, column=c).value
                    if val is not None and ("OTURUM TARİHİ" in str(val).upper() or "OTURUM TARIHI" in str(val).upper()):
                        target_col = c + 8 if c == 2 else c + 2
                        target_cell = ws.cell(row=r, column=target_col)
                        if type(target_cell).__name__ != 'MergedCell':
                            target_cell.value = "='KAPAK SAYFASI'!D53"
                            target_cell.number_format = "dd.mm.yyyy"


def process_oil_petition(wb, data_dict):
    """
    Dynamically replaces sample terms (date, brand, power_kva, serial_no)
    in the body paragraph (B10) of 'HERMETİK YAĞ DİLEKÇESİ' sheet without altering template layout or legal text.
    Also clears residual D16/D18 values on petition sheet.
    """
    for sname in wb.sheetnames:
        if "YAĞ DİLEKÇESİ" in sname.upper() or "YAG DILEKCESI" in sname.upper():
            ws = wb[sname]

            # Clear D16 and D18 to eliminate '30,0' artifact
            for cref in ["D16", "D18"]:
                try:
                    get_writable_cell(ws, cref).value = None
                except Exception:
                    pass

            # Update customer/location headers
            try:
                c_name = data_dict.get("customer_name")
                if c_name:
                    get_writable_cell(ws, "J2").value = str(c_name).strip()
                else:
                    get_writable_cell(ws, "J2").value = "='KAPAK SAYFASI'!D9"

                addr = data_dict.get("address") or data_dict.get("location")
                if addr:
                    get_writable_cell(ws, "J3").value = str(addr).strip()
                else:
                    get_writable_cell(ws, "J3").value = "='KAPAK SAYFASI'!D11"
            except Exception:
                pass

            # Extract date
            raw_date = data_dict.get("test_date") or data_dict.get("report_date")
            formatted_date = None
            if raw_date:
                s_d = str(raw_date).strip()
                if "." in s_d:
                    formatted_date = s_d
                elif "-" in s_d:
                    parts = s_d.split("-")
                    if len(parts) == 3:
                        formatted_date = f"{parts[2]}.{parts[1]}.{parts[0]}"
            if not formatted_date:
                formatted_date = datetime.now().strftime("%d.%m.%Y")

            brand_val = str(data_dict.get("brand") or "").strip()
            if not brand_val:
                brand_val = "ASTOR"

            power_val = data_dict.get("power_kva")
            if power_val:
                str_p = str(power_val).strip()
                if not str_p.lower().endswith("kva"):
                    str_p += "kVA"
            else:
                str_p = "1000kVA"

            serial_val = str(data_dict.get("serial_no") or "").strip()
            if not serial_val:
                serial_val = "27-07840"

            canonical_text = (
                "\n              İşletmenizde bulunan trafoların testini {date} tarihinde yapmış bulunmaktayız.\n"
                "Test kapsamında istenilen trafo yağ analizi işleminin yapılabilmesi için trafodan yağ numunesi alınması gerekmektedir. "
                "İşletmenizde bulunan {brand} marka, {power_kva}, '{serial_no}' seri numaralı trafonun hermetik tip olmasından dolayı yağ numunesi alınmamıştır.          \n"
                "                                                                                                                                                               \n"
                "              Hermetik tip trafolar atmosfere kapalıdır ve numune alma yerleri mühürlüdür. Mühürlerin açılıp numune alınması durumunda trafonun hermetik özelliği bozulacağından dolayı, fabrika standartlarına göre arıza durumu olmadığı sürece hiçbir şekilde hermetik trafolardan yağ numunesi alınamaz.\n\n"
                "              \n"
                "              Bilgilerinize sunarız.\n\n"
            )

            cell_b10 = get_writable_cell(ws, "B10")
            current_val = cell_b10.value

            if current_val and isinstance(current_val, str) and ("işletmenizde bulunan" in current_val.lower() or "trafo" in current_val.lower()):
                text = current_val
                text = re.sub(r"\b\d{2}\.\d{2}\.\d{4}\b", formatted_date, text)
                if brand_val != "ASTOR":
                    text = text.replace("ASTOR", brand_val)
                if str_p != "1000kVA":
                    text = text.replace("1000kVA", str_p).replace("1000 kVA", str_p)
                if serial_val != "27-07840":
                    text = text.replace("27-07840", serial_val)
                cell_b10.value = text
            else:
                text = canonical_text.format(
                    date=formatted_date,
                    brand=brand_val,
                    power_kva=str_p,
                    serial_no=serial_val
                )
                cell_b10.value = text

def apply_format_and_column_width_fixes(wb):
    for sname in ["KAPAK SAYFASI", "ANA SAYFA"]:
        if sname in wb.sheetnames:
            ws = wb[sname]
            ws.column_dimensions["D"].width = max(ws.column_dimensions["D"].width or 0, 14.0)
            for cref in ["D12", "D14", "D53", "D54"]:
                if cref in ws:
                    ws[cref].number_format = "dd.mm.yyyy"

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

    for sname in wb.sheetnames:
        if any(k in sname.upper() for k in ["AG SARGI", "OG SARGI"]):
            ws = wb[sname]
            ws.column_dimensions["G"].width = max(ws.column_dimensions["G"].width or 0, 15.0)
            for r in [24, 25, 26]:
                cell = ws[f"G{r}"]
                if cell.number_format in ["General", "0.000000"]:
                    cell.number_format = "0.00"


def generate_excel_report(report: Report, photos: List[Photo], output_path: str) -> str:
    mapped_type = (report.transformer_type or "HERMETIK").upper()
    if "KURU" in mapped_type:
        mapped_type = "KURU_TIP"
    elif "GT" in mapped_type or "TANK" in mapped_type:
        mapped_type = "GT"
    else:
        mapped_type = "HERMETIK"

    template_rel_path = TEMPLATE_PATHS.get(mapped_type, TEMPLATE_PATHS["HERMETIK"])
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    template_abs_path = os.path.join(base_dir, template_rel_path)

    if not os.path.exists(template_abs_path):
        raise FileNotFoundError(f"Template file not found at: {template_abs_path}")

    wb = openpyxl.load_workbook(template_abs_path, data_only=False)

    data_dict = report.data_json or {}
    op_name = str(data_dict.get("operator_name") or "").strip() or "Operatör"
    op_title = str(data_dict.get("operator_title") or "").strip() or "Elektrik Mühendisi"

    cell_map_sheets = TYPE_CELL_MAPPINGS.get(mapped_type, TYPE_CELL_MAPPINGS["HERMETIK"])
    force_overwrite_keys = {
        "operator_name", "operator_title", "creator_display_name", "notes", "device_model", "device_serial"
    }

    for target_sheet_name, cell_map in cell_map_sheets.items():
        matched_sheet = None
        for sname in wb.sheetnames:
            if sname.strip() == target_sheet_name.strip():
                matched_sheet = sname
                break

        if matched_sheet:
            ws = wb[matched_sheet]
            if target_sheet_name.strip() == "ANA SAYFA":
                process_checklist_pairs(ws, mapped_type, data_dict)

            for cell_ref, field_key in cell_map.items():
                if field_key.startswith("TODO_VERIFY"):
                    continue

                if field_key in data_dict:
                    val = data_dict[field_key]
                    if val is None:
                        continue

                    cell_obj = get_writable_cell(ws, cell_ref)

                    if cell_obj.value is not None and str(cell_obj.value).strip().startswith("="):
                        if field_key not in force_overwrite_keys:
                            continue

                    if field_key.startswith("checklist_") or field_key.startswith("tank_mark_"):
                        if val is True or str(val).strip() in ["true", "ü", "1"]:
                            cell_obj.value = "ü"
                        continue

                    if field_key in ["report_date", "test_date"]:
                        serial_val = date_to_excel_serial(val)
                        if serial_val is not None:
                            cell_obj.value = serial_val
                        else:
                            cell_obj.value = str(val)
                        cell_obj.number_format = "dd.mm.yyyy"
                        continue

                    if isinstance(val, bool):
                        cell_obj.value = "ü" if val else ""
                    elif isinstance(val, (int, float)):
                        cell_obj.value = val
                    else:
                        str_val = str(val).strip()
                        clean_num = str_val.replace(',', '.')
                        try:
                            if '.' in clean_num:
                                cell_obj.value = float(clean_num)
                            else:
                                cell_obj.value = int(clean_num)
                        except Exception:
                            cell_obj.value = str_val

    sig_path = data_dict.get("signature_path") or data_dict.get("signature")
    sheet_signature_map = SHEET_SIGNATURE_ANCHORS.get(mapped_type, SHEET_SIGNATURE_ANCHORS["HERMETIK"])

    for sname in wb.sheetnames:
        ws = wb[sname]
        target_anchor = None
        for k_sheet, a_cell in sheet_signature_map.items():
            if k_sheet.strip() == sname.strip():
                target_anchor = a_cell
                break
        process_sheet_signature(ws, target_anchor, sig_path)

    if "KAPAK SAYFASI" in wb.sheetnames:
        process_kapak_photos(wb["KAPAK SAYFASI"], data_dict, photos)

    clean_5070_text(wb)
    test_date_val = data_dict.get("test_date")
    report_date_val = data_dict.get("report_date")
    clean_left_personnel_block(wb, op_name, op_title, test_date=test_date_val, report_date=report_date_val, data_dict=data_dict)
    fix_subpage_dates(wb, test_date=test_date_val, report_date=report_date_val)
    process_oil_petition(wb, data_dict)
    # Note: customize_charts_marker_only is permanently disabled at runtime to prevent drawing5 corruption

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

    apply_format_and_column_width_fixes(wb)

    os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
    wb.save(output_path)
    fix_xlsx_rels(output_path)
    return output_path
