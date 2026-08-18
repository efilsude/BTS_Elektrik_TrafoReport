import os
import zipfile
import xml.etree.ElementTree as ET

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
TEMPLATES_DIR = os.path.join(REPO_ROOT, "backend", "templates")
REF_PATH = os.path.join(TEMPLATES_DIR, "reference", "yeni_tasarim_referans.xlsx")
HILMI_PATH = os.path.join(TEMPLATES_DIR, "HERMETİK TRAFO BAKIM RAPORU HİLMİ.xlsx")
HYBRID_PATH = os.path.join(TEMPLATES_DIR, "hybrid", "hermetik_hybrid.xlsx")
OUTPUT_PATH = os.path.join(REPO_ROOT, "tools", "t1_minimal_output.xlsx")

def dump_xml_page_settings(xlsx_path, tag):
    print(f"\n==================================================")
    print(f"DUMPING XML PAGE SETTINGS: {tag} ({os.path.basename(xlsx_path)})")
    print(f"==================================================")
    
    ns = {
        'ns': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main',
        'r': 'http://schemas.openxmlformats.org/officeDocument/2006/relationships'
    }
    
    with zipfile.ZipFile(xlsx_path, 'r') as z:
        wb_tree = ET.fromstring(z.read('xl/workbook.xml'))
        rel_map = {}
        for child in ET.fromstring(z.read('xl/_rels/workbook.xml.rels')):
            rel_map[child.get('Id')] = child.get('Target')
            
        for s in wb_tree.findall('.//ns:sheet', ns):
            sname = s.get('name')
            s_rid = s.get('{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id')
            target_path = rel_map.get(s_rid, '')
            if target_path.startswith('/xl/'):
                target_path = target_path[4:]
            elif not target_path.startswith('xl/'):
                target_path = 'xl/' + target_path
                
            tree = ET.fromstring(z.read(target_path))
            
            sv = tree.find('.//ns:sheetView', ns)
            sf = tree.find('.//ns:sheetFormatPr', ns)
            ps = tree.find('.//ns:pageSetup', ns)
            pspr = tree.find('.//ns:pageSetUpPr', ns)
            pm = tree.find('.//ns:pageMargins', ns)
            po = tree.find('.//ns:printOptions', ns)
            cols = tree.find('.//ns:cols', ns)
            
            sv_attr = dict(sv.attrib) if sv is not None else None
            sf_attr = dict(sf.attrib) if sf is not None else None
            ps_attr = dict(ps.attrib) if ps is not None else None
            pspr_attr = dict(pspr.attrib) if pspr is not None else None
            pm_attr = dict(pm.attrib) if pm is not None else None
            po_attr = dict(po.attrib) if po is not None else None
            col_count = len(cols.findall('ns:col', ns)) if cols is not None else 0
            
            print(f"\nSheet: '{sname}' ({target_path})")
            print(f"  sheetView:     {sv_attr}")
            print(f"  sheetFormatPr: {sf_attr}")
            print(f"  pageSetup:     {ps_attr}")
            print(f"  pageSetUpPr:   {pspr_attr}")
            print(f"  printOptions:  {po_attr}")
            print(f"  pageMargins:   {pm_attr}")
            print(f"  cols tag count: {col_count}")

def main():
    dump_xml_page_settings(REF_PATH, "REFERANS")
    dump_xml_page_settings(HILMI_PATH, "HİLMİ")
    dump_xml_page_settings(HYBRID_PATH, "HYBRID")
    dump_xml_page_settings(OUTPUT_PATH, "OUTPUT")

if __name__ == "__main__":
    main()
