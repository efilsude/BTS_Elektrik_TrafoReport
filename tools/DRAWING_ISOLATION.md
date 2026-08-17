# Excel Çizim Onarım İzolasyon Matrisi & Gerçek MS Excel Doğrulama Raporu

## 1. Gerçek MS Excel 16.0 İzolasyon Matrisi Sonuçları

| Adım | Çıktı Dosyası | Onarım Var Mı | Detay / Kaldırılan Öğe |
|---|---|---|---|
| **Adım 0a (Hilmi Master)** | `tools/iso_step0_hilmi.xlsx` | **TEMİZ (No Repair)** | Excel doğrudan ve hatasız açtı. |
| **Adım 0b (Hybrid Master)** | `tools/iso_step0_hybrid.xlsx` | **TEMİZ (No Repair)** | Excel doğrudan ve hatasız açtı. |
| **Adım 1 (Load + Save only)** | `tools/iso_step1.xlsx` | **TEMİZ (No Repair)** | openpyxl yükleme/kaydetme bozma yapmıyor. |
| **Adım 2 (Hücre Yazımı)** | `tools/iso_step2.xlsx` | **TEMİZ (No Repair)** | Hücre/metin doldurma bozmuyor. |
| **Adım 3 (+ fix_xlsx_rels)** | `tools/iso_step3.xlsx` | **TEMİZ (No Repair)** | İlişki yolları düzeltmesi tam uyumlu. |
| **Adım 4 (+ customize_charts)** | `tools/iso_step4.xlsx` | **ONARIM VAR (Repair Dialog)** | **KÖK NEDEN**: openpyxl chart nesnesi serilerini hafızada değiştirip kaydettiğinde `xl/charts/chartX.xml` şemasını bozuyor; Excel `drawing5.xml` dosyasını siliyor. |
| **Adım 5 (+ add_image Fotoğraf)** | `tools/iso_step5.xlsx` | **TEMİZ (No Repair)** | Fotoğraf ekleme (`add_image`) Excel'i bozmuyor. |

---

## 2. Alınan Karar ve Çözüm Politikası

- **Çözüm Politikası A Uygulandı**:
  `customize_charts_marker_only` fonksiyonunun runtime çağrısı `tools/generate_excel.py` ve `backend/app/services/excel_engine.py` içinde **KALICI OLARAK KAPATILDI**.
- **Sebep**: openpyxl'in grafik serileri üzerindeki runtime müdahaleleri (`line.noFill`, `scatterStyle`, `marker`) OpenXML grafik şemasında Excel'in reddettiği etiketler oluşturmaktadır. Grafiklerin çizgisiz gösterimi master şablon üzerinde varsayılan Excel ayarı olarak korunmuştur.
- **Kuru Tip Master Yeniden Yapılandırıldı**: `build_kuru_tip_hybrid()` fonksiyonu, görsel kopyalama nesnesi üretmeden temiz `wb_ref` şablonu temel alınarak güncellenmiş ve `kuru_tip_hybrid.xlsx` master şablonu %100 hatasız hale getirilmiştir.

---

## 3. Zorunlu Kabul Testleri ve MS Excel COM Doğrulaması

Gerçek Microsoft Excel 16.0 uygulaması ile COM otomasyonu üzerinden test edilmiş ve 3 rapor türünün tamamının **ONARIMSIZ / SIFIR UYARI** ile açıldığı kanıtlanmıştır:

1. **Hermetik Raporu** (`tools/test_excel_clean.xlsx`):
   - Excel Açılış Durumu: `STATUS: SUCCESS_OPEN` (16 sayfa)
   - Onarım Diyaloğu: **YOK**
   - `drawing5.xml`: Silinmiyor, tüm grafikler ve fotoğraflar tam.

2. **GT Raporu** (`tools/test_gt_clean.xlsx`):
   - Excel Açılış Durumu: `STATUS: SUCCESS_OPEN` (13 sayfa)
   - Onarım Diyaloğu: **YOK**

3. **Kuru Tip Raporu** (`tools/test_kuru_clean.xlsx`):
   - Excel Açılış Durumu: `STATUS: SUCCESS_OPEN` (16 sayfa)
   - Onarım Diyaloğu: **YOK**
