import os
import shutil
import openpyxl
import copy
import io
from openpyxl.drawing.image import Image

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
TEMPLATES_DIR = os.path.join(REPO_ROOT, "backend", "templates")
HYBRID_DIR = os.path.join(TEMPLATES_DIR, "hybrid")

REF_PATH = os.path.join(TEMPLATES_DIR, "reference", "yeni_tasarim_referans.xlsx")
OLD_HERMETIK_PATH = os.path.join(TEMPLATES_DIR, "HERMETİK TRAFO BAKIM RAPORU HİLMİ.xlsx")
OLD_GT_PATH = os.path.join(TEMPLATES_DIR, "TR BAKIM RAPORU GT HİLMİ.xlsx")
OLD_KURU_PATH = os.path.join(TEMPLATES_DIR, "KURU TİP HİLMİ.xlsx")


def copy_sheet_content(src_ws, target_ws):
    """Copies cell values, styles, merged cells, row heights, column widths, and images."""
    for r, rdim in src_ws.row_dimensions.items():
        if rdim.height is not None:
            target_ws.row_dimensions[r].height = rdim.height

    for c, cdim in src_ws.column_dimensions.items():
        if cdim.width is not None:
            target_ws.column_dimensions[c].width = cdim.width

    for row in src_ws.iter_rows(min_row=1, max_row=src_ws.max_row, min_col=1, max_col=src_ws.max_column):
        for cell in row:
            tcell = target_ws.cell(row=cell.row, column=cell.column)
            tcell.value = cell.value
            if cell.has_style:
                tcell.font = copy.copy(cell.font)
                tcell.border = copy.copy(cell.border)
                tcell.fill = copy.copy(cell.fill)
                tcell.number_format = cell.number_format
                tcell.protection = copy.copy(cell.protection)
                tcell.alignment = copy.copy(cell.alignment)

    for rng in src_ws.merged_cells.ranges:
        try:
            target_ws.merge_cells(str(rng))
        except Exception:
            pass

    if hasattr(src_ws, '_images') and src_ws._images:
        for img in src_ws._images:
            try:
                img_data = img._data()
                new_img = Image(io.BytesIO(img_data))
                if hasattr(img, 'anchor'):
                    new_img.anchor = copy.copy(img.anchor)
                target_ws.add_image(new_img)
            except Exception as e:
                print(f"Warning copying image in sheet {src_ws.title}: {e}")


def build_hermetik_hybrid():
    print("Building hermetik_hybrid.xlsx...")
    wb_ref = openpyxl.load_workbook(REF_PATH, data_only=False)
    wb_old = openpyxl.load_workbook(OLD_HERMETIK_PATH, data_only=False)

    for sname in wb_old.sheetnames:
        if sname not in wb_ref.sheetnames:
            target_ws = wb_ref.create_sheet(title=sname)
            copy_sheet_content(wb_old[sname], target_ws)

    original_order = wb_old.sheetnames
    ordered_sheets = []
    for sname in original_order:
        if sname in wb_ref.sheetnames:
            ordered_sheets.append(wb_ref[sname])
    for sname in wb_ref.sheetnames:
        if wb_ref[sname] not in ordered_sheets:
            ordered_sheets.append(wb_ref[sname])
    wb_ref._sheets = ordered_sheets

    out_hybrid = os.path.join(HYBRID_DIR, "hermetik_hybrid.xlsx")
    wb_ref.save(out_hybrid)
    shutil.copyfile(out_hybrid, OLD_HERMETIK_PATH)
    print(f"Saved: {out_hybrid} and updated {OLD_HERMETIK_PATH}")


