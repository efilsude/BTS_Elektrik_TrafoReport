# Mobile Görev Listesi

> Bu dosyayı SADECE mobile ajanı/geliştiricisi işaretler ve düzenler. Backend ajanı
> ilerlemeyi görmek için okuyabilir. Her oturum sonunda ilgili kutucukları güncelle
> ve `mobile/MEMORY.md`'e kısa not düş.

## Faz 1 — Temel (PRD §22)
- [ ] Flutter proje iskeleti (Material Design 3, TR dil)
- [ ] JWT güvenli saklama (flutter secure storage)
- [ ] Başlangıç ekranı: Çalışan Girişi | Kayıt Ol | Admin Girişi (PRD §6)
- [ ] Giriş / Kayıt Ol ekranları (`docs/API_CONTRACT.md`'deki `/auth/*`'a bağlan)
- [ ] Ana Sayfa navigasyonu (Yeni Rapor | Rapor Havuzu | Taslaklar | Profil | Admin)

## Faz 2 — Rapor Çekirdeği (PRD §22)
- [ ] Yeni Rapor akışı: tip seçimi (Bakım/Test → Normal/Kesici → Hermetik/Kuru/GT)
- [ ] QR/Barcode tarama ile etiket verisi otomatik doldurma (PRD §21.2, Kabul #10)
- [ ] Dinamik form motoru: PRD §2.4 karar ağacına göre alan gizleme/gösterme
- [ ] Anlık UYGUN/UYGUN DEĞİL geri bildirimi (PRD §2.5 sınır değerlerine göre)
- [ ] Taslak sistemi: otomatik kayıt (2-3 sn gecikmeli + adım geçişinde), tam
      durum geri yükleme (PRD §8)
- [ ] Rapor Havuzu UI: liste, arama, filtre (PRD §9)

## Faz 3 — Fotoğraf, İmza, Üretim
- [ ] Kamera + galeri entegrasyonu (Öncesi/Sonrası/Etiket, PRD §10)
- [ ] İmza pad — tek seferlik kayıt + profil sayfasından güncelleme (PRD §11)
- [ ] Kesinleştirme akışı → `POST /reports/{id}/finalize` → indirme
- [ ] Üretim sonrası ekran: Excel'i Aç | Paylaş | Yazdır | Kapat (PRD §21.4)
- [ ] Formdan kaydedilmemiş değişiklikle çıkışta onay dialogu (PRD §20)

## Faz 4 — Admin ve Cilalama
- [ ] Admin Gösterge Paneli: Kullanıcılar, Kodlar, Şablonlar, İstatistikler
- [ ] Şablon yükleme UI, kod oluşturucu UI, kullanıcı yönetimi UI
- [ ] Profil/Ayarlar: şifre değiştir + imza güncelle
- [ ] Hata durumları için TR kullanıcı mesajları (PRD §19 ile eşleşecek)

## Faz 5 — Test ve Sürüm
- [ ] Gerçek şirket tabletinde uçtan uca test
- [ ] Release APK imzalama (Play Store yok, AAB gerekmiyor)
- [ ] Kabul kriterleri kontrolü (PRD §24 — mobile'ı ilgilendiren maddeler)

## Sürekli (her fazda geçerli)
- [ ] `docs/API_CONTRACT.md`'i sadece oku; eksik/uyumsuz bulursan
      `docs/DECISIONS.md`'e istek düş
- [ ] `mobile/MEMORY.md`'i güncel tut
