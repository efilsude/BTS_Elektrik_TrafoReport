import os
import re
from datetime import datetime
from typing import List, Optional
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

# Cell mappings per sheet
CELL_MAPPING = {
    "KAPAK SAYFASI": {
        "D9": "customer_name",
        "D10": "trafo_label",
        "D11": "address",
        "D12": "report_date",
        "D14": "test_date",
        "D54": "test_date",
        "D55": "report_date",
        "D56": "operator_title",
        "D57": "sicil_no",
        "D58": "ekipnet_no",
        "B31": "summary_text"
    },
    "ANA SAYFA": {
        "K2": "customer_name",
        "K5": "trafo_label",
        "G11": "brand",
        "O11": "tap_info",
        "G13": "power_kva",
        "O13": "manufacture_year",
        "G15": "voltage",
        "O15": "serial_no",
        "G17": "oil_brand",
        "O17": "oil_weight",
        "G19": "connection_group",
        "O19": "short_circuit_imp_pct",
        "G21": "tank_type"
    },
    "OG SARGI MEVCUT KADEME": {
        "K24": "og_r_a",
        "K25": "og_r_b",
        "K26": "og_r_c"
    },
    "AG SARGI": {
        "K24": "ag_r_a",
        "K25": "ag_r_b",
        "K26": "ag_r_c"
    }
}

def date_to_excel_serial(date_input: Optional[str]) -> Optional[float]:
    """Converts a date string (YYYY-MM-DD or DD.MM.YYYY) into an Excel serial date number (epoch: 1899-12-30)."""
    if not date_input:
        return None
    try:
        if "." in str(date_input):
            parts = str(date_input).split(".")
            d_obj = datetime(int(parts[2]), int(parts[1]), int(parts[0])).date()
        elif "-" in str(date_input):
            parts = str(date_input).split("-")
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
        if "." in str(date_input):
            parts = str(date_input).split(".")
            return f"{int(parts[0]):02d}.{int(parts[1]):02d}.{parts[2]}"
        elif "-" in str(date_input):
            parts = str(date_input).split("-")
            return f"{int(parts[2]):02d}.{int(parts[1]):02d}.{parts[0]}"
    except Exception:
        pass
    return datetime.now().strftime("%d.%m.%Y")

def generate_report_excel(
    report: Report,
    photos: List[Photo],
    signature_path: Optional[str] = None
) -> str:
    report_type = report.report_type.upper()
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

    # Fill mapped cells across sheets
    for sheet_name, cell_map in CELL_MAPPING.items():
        if sheet_name in wb.sheetnames:
            ws = wb[sheet_name]
            for cell_ref, field_key in cell_map.items():
                if field_key in data_dict:
                    val = data_dict[field_key]
                    if val is not None:
                        # Convert date fields to Excel serial numbers
                        if field_key in ["report_date", "test_date"]:
                            serial_val = date_to_excel_serial(val)
                            if serial_val is not None:
                                ws[cell_ref] = serial_val
                            else:
                                ws[cell_ref] = str(val)
                        else:
                            # Try numeric conversion for measurements
                            try:
                                if isinstance(val, (int, float)):
                                    ws[cell_ref] = val
                                elif str(val).replace('.', '', 1).replace('-', '', 1).isdigit():
                                    ws[cell_ref] = float(val) if '.' in str(val) else int(val)
                                else:
                                    ws[cell_ref] = str(val)
                            except Exception:
                                ws[cell_ref] = str(val)

    # Insert signature image if present
    if signature_path and os.path.exists(signature_path) and "KAPAK SAYFASI" in wb.sheetnames:
        ws_kapak = wb["KAPAK SAYFASI"]
        try:
            img = OpenPyXLImage(signature_path)
            img.width = 120
            img.height = 50
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

    # Generate output directory and filename
    output_dir = os.path.join(settings.UPLOAD_DIR, "reports")
    os.makedirs(output_dir, exist_ok=True)

    date_str = format_date_display(report.report_date or report.test_date)
    raw_filename = f"{report.customer_name} - {report.trafo_label} - {date_str}.xlsx"
    clean_filename = sanitize_filename(raw_filename)
    output_file_path = os.path.join(output_dir, clean_filename)

    wb.save(output_file_path)
    return output_file_path