def build_gt_hybrid():
    print("Building gt_hybrid.xlsx...")
    wb_ref = openpyxl.load_workbook(REF_PATH, data_only=False)
    wb_old = openpyxl.load_workbook(OLD_GT_PATH, data_only=False)

    for sname in wb_old.sheetnames:
        if sname not in wb_ref.sheetnames:
            target_ws = wb_ref.create_sheet(title=sname)
            copy_sheet_content(wb_old[sname], target_ws)

    original_order = wb_old.sheetnames
    ordered_sheets = []
    for sname in original_order:
        if sname in wb_ref.sheetnames:
            ordered_sheets.append(wb_ref[sname])
    for sname in wb_ref.sheetnames:
        if wb_ref[sname] not in ordered_sheets:
            ordered_sheets.append(wb_ref[sname])
    wb_ref._sheets = ordered_sheets

    out_hybrid = os.path.join(HYBRID_DIR, "gt_hybrid.xlsx")
    wb_ref.save(out_hybrid)
    shutil.copyfile(out_hybrid, OLD_GT_PATH)
    print(f"Saved: {out_hybrid} and updated {OLD_GT_PATH}")


def build_kuru_tip_hybrid():
    print("Building kuru_tip_hybrid.xlsx...")
    wb_kuru = openpyxl.load_workbook(OLD_KURU_PATH, data_only=False)
    wb_ref = openpyxl.load_workbook(REF_PATH, data_only=False)

    if "KAPAK SAYFASI" in wb_kuru.sheetnames:
        del wb_kuru["KAPAK SAYFASI"]
    kapak_ws = wb_kuru.create_sheet(title="KAPAK SAYFASI", index=0)
    copy_sheet_content(wb_ref["KAPAK SAYFASI"], kapak_ws)

    ref_ana = wb_ref["ANA SAYFA"]
    kuru_ana = wb_kuru["ANA SAYFA"]

    # Unmerge existing ranges in rows 1..21 of kuru_ana
    ranges_to_remove = []
    for rng in kuru_ana.merged_cells.ranges:
        if rng.min_row <= 21 or rng.max_row <= 21:
            ranges_to_remove.append(rng)
    for rng in ranges_to_remove:
        try:
            kuru_ana.unmerge_cells(str(rng))
        except Exception:
            pass

    # Copy row heights and cell values/styles for rows 1..21 from ref_ana
    for r in range(1, 22):
        if r in ref_ana.row_dimensions and ref_ana.row_dimensions[r].height is not None:
            kuru_ana.row_dimensions[r].height = ref_ana.row_dimensions[r].height
        for c in range(1, ref_ana.max_column + 1):
            cell = ref_ana.cell(row=r, column=c)
            tcell = kuru_ana.cell(row=r, column=c)
            tcell.value = cell.value
            if cell.has_style:
                tcell.font = copy.copy(cell.font)
                tcell.border = copy.copy(cell.border)
                tcell.fill = copy.copy(cell.fill)
                tcell.number_format = cell.number_format
                tcell.alignment = copy.copy(cell.alignment)

    # Re-apply merged cells from ref_ana for rows 1..21
    for rng in ref_ana.merged_cells.ranges:
        if rng.min_row <= 21 and rng.max_row <= 21:
            try:
                kuru_ana.merge_cells(str(rng))
            except Exception:
                pass

    if hasattr(ref_ana, '_images') and ref_ana._images:
        kuru_ana._images = []
        for img in ref_ana._images:
            try:
                img_data = img._data()
                new_img = Image(io.BytesIO(img_data))
                if hasattr(img, 'anchor'):
                    new_img.anchor = copy.copy(img.anchor)
                kuru_ana.add_image(new_img)
            except Exception as e:
                print(f"Warning copying ANA SAYFA image in Kuru Tip: {e}")

    out_hybrid = os.path.join(HYBRID_DIR, "kuru_tip_hybrid.xlsx")
    wb_kuru.save(out_hybrid)
    shutil.copyfile(out_hybrid, OLD_KURU_PATH)
    print(f"Saved: {out_hybrid} and updated {OLD_KURU_PATH}")


def main():
    os.makedirs(HYBRID_DIR, exist_ok=True)
    build_hermetik_hybrid()
    build_gt_hybrid()
    build_kuru_tip_hybrid()
    print("Master hybrid template generation completed successfully.")


if __name__ == "__main__":
    main()
