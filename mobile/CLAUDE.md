# Mobile Ajanı — Kurallar (mobile/)

Bu dosya SADECE `mobile/` içinde çalışırken yüklenir. Önce kök `../CLAUDE.md`'i
okumuş ve mutlak kurallara uyduğunu varsay — burada onları tekrar etmiyoruz, sadece
mobile'a özel olanları listeliyoruz.

## Senin sorumluluk alanın

- `mobile/**` — Flutter uygulaması (formlar, navigasyon, kamera, imza, taslak,
  offline banner, admin ekranları)
- `docs/TASKS_MOBILE.md` — kendi görev listen
- `docs/API_CONTRACT.md`, `docs/DB_SCHEMA.md` — SALT OKUNUR. Buraya yazma.

## Asla yapma

- `backend/**` içine yazma
- `docs/API_CONTRACT.md`'i kendi başına değiştirme — ihtiyacın olan bir endpoint/alan
  yoksa `docs/DECISIONS.md`'e `İSTEK: backend'den X endpoint'i / Y alanı gerekiyor`
  diye not düş, backend ajanının/geliştiricisinin onu eklemesini bekle
- Dokümante edilmemiş bir endpoint/alan varsaymak — kontratta yoksa geçici, AÇIKÇA
  işaretlenmiş bir mock kullan ve `docs/TASKS_MOBILE.md`'de
  `BLOKE: backend bekleniyor` diye işaretle

## Dinamik form mantığı — kritik kurallar (PRD §2.4, §7.2)

- Trafo yapım tipi seçimi (Hermetik / Kuru Tip / Genleşme Tanklı) hangi alanların
  gösterileceğini belirler — uygulanamayan alanları TAMAMEN gizle, sadece disable etme
- Kuru Tip için asla yağ soruları gösterme; Hermetik/GT dışı tiplerde ilgisiz
  alanları gösterme (tam liste PRD §7.2)
- Her ölçüm için anlık UYGUN/UYGUN DEĞİL görsel geri bildirimi (yeşil/kırmızı) —
  sınır değerler PRD §2.5'te
- Kaydedilmemiş değişiklik varken formdan çıkmaya çalışınca onay dialogu göster

## Taslak / otomatik kayıt (PRD §8)

- Her önemli alan değişikliğinden 2-3 sn sonra ve adım geçişinde otomatik kaydet
- Yeniden açılışta: seçilen tip + fotoğraflar + mevcut adım dahil TAM durum
  geri yüklenmeli
- Taslaklar kesinleşene kadar sadece oluşturan kullanıcıya özel

## Üretim sonrası akış (PRD §21.4)

Excel üretildikten sonra kullanıcıya sun: **Excel'i Aç | Paylaş | Yazdır | Kapat**
(mümkün olduğunca native Android intent'leri kullan).

## Öncelik sırası (PRD §22 yol haritasından, mobile payı)

Detaylı checklist: `docs/TASKS_MOBILE.md`. Genel sıra:

1. Flutter proje iskeleti + JWT güvenli saklama + giriş/kayıt ekranları
2. Dinamik form motoru + taslak sistemi + Rapor Havuzu UI
3. Kamera/fotoğraf akışı + imza pad + üretim-sonrası ekran
4. Admin ekranları (şablon yükleme, istatistik, kullanıcı yönetimi)
5. Uçtan uca test (gerçek tablette), APK imzalama

## Hafıza

Her oturum sonunda `mobile/MEMORY.md`'e kısa not düş. Bu dosya git'e commit edilir,
silinmez.
