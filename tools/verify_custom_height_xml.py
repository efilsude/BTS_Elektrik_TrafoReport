import os
import zipfile
import xml.etree.ElementTree as ET

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
TEMPLATES_DIR = os.path.join(REPO_ROOT, "backend", "templates")
HILMI_PATH = os.path.join(TEMPLATES_DIR, "HERMETİK TRAFO BAKIM RAPORU HİLMİ.xlsx")
OUTPUT_PATH = os.path.join(REPO_ROOT, "tools", "t1_minimal_output.xlsx")

def inspect_row_custom_height(xlsx_path, sheet_name):
    print(f"\n==================================================")
    print(f"INSPECTING XML ROW customHeight ATTRIBUTE IN: {os.path.basename(xlsx_path)} ({sheet_name})")
    print(f"==================================================")
    
    ns = {'ns': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}
    with zipfile.ZipFile(xlsx_path, 'r') as z:
        wb_tree = ET.fromstring(z.read('xl/workbook.xml'))
        rel_map = {c.get('Id'): c.get('Target') for c in ET.fromstring(z.read('xl/_rels/workbook.xml.rels'))}
        
        matched_path = None
        for s in wb_tree.findall('.//ns:sheet', ns):
            if s.get('name').strip() == sheet_name.strip():
                matched_path = rel_map.get(s.get('{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id'))
                break
        if not matched_path:
            print("Sheet not found")
            return
            
        if matched_path.startswith('/xl/'):
            matched_path = matched_path[4:]
        elif not matched_path.startswith('xl/'):
            matched_path = 'xl/' + matched_path
            
        sheet_xml = z.read(matched_path)
        tree = ET.fromstring(sheet_xml)
        
        rows_info = []
        for row in tree.findall('.//ns:row', ns):
            r_num = row.get('r')
            ht = row.get('ht')
            custom_ht = row.get('customHeight')
            rows_info.append((r_num, ht, custom_ht))
            
        print(f"Total <row> tags in XML: {len(rows_info)}")
        print("Sample <row> tags (1..30):")
        for r_num, ht, custom_ht in rows_info[:30]:
            print(f"  Row {r_num:2s}: ht={ht} | customHeight={custom_ht}")

def main():
    inspect_row_custom_height(HILMI_PATH, "ANA SAYFA KESİCİ")
    inspect_row_custom_height(OUTPUT_PATH, "ANA SAYFA KESİCİ")

if __name__ == "__main__":
    main()
