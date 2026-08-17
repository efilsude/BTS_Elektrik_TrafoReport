# Excel Drawing Repair Notes & Diagnostic Summary

## 1. Asıl Gerçek Kök Neden (True Root Cause)
Excel'deki **"Bazı öğelerde sorun / kurtarma"** ve **"Onarılan/kaldırılan: /xl/drawings/drawing1.xml … drawing12.xml (Çizim şekli), drawing5 kaldırıldı"** uyarısının **asıl temel nedeni**:

- openpyxl veya hibrit şablon kopyalama mekanizması tarafından oluşturulan ilişki (`.rels`) dosyalarında (ör. `xl/worksheets/_rels/sheetX.xml.rels` ve `xl/drawings/_rels/drawingX.xml.rels`), hedef (`Target`) yollarının başında **baştaki slaş `/xl/`** (`Target="/xl/drawings/drawing1.xml"`, `Target="/xl/media/image1.png"`, `Target="/xl/charts/chart3.xml"`) yazılmasıydı.
- Microsoft Excel OPC/OpenXML ilişki ayrıştırıcısı, bir ilişki dosyasının içinde `Target="/xl/..."` gördüğünde bunu geçersiz/kırık ilişki kabul etmekte ve ilgili tüm çizim dosyalarını (`drawing1.xml`...`drawing16.xml`) ile chart barındıran `drawing5.xml` dosyasını bozularak kaldırılmış ilan etmekteydi.
- İlişki hedefleri `fix_xlsx_rels` fonksiyonu ile `Target="../drawings/drawing1.xml"`, `Target="../media/image1.png"`, `Target="../charts/chart3.xml"` şeklinde standart göreceli yollara dönüştürüldüğünde Excel'in tüm çizim dosyalarını tam ve hatasız tanıdığı empirik olarak kanıtlanmıştır (0 kırık target, 0 yetim drawing).

---

## 2. Yapılan Düzeltmeler

### A) İlişki Yolu Normalizasyonu (`fix_xlsx_rels`)
- `tools/build_hybrid_templates.py`, `tools/generate_excel.py` ve `backend/app/services/excel_engine.py` dosyalarına `fix_xlsx_rels` fonksiyonu eklendi.
- Master şablonlar üretilirken ve her rapor `.xlsx` olarak kaydedildikten hemen sonra `.rels` paketleri otomatik temizlenir ve tüm `Target` ifadeleri geçerli bağıntılı konuma (`../drawings/`, `../media/`, `../charts/`) çevrilir.

### B) KAPAK Fotoğraf Yerleşimi (Çakışma Önleme)
- Sol personel bloğu (`A52:D58`) ve sağ `ONAYLAYAN` bloğu (`G52:M58`) satır 52'de başlamaktadır.
- Fotoğraf ve etiket boyutları personel kutularının kesinlikle üstünde (satır 31-50 arasında) kalacak şekilde yeniden düzenlendi:
  - **Slot 1 (Bakım Öncesi)**: Anchor `A31`, boyut `210x135` px. Etiket hücresi: `A41` ("Bakım Öncesi", Kalın/Ortalı).
  - **Slot 2 (Bakım Sonrası)**: Anchor `G31`, boyut `210x135` px. Etiket hücresi: `G41` ("Bakım Sonrası", Kalın/Ortalı).
  - **Slot 3 (Trafo Etiket / Plaka)**: Anchor `A43`, boyut `210x100` px. Etiket hücresi: `A50` ("Trafo Etiket / Plaka", Kalın/Ortalı).
  - **Satır 51**: Boş koruma aralığı. Satır 52+ personel bloğu ve ONAYLAYAN kutuları ile hiçbir görsel çakışması veya taşma kalmadı.

### C) Grafikler (Nokta / Marker-Only)
- `customize_charts_marker_only` fonksiyonunda ScatterChart & LineChart serileri için:
  - `chart.scatterStyle = "lineMarker"`
  - `series.graphicalProperties.line.noFill = True`
  - `series.smooth = False`
  - `series.marker = Marker(symbol="circle", size=6)`
  ayarları uygulanarak birleştirici çizgiler kaldırıldı, yalnızca nokta (marker) gösterimi sağlandı.

---

## 3. Doğrulama ve Kabul Testleri
1. `python tools/build_hybrid_templates.py` ile tüm master hibrit şablonlar sıfırdan ve temiz `.rels` yapısıyla üretildi.
2. `python tools/verify_drawing_fix.py` ile `hermetik`, `gt` ve `kuru_tip` rapor üretimleri ve ZIP/XML ilişki kontrolleri yapıldı (0 kırık hedef, 0 yetim drawing, 0 5070 metni, ONAYLAYAN bloğu temiz).
3. `mobile/` klasöründe `flutter analyze` 0 error ile doğrulandı.
