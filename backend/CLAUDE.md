# Backend Ajanı — Kurallar (backend/)

Bu dosya SADECE `backend/` içinde çalışırken yüklenir. Önce kök `../CLAUDE.md`'i
okumuş ve mutlak kurallara uyduğunu varsay — burada onları tekrar etmiyoruz, sadece
backend'e özel olanları listeliyoruz.

## Senin sorumluluk alanın

- `backend/**` — FastAPI uygulaması, veritabanı, Excel üretim motoru
- `docs/API_CONTRACT.md`, `docs/DB_SCHEMA.md`, `docs/EXCEL_CELL_MAPPING.md` — bu üçünü
  SEN yazarsın, mobile ajanı sadece okur
- `docs/TASKS_BACKEND.md` — kendi görev listen

## Asla yapma

- `mobile/**` içine yazma (okuman bile gerekmez, sınırın bu)
- `backend/templates/*.xlsx` dosyalarını elle veya kodla değiştirme — kanonik, değiştirilemez
  kaynaklardır; sadece okunur, üzerine asla yazılmaz
- Sayfaları sıfırdan yeniden oluşturma
- Yazı tipi, boyut, renk, kenarlık, sütun genişliği, satır yüksekliği değiştirme
- Hücre birleştirmelerini çözme/yeniden birleştirme
- Sayfa ayarını / yazdırma alanlarını değiştirme
- Mevcut formülleri silme (sadece değer hücrelerinin üzerine yaz)
- Eşlemede (mapping) listelenmeyen herhangi bir hücreye dokunma
- Fotoğraflar için yeni çalışma sayfası ekleme — yer tutucu yoksa mevcut boş
  hücreye/kapak alanına yerleştir, düzeni değiştirme

## Excel üretim motoru — değişmez kurallar (PRD §12.3 özeti, tam metin PRD'de)

1. Doğru şablonu şablon deposundan yükle (tipe göre: HERMETİK / KURU TİP / GT)
2. openpyxl ile aç (stiller, birleştirilmiş hücreler, çizimler korunur)
3. Yalnızca bilinen hücre adreslerine yaz — şablon başına bir mapping sözlüğü
   (`docs/EXCEL_CELL_MAPPING.md`)
4. Tarihleri Excel seri numarası olarak yaz (epoch: 1899-12-30)
5. Sayısal ölçümleri sayı olarak yaz (metin değil), Excel hesaplayabilsin
6. Yeni workbook olarak kaydet — orijinal şablonu asla değiştirme
7. Dosya adı: `{Müşteri Adı} - {Trafo Etiketi} - {GG.AA.YYYY}.xlsx`
   (geçersiz dosya adı karakterlerini temizle)

## API kontrat disiplini

`docs/API_CONTRACT.md` senin çıktın; mobile ajanı buna göre kod yazıyor.

- Yeni endpoint/alan eklemeden/değiştirmeden ÖNCE dosyayı güncelle
- Var olan bir response şeklini değiştiriyorsan → `docs/DECISIONS.md`'e tarihli not
  düş + PR açıklamasında mobile geliştiriciye açık şekilde etiket koy
  (`DİKKAT mobile: /reports/{id} response şekli değişti — bkz DECISIONS.md #tarih`)
- Mobile'ın zaten üzerine kod yazdığı bir kontratı sessizce kırma

## Öncelik sırası (PRD §22 yol haritasından, backend payı)

Detaylı checklist: `docs/TASKS_BACKEND.md`. Genel sıra:

1. FastAPI iskeleti + JWT auth + kayıt kodu sistemi + kullanıcı CRUD
2. `data_json` tabanlı rapor/taslak modeli + Rapor Havuzu endpointleri
3. 3 şablon için hücre eşlemesi + openpyxl üretim motoru + fotoğraf ekleme
4. Şablon yükleme (admin), istatistikler, hata yönetimi senaryoları (PRD §19)
5. Uçtan uca test desteği, API sözleşmesinin son hali

## Hafıza

Her oturum sonunda `backend/MEMORY.md`'e kısa not düş: ne yapıldı, hangi şablon/hücre
kararı alındı, hangi sorun/gotcha bulundu. Bu dosya git'e commit edilir, silinmez.
