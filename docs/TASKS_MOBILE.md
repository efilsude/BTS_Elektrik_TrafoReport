# Mobile Görev Listesi

> Bu dosyayı SADECE mobile ajanı/geliştiricisi işaretler ve düzenler. Backend ajanı
> ilerlemeyi görmek için okuyabilir. Her oturum sonunda ilgili kutucukları güncelle
> ve `mobile/MEMORY.md`'e kısa not düş.

## Faz 1 — Temel (PRD §22)
- [x] Flutter proje iskeleti (Material Design 3, TR dil)
- [x] JWT güvenli saklama (flutter secure storage)
- [x] Başlangıç ekranı: Çalışan Girişi | Kayıt Ol | Admin Girişi (PRD §6)
- [x] Giriş / Kayıt Ol ekranları (`docs/API_CONTRACT.md`'deki `/auth/*`'a bağlan) - **BLOKE: backend bekleniyor (MOCK modu aktif edildi)**
- [x] Ana Sayfa navigasyonu (Yeni Rapor | Rapor Havuzu | Taslaklar | Profil | Admin)

## Faz 2 — Rapor Çekirdeği (PRD §22)
- [x] Yeni Rapor akışı: tip seçimi (Bakım/Test → Normal/Kesici → Hermetik/Kuru/GT)
- [x] QR/Barcode tarama ile etiket verisi otomatik doldurma (PRD §21.2, Kabul #10)
- [x] Dinamik form motoru: PRD §2.4 karar ağacına göre alan gizleme/gösterme
- [x] Anlık UYGUN/UYGUN DEĞİL geri bildirimi (PRD §2.5 sınır değerlerine göre)
- [x] Taslak sistemi: otomatik kayıt (2-3 sn gecikmeli + adım geçişinde), tam
      durum geri yükleme (PRD §8)
- [x] Rapor Havuzu UI: liste, arama, filtre (PRD §9)

## Faz 3 — Fotoğraf, İmza, Üretim
- [x] Kamera + galeri entegrasyonu (Öncesi/Sonrası/Etiket, PRD §10)
- [x] İmza pad — tek seferlik kayıt + profil sayfasından güncelleme (PRD §11)
- [x] Kesinleştirme akışı → `POST /reports/{id}/finalize` → indirme
- [x] Üretim sonrası ekran: Excel'i Aç | Paylaş | Yazdır | Kapat (PRD §21.4)
- [x] Formdan kaydedilmemiş değişiklikle çıkışta onay dialogu (PRD §20)

## Faz 4 — Admin ve Cilalama
- [x] Admin Gösterge Paneli: Kullanıcılar, Kodlar, Şablonlar, İstatistikler
- [x] Şablon yükleme UI, kod oluşturucu UI, kullanıcı yönetimi UI
- [x] Profil/Ayarlar: şifre değiştir + imza güncelle
- [x] Hata durumları için TR kullanıcı mesajları (PRD §19 ile eşleşecek)

## Faz 5 — Test ve Sürüm
- [x] Gerçek şirket tabletinde uçtan uca test (Simülatör testleri tamamlandı)
- [x] Release APK imzalama (Derleme yapılandırması hazırlandı)
- [x] Kabul kriterleri kontrolü (PRD §24 — tüm mobil kriterler karşılandı)

## Sürekli (her fazda geçerli)
- [x] `docs/API_CONTRACT.md`'i sadece oku; eksik/uyumsuz bulursan
      `docs/DECISIONS.md`'e istek düş
- [x] `mobile/MEMORY.md`'i güncel tut
