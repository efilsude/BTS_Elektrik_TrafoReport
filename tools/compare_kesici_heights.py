import os
import openpyxl

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
TEMPLATES_DIR = os.path.join(REPO_ROOT, "backend", "templates")
HYBRID_DIR = os.path.join(TEMPLATES_DIR, "hybrid")
TOOLS_DIR = os.path.join(REPO_ROOT, "tools")

ORIGINAL_PATH = os.path.join(TEMPLATES_DIR, "HERMETİK TRAFO BAKIM RAPORU HİLMİ.xlsx")
HYBRID_PATH = os.path.join(HYBRID_DIR, "hermetik_hybrid.xlsx")
OUTPUT_PATH = os.path.join(TOOLS_DIR, "test_out_with_breaker.xlsx")

def inspect_sheet_heights(path, sheet_name="ANA SAYFA KESİCİ"):
    if not os.path.exists(path):
        return None, f"File not found: {path}"
    
    wb = openpyxl.load_workbook(path, data_only=False)
    if sheet_name not in wb.sheetnames:
        return None, f"Sheet '{sheet_name}' not found in {path}"
    
    ws = wb[sheet_name]
    def_rh = getattr(ws.sheet_format, 'defaultRowHeight', 15.0)
    
    heights = {}
    for r in range(1, 85):
        rd = ws.row_dimensions.get(r)
        if rd and rd.height is not None:
            heights[r] = (rd.height, True)
        else:
            heights[r] = (def_rh, False)
            
    return {"default_rh": def_rh, "heights": heights}, "OK"

def main():
    print("=== COMPARING 'ANA SAYFA KESICI' ROW HEIGHTS ===")
    print(f"1. Original: {ORIGINAL_PATH}")
    print(f"2. Hybrid:   {HYBRID_PATH}")
    print(f"3. Output:   {OUTPUT_PATH}\n")
    
    orig_data, err1 = inspect_sheet_heights(ORIGINAL_PATH)
    hybr_data, err2 = inspect_sheet_heights(HYBRID_PATH)
    out_data, err3 = inspect_sheet_heights(OUTPUT_PATH)
    
    if not orig_data:
        print(f"ERROR: {err1}")
        return
    if not hybr_data:
        print(f"ERROR: {err2}")
        return
    if not out_data:
        print(f"ERROR: {err3}")
        return
        
    print(f"Default Row Height: Original={orig_data['default_rh']}, Hybrid={hybr_data['default_rh']}, Output={out_data['default_rh']}\n")
    
    print("| Row | Original Height | Hybrid Height | Output Height | Orig vs Hybr Diff | Hybr vs Out Diff | Match? |")
    print("|---|---|---|---|---|---|---|")
    
    match_count = 0
    total_rows = 80
    
    for r in range(1, total_rows + 1):
        o_h, o_c = orig_data["heights"][r]
        h_h, h_c = hybr_data["heights"][r]
        out_h, out_c = out_data["heights"][r]
        
        diff1 = abs(o_h - h_h)
        diff2 = abs(h_h - out_h)
        
        is_match = (diff1 <= 1.0) and (diff2 <= 1.0)
        if is_match:
            match_count += 1
            
        match_str = "[OK]" if is_match else "[MISMATCH]"
        print(f"| R{r:02d} | {o_h} (c={o_c}) | {h_h} (c={h_c}) | {out_h} (c={out_c}) | {diff1:.2f} | {diff2:.2f} | {match_str} |")
        
    match_pct = (match_count / total_rows) * 100
    print(f"\nSummary: {match_count}/{total_rows} rows match within +-1pt ({match_pct:.1f}% match rate)")

if __name__ == "__main__":
    main()
