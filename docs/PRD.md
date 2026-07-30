# ÜRÜN GEREKSİNİM DOKÜMANI — TrafoReport

**Trafo Bakım ve Test Saha Raporlama Sistemi — Kurumsal Dahili Android Uygulaması**

- Sürüm: 1.1
- Tarih: 2026-07-26
- Durum: Uygulamaya Hazır
- Hedef Kitle: Geliştirme Ekibi / Yapay Zeka Kod Asistanları
- Şirket: B.T.S. Elektrik Trafo Bakım

> Bu doküman bu proje için **tek doğruluk kaynağıdır**. Repo içindeki hiçbir ajan
> bu dosyayı değiştirmez. Çelişki/belirsizlik durumunda `docs/DECISIONS.md`'e not
> düşülür.

---

## 1. Proje Genel Bakış ve Amaçlar

### 1.1 Problem Tanımı

Saha teknisyenleri şu anda trafo bakımı ve testlerini gerçekleştirmekte, ölçümleri
kağıda kaydetmekte, ardından ofise döndüklerinde verileri karmaşık çok sayfalı Excel
rapor şablonlarına manuel olarak aktarmaktadır. Bu süreç zaman alıcı, hataya açık ve
önemli ölçüde tekrarlayan iş yaratmaktadır.

### 1.2 Çözüm

TrafoReport, teknisyenlerin tüm rapor veri girişini sahada tamamlamasına olanak
tanıyan tek şirketlik dahili bir Android tablet uygulamasıdır. Tamamlandığında sistem,
girilen değerlerle mevcut Excel şablonlarını otomatik olarak doldurur ve orijinal
şablonlarla düzen, biçimlendirme, yazı tipleri, kenarlıklar ve yapı bakımından birebir
aynı, imzaya hazır bir .xlsx dosyası üretir.

### 1.3 Başarı Metrikleri

- Saha sonrası manuel Excel veri girişinin ortadan kaldırılması
- Rapor hazırlama süresinin ≥%70 azaltılması
- Üretilen ve orijinal şablonlar arasında sıfır düzen/biçimlendirme farkı
- İlk günden itibaren mevcut üç rapor ailesinin desteklenmesi
- Tek şirket tableti üzerinde tek APK dağıtımı

### 1.4 Kapsam Dışı (v1)

- Google Play Store dağıtımı / çok kiracılı SaaS
- iOS sürümü
- Gerçek zamanlı iş birliği / bir raporun birden fazla kullanıcı tarafından eşzamanlı düzenlenmesi
- Şablonlarda halihazırda bulunan basit formüllerin ötesinde karmaşık türetilmiş değerlerin otomatik hesaplanması
- Tam dinamik şablon motoru (gelecek)

---

## 2. Excel Şablon Analizi (Kritik Temel)

Üç Excel çalışma kitabı sağlanmış ve eksiksiz analiz edilmiştir. Bunlar kanonik
şablonlardır. Uygulama bunları değiştirilemez düzen kaynakları olarak ele almalı ve
yalnızca belirlenen hücrelere değer yazmalıdır.

### 2.1 Şablon Envanteri

| Dosya | Birincil Kullanım | Temel Ayırt Edici Özellik |
|---|---|---|
| HERMETİK TRAFO BAKIM RAPORU HİLMİ.xlsx | Hermetik (sızdırmaz) yağlı trafo | Hermetik tip, yağ numunesi yok, basınç/gaz kontrolleri, HERMETİK YAĞ DİLEKÇESİ sayfası |
| KURU TİP HİLMİ.xlsx | Kuru tip trafo | Kuru Tip seçili, Fan ON/OFF, Epoksi, Termistor, yağla ilgili alan yok |
| TR BAKIM RAPORU GT HİLMİ.xlsx | Genleşme tanklı / konvansiyonel yağlı trafo + yağ analizi | Genleşme Tanklı, Buchholz, Silika-Jel, Yağ Numunesi, tam YAĞ RAPORU sayfası |

### 2.2 Ortak Sayfa Yapısı

| Sayfa Adı | Amaç | Kullanıcı Verisi Yoğunluğu |
|---|---|---|
| KAPAK SAYFASI | Kapak sayfası, özet bulgular, sonuç, onay bloğu | Yüksek (müşteri, tarihler, özet metin, sonuç) |
| ANA SAYFA | Trafo etiket verileri + görsel/kontrol kontrol listesi + özet ölçümler | Çok Yüksek |
| OG SARGI MEVCUT KADEME | Primer (YG) sargı direnci test sonuçları | Yüksek (ölçülen R, nominal, hata %) |
| AG SARGI | Sekonder (AG) sargı direnci test sonuçları | Yüksek |
| İZOLASYON | DC izolasyon direnci + DAR + sıcaklık düzeltmesi | Yüksek |
| Ç.O 34500 (ve varyantları) | Belirli kademelerde çevirme oranı (TTR) testi | Yüksek (faz başına birden fazla oran) |
| TOPRAKLAMALAR | Toprak direnci ölçümleri | Orta |
| HV PF / LV PF | Güç faktörü / kayıp faktörü testleri | Yüksek (bazı akışlarda isteğe bağlı) |
| ANA SAYFA KESİCİ | Kesici özet sayfası | Kesici bakımı seçildiğinde Yüksek |
| KESİCİ İZOLASYON | Kesici izolasyon direnci | Orta |
| KESİCİ KONTAK | Kesici kontak direnci (µΩ) | Orta |
| AÇMA-KAPAMA | Kesici açma/kapama süreleri ve faz uyuşmazlığı | Yüksek |
| DİĞER | Hücre izolasyonu, mesnet izolatörü, XLPE kablo izolasyonu | Orta |
| AKIM TRAFOLARI | Akım trafosu izolasyonu | Orta |
| HERMETİK YAĞ DİLEKÇESİ / YAĞ RAPORU | Yağ numunesi muafiyet dilekçesi veya tam yağ analizi | Tipe göre Düşük–Yüksek |

### 2.3 Sabit ve Düzenlenebilir İçerik

**Sabit (asla üzerine yazılmamalı):**

- Şirket başlığı (B.T.S. ELEKTRİK TRAFO BAKIM, adres, telefonlar, web sitesi)
- Sayfa başlıkları, bölüm etiketleri, sütun başlıkları, birimler (Ω, GΩ, °C, kV, ms, µΩ…)
- Tüm kenarlıklar, birleştirilmiş hücreler, sütun genişlikleri, satır yükseklikleri, yazı tipleri, renkler
- Onay bloğu etiketleri (Unvan, Sicil No, Ekipnet No, ONAYLAYAN)
- Elektronik imza ile ilgili yasal dipnot metni (5070 sayılı…)
- Referans metni (International Electrical Testing Association)
- Notlar ve değerlendirme kriterleri metinleri (DAR/PE yorum paragrafları)
- Sıcaklık düzeltme faktörü tabloları
- Sabit olan sınır değerler (ör. SINIR DEĞER 0.05, 0.5, Max 2 Ω)

**Kullanıcı tarafından düzenlenebilir / sistem tarafından doldurulan:**

- Müşteri adı (Müşterinin Adı / ŞALT SAHASI)
- Trafo etiketi / lokasyon (TRAFO 1, adres)
- Rapor tarihi, Test tarihi (şu anda Excel seri tarihleri kullanılıyor – doğru dönüştürülmeli)
- Trafo etiket bilgileri: Marka, Güç (kVA), Gerilim, Seri No, İmal Yılı, Bağlantı Grubu,
  Kısa Devre Emp.%, Yağ Markası/Ağırlığı, Kademe Bilgisi, Kazan Tipi
- Tüm ölçüm değerleri (direnç, izolasyon, TTR oranları, toprak, PF, kontak direnci, açma/kapama süreleri)
- Geçti/Kaldı / UYGUN / UYGUN DEĞİL seçimleri ve sonuç çıkan sonuç cümleleri
- Kontrol listesi sonuçları (Evet/Hayır veya UYGUN + onay kutusu benzeri işaretler)
- Operatör adı, cihaz modeli ve S/N
- Fotoğraflar (öncesi/sonrası/etiket) – varsa belirlenen görsel yer tutucularına eklenir;
  yer tutucu yoksa yeni çalışma sayfası eklemeden ve düzeni değiştirmeden mevcut
  kapak/sayfa hücrelerine eklenir
- KAPAK SAYFASI üzerindeki özet sonuç metni

### 2.4 Rapor Tipi Karar Ağacı (Dinamik Form Mantığı)

Form, gereksiz soruları önlemek için seçimlere göre uyarlanmalıdır.

**Seviye 1 – Birincil Kategori:** Bakım VEYA Yalnızca Test

**Seviye 2 – Bakım ise:** Normal Trafo Bakımı VEYA Kesici Bakımı

**Seviye 3 – Trafo Yapım Tipi** (hangi şablon + hangi alanların kullanılacağını belirler):

- Hermetik (sızdırmaz) → HERMETİK şablonu, yağ numunesini gizle, basınç/gaz göster,
  gerekirse muafiyet dilekçesi üret
- Kuru Tip → KURU TİP şablonu, Fan ON/OFF, Epoksi, Termistor göster; tüm yağ alanlarını gizle
- Genleşme Tanklı / Konvansiyonel → GT şablonu, Buchholz, Silika-Jel, Yağ Seviyesi,
  Yağ Numunesi, tam yağ analizi sayfası göster

**Seviye 4 – İsteğe bağlı modüller** (açılıp kapatılabilir veya otomatik dahil edilebilir):

- Güç Faktörü (HV PF / LV PF) testleri
- Tam Kesici test paketi (trafo bakımı sırasında bile)
- Akım Trafoları izolasyonu
- Hücre / Kablo / Mesnet izolatörü izolasyonu (DİĞER)

### 2.5 Temel Hesaplanan / Türetilmiş Değerler

Birçok sayfa zaten formüller veya önceden hesaplanmış hata yüzdeleri içerir. Motor
tercihen ham ölçülen değerleri yazmalı ve Excel formüllerinin mevcut olduğu yerlerde
yeniden hesaplamasına izin vermelidir. Şablonların yalnızca statik sayılar depoladığı
(formül olmadığı) durumlarda uygulama, görüntülenen nihai değerleri hesaplayıp
yazmalıdır (ör. % hata = |R_ölç − R_nom| / R_nom × 100, DAR = R60/R30, sıcaklık
düzeltilmiş izolasyon).

Gözlemlenen kritik sınırlar:

- Sargı direnci faz dengesizliği sınırı: %5 (0.05)
- TTR hata sınırı: ±%0,5
- Toprak direnci maksimum: genellikle 2 Ω
- Kontak direnci maksimum: 150 µΩ
- Kesici açma süresi < 80 ms, kapama süresi < 120 ms, faz uyuşmazlığı < 5 ms
- İşletmedeki trafolar için PF(20°C) ≤ 1

### 2.6 Tarih İşleme

Şablonlar şu anda tarihleri Excel seri numaraları olarak saklamaktadır (ör. 45307,
45310, 45354, 45717). Üretim motoru Python/Dart DateTime → Excel serisini doğru
şekilde dönüştürmeli (Excel epoch 1899-12-30) ve mevcut hücre biçimlendirmesinin
doğru tarihi görüntülemesi için sayısal değeri yazmalıdır.

---

## 3. Sistem Kapsamı ve Kısıtlar

- Tek şirket, tek Android tablet (şirkete ait)
- Teslimat: Yalnızca Release APK (Play Store yok, AAB zorunluluğu yok)
- Öncelikli olarak çevrimiçi; çevrimdışı destek gelecek faz için önerilir
- Üretilen tüm Excel dosyaları yüklenen şablonlarla düzen bakımından ikili olarak aynı olmalıdır
- Türkçe dil arayüzü ve rapor içeriği
- Çok şirketli / white-label özellikler yok

---

## 4. Kullanıcı Rolleri ve Yetkiler

### 4.1 Admin

Şirket sahibi veya yetkili yönetici. Yetkiler:

- Tek kullanımlık kayıt davet kodları oluşturma (15 dk TTL)
- Kullanıcı yönetimi (listeleme, arama, devre dışı bırakma/silme). Kullanıcı silme,
  geçmiş rapor sahipliğini değiştirmez; orijinal oluşturan adı tüm geçmiş raporlarda
  görünür kalır.
- Havuzdaki herhangi bir raporu görüntüleme / düzenleme / indirme
- Excel şablonlarını yükleme / değiştirme
- Temel istatistikleri görüntüleme (oluşturulan raporlar, kullanıcıya göre, tipe göre)
- Rapor Havuzuna tam erişim

### 4.2 Çalışan (Teknisyen)

Saha teknisyeni. Yetkiler:

- Davet kodu ile kayıt olma + şifre oluşturma
- Giriş / çıkış
- Yeni rapor oluşturma (Bakım veya Test)
- Taslakları kaydetme ve devam etme
- Paylaşılan Rapor Havuzuna göz atma (tüm şirket raporları)
- Önceki raporları açma (görüntüleme + Excel indirme)
- Kendi taslaklarını düzenleme; başkalarının kesinleşmiş raporlarının üzerine yazamaz (Admin yazabilir)
- Gerekli fotoğrafları çekme ve ekleme

---

## 5. Kayıt ve Kimlik Doğrulama

### 5.1 Kayıt Akışı

1. Admin, Admin Panelinde tek kullanımlık bir kayıt kodu oluşturur
2. Kod tam olarak 15 dakika geçerlidir ve tek kullanımlıktır
3. Çalışan Kayıt ekranını açar, girer: Ad Soyad, E-posta (isteğe bağlı), Telefon, Sicil No (isteğe bağlı)
4. Çalışan davet kodunu girer
5. Sistem kodu doğrular (mevcut, süresi dolmamış, kullanılmamış)
6. Çalışan şifre belirler (min. 8 karakter, karmaşıklık önerilir)
7. Hesap oluşturulur; kod hemen kullanılmış/silinmiş olarak işaretlenir
8. Çalışan artık giriş yapabilir

### 5.2 Giriş

Başlangıç ekranı üç giriş noktası sunar: Çalışan Girişi | Kayıt Ol | Admin Girişi

Kimlik doğrulama: JWT (access + refresh token önerilir). Token'ları güvenli şekilde
saklayın (Flutter secure storage).

Admin girişi ayrı bir kimlik bilgisi seti kullanır (veya aynı kullanıcı tablosunda
yükseltilmiş bayrak).

### 5.3 Şifre Kuralları

- Minimum 8 karakter
- En az bir harf ve bir rakam önerilir
- Şifre güçlü hash ile saklanır (bcrypt / argon2)

Kullanıcı sayfası (Profil / Ayarlar) bir Şifre Değiştir işlevi sunmalıdır. Kullanıcılar
mevcut şifre + yeni şifre (onay ile) girer. İmza güncelleme de aynı sayfada mevcuttur.

---

## 6. Uygulama Navigasyonu ve Ekranlar

Navigasyon basit ve tablete optimize edilmiş olmalıdır (büyük dokunma hedefleri,
minimum iç içe geçme).

Yeni Rapor akışı, tip seçiminden hemen sonra trafo seri numarası ve diğer mevcut
etiket verilerini otomatik doldurmak için isteğe bağlı bir QR/Barcode tarama adımı
içerir.

| Ekran | Erişim | Amaç |
|---|---|---|
| Splash / Başlangıç | Tümü | Uygulama logosu + yükleme; oturum geçerliyse Giriş veya Ana Sayfa'ya yönlendirir |
| Giriş | Herkese açık | Çalışan kimlik bilgileri veya Admin kimlik bilgileri |
| Kayıt Ol | Herkese açık | Davet koduna dayalı kayıt |
| Ana Sayfa | Kimlik doğrulanmış | Yeni Rapor \| Rapor Havuzu \| Taslaklar \| Profil \| Admin (admin ise) |
| Yeni Rapor – Tip Seçimi | Çalışan | Bakım vs Test → alt tip → yapım tipi |
| Dinamik Rapor Formu | Çalışan | Seçimlere göre uyarlanan çok adımlı veya sekmeli form |
| Fotoğraf Çekimi | Çalışan | Öncesi / Sonrası / Etiket için kamera + galeri |
| Taslak Listesi | Çalışan | Mevcut kullanıcıya ait tamamlanmamış raporlar |
| Rapor Havuzu | Tüm kimlik doğrulanmış | Tüm şirket raporlarının aranabilir/filtrelenebilir listesi |
| Rapor Detay / Önizleme | Tüm kimlik doğrulanmış | Özet görüntüleme + Excel indirme + (Admin) düzenleme |
| Admin Gösterge Paneli | Admin | Kullanıcılar, Kodlar, Şablonlar, İstatistikler, Rapor Havuzu |
| Kullanıcı Yönetimi | Admin | Kullanıcıları listeleme / arama / devre dışı bırakma / silme |
| Kod Oluşturucu | Admin | Davet kodları oluşturma + geçmiş |
| Şablon Yönetimi | Admin | .xlsx şablonlarını yükleme/değiştirme |
| Profil / Ayarlar | Kimlik doğrulanmış | Şifre değiştirme, kayıtlı imzayı güncelleme, kendi bilgilerini görüntüleme, çıkış |

---

## 7. Rapor İş Akışı ve Dinamik Formlar

### 7.1 Üst Düzey Akış

1. Kullanıcı Yeni Rapor'a dokunur
2. İsteğe bağlı: Trafo etiketindeki QR/Barcode tarama → sistem okur ve mevcut etiket
   verilerini (seri numarası ve kodlanmış diğer alanlar) otomatik doldurur.
3. Birincil tipi seçer: Bakım veya Test
4. Bakım ise → Normal Trafo veya Kesici
5. Yapım tipini seçer (Hermetik / Kuru Tip / Genleşme Tanklı) – bu hedef Excel şablonunu kilitler
6. Müşteri ve lokasyon verilerini girer (sayfalar arasında paylaşılır)
7. Etiket verilerini doldurur (Marka, Güç, Gerilim, Seri No vb.)
8. Görsel ve kontrol listesi kontrollerini tamamlar (yalnızca ilgili olanlar gösterilir)
9. Ölçüm bölümlerini girer (sargı R, izolasyon, TTR, topraklama, PF, Kesici…)
10. Sistem sınırlara göre UYGUN / UYGUN DEĞİL değerlendirmesini otomatik yapar ve
    sonuç metni önerir
11. Gerekli fotoğrafları çeker
12. KAPAK eşdeğeri ekranda özeti gözden geçirir
13. Taslak olarak kaydeder veya Kesinleştirir → standart dosya adıyla Excel üretir
    (`{Müşteri} - {Trafo Etiketi} - {GG.AA.YYYY}.xlsx`) → Rapor Havuzuna kaydeder →
    üretim sonrası eylemleri sunar

### 7.2 Dinamik Form Kuralları (Uygulanması Zorunlu)

Uygulanabilir olmadığında tamamen gizle:

- Yağ seviyesi, yağ kaçağı, Buchholz, Silika-Jel, Yağ Numunesi, Yağ İlavesi → yalnızca
  Genleşme Tanklı için
- Basınç açma, Gaz açma → Hermetik
- Fan ON/OFF, Epoksi, Termistor → yalnızca Kuru Tip
- Tam Kesici paketi → yalnızca Kesici Bakımı seçildiğinde veya açıkça eklendiğinde
- Güç Faktörü bölümleri → isteğe bağlı geçiş veya ölçümler girildiğinde otomatik
- Hermetik Yağ Dilekçesi sayfası üretimi → yalnızca Hermetik için, yağ numunesi
  istendiğinde ancak alınamadığında

### 7.3 Otomatik Değerlendirme Mantığı

Her ölçülen değer için form, şablonlarda gözlemlenen sınırlara dayalı anında
geçti/kaldı göstergesi göstermelidir. KAPAK SAYFASI üzerindeki nihai sonuç cümleleri
bu sonuçlardan üretilir (şablonlarda halihazırda bulunan dil ile eşleşecek şekilde).

---

## 8. Taslak Sistemi

- Her önemli alan değişikliğinden sonra otomatik kaydet (2–3 sn gecikmeli) ve kullanıcı
  formun başka bir sayfasına/adımına her geçtiğinde otomatik olarak
- Taslaklar kesinleşene kadar oluşturan çalışana özeldir
- Yeniden açıldığında, seçilen tip, fotoğraflar ve mevcut adım dahil tam form durumunu geri yükle
- Kullanıcı kendi taslaklarını silebilir
- 30 günden eski taslaklar otomatik arşivlenebilir (yapılandırılabilir)

---

## 9. Rapor Havuzu ve Düzenleme

Paylaşılan şirket kütüphanesi. Görüntülenen sütunlar:

- Rapor Adı (otomatik üretilir: Müşteri – Trafo Etiketi – Tarih)
- Rapor Tipi (Hermetik Bakım / Kuru Tip Bakım / GT Bakım / Kesici / Test)
- Oluşturan
- Oluşturma Tarihi / Son Değiştirme
- Durum (Taslak / Kesin)
- Eylemler: Görüntüle, Excel İndir, (Admin) Düzenle

Gelişmiş Arama alanları: Müşteri Adı, Trafo Seri Numarası, Trafo Gücü (kVA), Rapor
Oluşturan, Tarih. Filtreler: Bakım Tipi (Normal / Kesici), Bakım vs Test, Trafo Tipi
(Hermetik / Kuru Tip / Genleşme Tanklı), Tarih Aralığı. Sonuçlar birleşik arama +
filtreyi destekler.

Admin düzenleme: aynı formu önceden doldurulmuş olarak açar; kaydetme önceki
sürümün üzerine yazar (v1'de sürüm geçmişi gerekmez).

---

## 10. Fotoğraf Çekimi ve Ekleme

Gerekli fotoğraflar:

| Rapor Türü | Öncesi | Sonrası | Etiket |
|---|---|---|---|
| Bakım (herhangi bir tip) | Zorunlu | Zorunlu | Zorunlu |
| Yalnızca Test | — | — | Zorunlu |

Fotoğraflar dosya olarak (veya tek tablet için basitlik adına DB'de base64) saklanır
ve Excel üretiminde KAPAK SAYFASI üzerindeki doğru görsel yer tutucularına / hücrelere
veya şablon destekliyorsa özel bir fotoğraf alanına eklenir.

**KRİTİK KURAL:** Orijinal şablon önceden tanımlanmış bir görsel yer tutucu içermiyorsa,
fotoğraflar yine de mevcut şablon yapısına (örneğin kullanılabilir boş hücrelere veya
kapak sayfası alanına) yeni bir çalışma sayfası oluşturmadan ve orijinal düzeni,
kenarlıkları, birleştirilmiş hücreleri veya sayfa yapısını değiştirmeden eklenmelidir.
Yalnızca fotoğraflar için asla yeni bir sayfa eklemeyin.

Kamera entegrasyonu endüstriyel tabletlerde iyi çalışmalıdır; yedek olarak galeriden
seçime izin verin.

---

## 11. Dijital İmza

Dijital imza, raporu hazırlayan teknisyene (çalışana) aittir.

**İmza Kaydı (tek seferlik kurulum):**

- İlk hesap kurulumu sırasında (veya kayıttan sonraki ilk girişte) her kullanıcı
  Signature Pad widget'ı ile el yazısı imzasını bir kez yakalar ve kaydeder. İmza,
  kullanıcı profiline karşı saklanır.
- Kayıtlı imza, o kullanıcının oluşturduğu tüm gelecekteki raporlara otomatik olarak
  eklenir (KAPAK SAYFASI ONAYLAYAN alanı ve ilgili detay sayfaları).
- Kullanıcılar kayıtlı imzalarını herhangi bir zamanda Kullanıcı / Profil sayfasından
  güncelleyebilir.

**Otomatik ekleme:**

- Bir rapor kesinleştirildiğinde sistem, hazırlayan teknisyenin kayıtlı imza
  görselini KAPAK SAYFASI ONAYLAYAN alanına ve imza bloğu içeren diğer ilgili detay
  sayfalarına otomatik olarak gömer.
- İmza şeffaf PNG olarak saklanır. Teknisyen adı, Unvan, Sicil No ve Ekipnet No
  görselin yanında metin olarak yazılır.

Elektronik imza yasası referansı şablonlarda halihazırda mevcuttur (5070 sayılı) ve
dokunulmamalıdır.

---

## 12. Excel Üretim Motoru (En Kritik Bileşen)

Bu ürünün kalbidir. **Üretilen dosya kaynak şablonla düzen bakımından birebir aynı
OLMALIDIR.**

### 12.1 Mimari Öneri

Backend (FastAPI) üretim mantığını sahiplenir:

1. Doğru şablon dosyasını Şablon depolamasından yükle (tipe göre)
2. Stilleri, birleştirilmiş hücreleri, çizimleri koruyan bir kütüphane ile aç
   (openpyxl önerilir; görselleri dikkatli işle)
3. Yalnızca bilinen hücre adreslerine değer yaz (şablon başına bir eşleme sözlüğü tut)
4. Varsa belirlenen yer tutuculara fotoğraf ekle. Yer tutucu yoksa fotoğrafları
   yalnızca mevcut boş hücrelere veya kapak sayfası alanlarına yerleştir — asla yeni
   bir çalışma sayfası oluşturma ve düzeni asla değiştirme.
5. Yeni bir çalışma kitabı kaydet; ana şablonu asla değiştirme
6. Dosya yolunu / akışını indirme için istemciye döndür

Üretilen Excel dosyaları standart bir dosya adı kullanmalıdır:
`"{Müşteri Adı} - {Trafo Etiketi} - {GG.AA.YYYY}.xlsx"`. Örnek:
`"ABC Fabrikası - TR1 - 25.07.2026.xlsx"`. Geçersiz dosya adı karakterlerini temizle.

Başarılı Excel üretiminden sonra istemci kullanıcıya şu eylemleri sunmalıdır:
Excel'i Aç, Paylaş, Yazdır, Kapat.

### 12.2 Hücre Eşleme Stratejisi

Her şablon için her yazılabilir hücre adresini ve karşılık gelen form alan anahtarını
listeleyen bir JSON (veya Python dict) eşlemesi oluşturun. Örnek yapı:

```json
{ "HERMETIK": { "KAPAK SAYFASI": { "C9": "customer_name", "C10": "trafo_label" }, "ANA SAYFA": { } } }
```

Geliştirme sırasında eşleme, gerçek şablonlar incelenerek oluşturulmalıdır (zaten
sağlanmıştır). Eşlemede listelenmeyen hiçbir hücreye dokunulmaz.

### 12.3 Tartışmasız Kurallar

- Sayfaları sıfırdan yeniden oluşturma
- Yazı tiplerini, boyutları, renkleri, kenarlıkları, sütun genişliklerini, satır
  yüksekliklerini değiştirme
- Hücre birleştirmelerini çözme veya yeniden birleştirme
- Sayfa ayarını / yazdırma alanlarını değiştirme
- Mevcut tüm formülleri koru; yalnızca değer hücrelerinin üzerine yaz
- Tarihleri Excel seri numaraları olarak yaz
- Sayısal ölçümleri sayı olarak yaz (metin değil) ki Excel hesaplayabilsin
- Bir şablonda görsel yer tutucu yoksa, fotoğrafları yine de yalnızca orijinal
  sayfaların mevcut hücrelerine/alanlarına ekle; fotoğraflar için asla yeni bir
  çalışma sayfası ekleme

---

## 13. Şablon Yönetimi

Admin yeni bir .xlsx dosyası yükleyebilir ve bir rapor tipine atayabilir
(Hermetik / Kuru / GT / Kesici).

v1 yaklaşımı: her şablon sabit bir dosya + sabit hücre-eşleme sözlüğüdür. Tamamen
yeni bir rapor düzeni eklemek küçük bir geliştirme çabası gerektirir (yeni eşleme).
Bu, ilk sürüm için kabul edilebilirdir.

Gelecek iyileştirme: Admin'in kod değişikliği olmadan hangi form alanının hangi
hücreye yazacağını tanımlamasına olanak tanıyan görsel bir eşleme aracı veya
bildirimsel YAML. Ödünleşim: daha yüksek karmaşıklık vs uzun vadeli esneklik.

---

## 14. Çevrimdışı Değerlendirmeler

Birincil kullanım çevrimiçidir. Ancak endüstriyel sahalarda sıklıkla zayıf bağlantı
vardır.

Öneri: çevrimdışı modu Faz 2'de uygulayın.

Çevrimdışının avantajları:

- Teknisyen metal bir kabin içinde veya uzak OSB'de çalışmaya devam edebilir
- Taslaklar yerel olarak saklanır, çevrimiçi olunca senkronize edilir

Dezavantajlar / Karmaşıklık:

- Aynı rapor iki cihazda düzenlenirse çakışma çözümü (tek tablette olasılık düşük)
- Cihazda fotoğraf depolama
- Excel üretiminin de çevrimdışı çalışması veya senkronizasyona kadar ertelenmesi gerekir

Çevrimdışı ertelenirse, uygulama ağ durumunu net şekilde belirtmeli ve bağlantı
kopmasında veri kaybını önlemelidir (yerel taslak arabelleği).

---

## 15. Güvenlik Gereksinimleri

- Tüm API uç noktaları (giriş/kayıt hariç) geçerli JWT gerektirir
- Yalnızca HTTPS
- Şifreler bcrypt veya argon2 ile hash'lenir
- Kayıt kodları tek kullanımlık + 15 dk süre + oran sınırlı oluşturma
- Silinen / devre dışı bırakılan kullanıcılar erişimi hemen kaybeder (token kara
  listesi veya kısa ömürlü access token'lar)
- Bir kullanıcı silindiğinde, daha önce oluşturulmuş raporlardaki sahiplik bilgisi
  kaldırılmamalı veya anonimleştirilmemelidir. Raporlar orijinal oluşturanın adını
  göstermeye devam eder (oluşturma anında rapor kaydına denormalize creator display
  name olarak sakla).
- Raporlar şirket kapsamlıdır; şirketler arası sızıntı yok (tasarım gereği tek kiracı)
- Dosya indirmeleri kimlik doğrulama gerektirir
- Admin eylemleri günlüğe kaydedilir (isteğe bağlı denetim izi)

---

## 16. Önerilen Teknoloji Yığını

| Katman | Teknoloji | Gerekçe |
|---|---|---|
| Mobil İstemci | Flutter 3.x (Dart) | Mükemmel tablet desteği, tek kod tabanı, kamera, imza, dosya işleme, güvenli depolama için olgun paketler |
| Backend API | FastAPI (Python 3.11+) | Hızlı, tipli, mükemmel Excel ekosistemi (openpyxl), kolay JWT, async hazır |
| Veritabanı | PostgreSQL (tercih) veya SQLite | Çok cihazlı gelecek mümkünse PostgreSQL; gerçek tek tablet + yerel sunucu için SQLite kabul edilebilir. Sağlamlık için PostgreSQL önerilir |
| Kimlik Doğrulama | JWT (access 15–30 dk + refresh) | Durumsuz, standart, kısa süre + kara liste ile iptal edilmesi kolay |
| Excel Motoru | openpyxl (+ görseller için pillow) | Biçimlendirmenin çoğunu korur; iyi belgelenmiş hücre yazma |
| Dosya Depolama | Yerel dosya sistemi (sunucu) + isteğe bağlı sonra S3 | v1 için basit; yol DB'de saklanır |
| Barındırma | Aynı LAN / küçük VPS veya tabletin kendisi yerel sunucu ile | Dahili uygulama; backend küçük her zaman açık bir PC veya tablet üzerinde çalışabilir |

Alternatif: salt cihaz üzeri Flutter + yerel SQLite + cihaz üzeri Excel üretimi (Dart
Excel paketi kullanarak). Daha basit dağıtım (sunucu yok) ancak daha zayıf Admin çok
cihaz erişimi ve daha zor şablon güncellemeleri. Önerilen hibrit: aynı tablet veya
yerel bir PC üzerinde çalışsa bile küçük bir FastAPI backend.

---

## 17. Veritabanı Tasarımı (Üst Düzey)

| Varlık | Anahtar Alanlar |
|---|---|
| users | id, full_name, email, phone, sicil_no, password_hash, role (admin/employee), is_active, created_at |
| registration_codes | id, code, created_by, expires_at, used_at, used_by_user_id |
| templates | id, name, report_type (hermetik/kuru/gt/kesici), file_path, mapping_json, version, uploaded_at |
| reports | id, title, report_type, status (draft/final), created_by, customer_name, trafo_label, test_date, report_date, data_json (tüm form değerleri), excel_path, created_at, updated_at |
| photos | id, report_id, photo_type (before/after/label/signature), file_path, created_at |
| audit_log (isteğe bağlı) | id, user_id, action, entity_type, entity_id, timestamp |

`data_json`, taslaklar ve düzenlemeler için formun mükemmel şekilde yeniden
doldurulabilmesi amacıyla tüm form durumunu tutar.

`reports` tablosu, kullanıcı silindiğinde geçmiş raporların görünür oluşturanını
asla silmemek için denormalize bir `creator_display_name` (oluşturma anında
kopyalanır) saklamalıdır.

---

## 18. REST API Tasarımı

Temel yol: `/api/v1`

| Metod | Uç Nokta | Amaç |
|---|---|---|
| POST | /auth/login | Çalışan veya Admin girişi → JWT |
| POST | /auth/register | Davet kodu ile kayıt |
| POST | /auth/refresh | Access token yenileme |
| GET | /users/me | Mevcut kullanıcı profili |
| GET | /admin/users | Kullanıcıları listele/ara (Admin) |
| DELETE | /admin/users/{id} | Kullanıcıyı devre dışı bırak/sil |
| POST | /admin/codes | Kayıt kodu oluştur |
| GET | /admin/codes | Son kodları listele |
| GET | /templates | Mevcut şablonları listele |
| POST | /admin/templates | Yeni şablon yükle |
| GET | /reports | Rapor havuzu (filtre, arama, sayfalama) |
| POST | /reports | Rapor oluştur (taslak veya kesin) |
| GET | /reports/{id} | Rapor detayı + data_json al |
| PUT | /reports/{id} | Taslağı güncelle veya (Admin) kesin olanı düzenle |
| POST | /reports/{id}/finalize | Excel üret, kesin olarak işaretle |
| GET | /reports/{id}/download | Üretilen .xlsx indir |
| POST | /reports/{id}/photos | Fotoğraf yükle |
| GET | /drafts | Mevcut kullanıcının taslakları |
| DELETE | /reports/{id} | Taslağı sil (sahip) veya herhangi birini (Admin) |

---

## 19. Hata Yönetimi

| Senaryo | Beklenen Davranış |
|---|---|
| Form girişi sırasında ağ kaybı | Yerel taslak arabelleğine otomatik kaydet; çevrimdışı banner göster; çevrimiçi olunca devam et |
| Süresi dolmuş / kullanılmış kayıt kodu | Net hata mesajı: "Kod geçersiz veya süresi dolmuş" |
| Geçersiz giriş | Genel "E-posta/şifre hatalı" (kullanıcı numaralandırma yok) |
| Kesinleştirmede zorunlu alanlar eksik | Alanları vurgula + kesinleştirmeyi engelle |
| Fotoğraf yükleme hatası | Yeniden dene düğmesi + zorunlu değilse fotoğrafsız devam etmeye izin ver |
| Bozuk / eksik şablon | Admin'e yönelik hata; üretme; günlüğe kaydet |
| Excel üretim istisnası | Durumu taslağa geri al; "Rapor oluşturulamadı, teknik destek" göster |
| Token süresi doldu | Sessiz yenileme; yenileme başarısız olursa → yeniden girişe zorla |
| Beklenmeyen sunucu hatası | Kullanıcı dostu Türkçe mesaj + destek için hata kimliği |

---

## 20. UI/UX Yönergeleri

- Material Design 3, varsayılan açık tema, isteğe bağlı koyu mod
- Endüstriyel eldiven kullanımı için büyük dokunma hedefleri (≥48 dp)
- Minimum navigasyon derinliği; tablette alt veya yan navigasyon
- Çok adımlı formlar için ilerleme göstergesi
- Ölçümlerde anında geçti/kaldı görsel geri bildirimi (yeşil/kırmızı)
- Excel terminolojisiyle eşleşen Türkçe etiketler (UYGUN, Kademe, Sargı vb.)
- Klavye tipleri: ölçümler için sayısal, ondalık desteği
- Kullanıcı kaydedilmemiş değişiklikler varken bir rapor formundan çıkmaya çalışırsa
  (geri, ana sayfa veya kapat), ayrılmadan önce bir onay iletişim kutusu göster. Adım
  değişiminde otomatik kaydet riski azaltır, ancak silme mümkün olduğunda açık onay
  yine de gereklidir.
- Hızlı: süslemeden çok hızı tercih et

---

## 21. Kullanıcı Akışları

### 21.1 Kayıt
Admin → Kod Oluşturucu → kod oluştur → sözlü/SMS ile paylaş → Çalışan Kayıt Ol'u
açar → bilgileri + kodu doldurur → şifre belirler → başarı → Giriş

### 21.2 Bakım Raporu Oluşturma
Ana Sayfa → Yeni Rapor → Bakım → Normal → Hermetik/Kuru/GT → müşteri/etiket doldur →
kontrol listeleri → ölçümler → fotoğraflar → gözden geçir → Kesinleştir → Excel
üretilir → Havuzda görünür

### 21.3 Taslağa Devam Etme
Ana Sayfa → Taslaklar → taslak seç → form tam olarak geri yüklenir → devam et →
Kesinleştir veya tekrar Kaydet

### 21.4 Excel İndirme
Rapor Havuzu / Detay → Excel üretimi sonrası (veya İndir'de) kullanıcıya sunulur:
Excel'i Aç | Paylaş | Yazdır | Kapat. Bu eylemler mümkün olduğunda yerel Android
intent'lerini kullanır.

### 21.5 Admin Düzenleme
Admin → Rapor Havuzu → Düzenle → aynı form önceden doldurulmuş → Kaydet (üzerine yazar)

---

## 22. Geliştirme Yol Haritası

| Faz | Süre (tahmini) | Teslimatlar |
|---|---|---|
| 1 – Temel | 2–3 hafta | Flutter projesi, FastAPI iskeleti, JWT kimlik doğrulama, kayıt kodları, kullanıcı CRUD, temel navigasyon |
| 2 – Rapor Çekirdeği | 3–4 hafta | Dinamik form motoru, taslak sistemi, data_json kalıcılığı, Rapor Havuzu UI |
| 3 – Excel Motoru | 3–4 hafta | 3 şablon için hücre eşlemesi, openpyxl üretimi, fotoğraf ekleme, indirme |
| 4 – Admin ve Cilalama | 2 hafta | Şablon yükleme, istatistikler, imza pedi, fotoğraf çekimi UX, hata yönetimi |
| 5 – Test ve Sürüm | 2 hafta | Gerçek tablette uçtan uca testler, APK imzalama, dokümantasyon, eğitim |

Gerçekçi toplam v1: küçük bir ekip (1–2 geliştirici) için 12–15 hafta.

---

## 23. Gelecek İyileştirmeler

- Arka plan senkronizasyonu ile tam çevrimdışı mod
- Bildirimsel şablon eşleme aracı (yeni düzenler için kod değişikliği yok)
- (v1'e taşındı) QR / barcode tarama, trafo seri numarası ve ilgili etiket verilerinin
  otomatik doldurulması için Yeni Rapor akışında uygulanmıştır.
- Taslak hatırlatmaları veya Admin inceleme istekleri için anlık bildirimler
- Raporların bulut yedeklemesi (isteğe bağlı)
- Dijital çok seviyeli onay iş akışı
- Analitik gösterge paneli (aylık raporlar, arıza eğilimleri)
- Excel'e ek olarak PDF dışa aktarma
- Mevcut ERP / müşteri CRM ile entegrasyon

---

## 24. Kabul Kriterleri (Geçmesi Zorunlu)

1. Üretilen Excel, Microsoft Excel / LibreOffice'te orijinal şablondan sıfır düzen farkıyla açılır
2. Üç şablon ailesinin tümü aynı form motorundan doğru raporlar üretir
3. Dinamik form, Kuru Tip için yağ sorularını veya gerekmediğinde Hermetik muafiyet
   dilekçesini asla göstermez
4. Taslak kapatılıp yeniden açıldığında %100 durum geri yüklemesi yapılır
5. Admin kod üretebilir → çalışan kayıt olur → her ikisi de oluşan raporu Havuzda görebilir
6. Gerekli fotoğraflar nihai Excel'de mevcuttur (veya ekleme noktası yoksa net şekilde not edilir)
7. APK, hedef şirket Android tabletinde Play Store olmadan kurulur ve çalışır
8. Yetkisiz kullanıcılar hiçbir rapor verisine erişemez
9. Tarih değerleri üretilen dosyada doğru görüntülenir (seri numaraları değil)
10. Yeni Rapor'da QR/Barcode tarama, geçerli bir kod mevcut olduğunda trafo seri numarasını otomatik doldurur.
11. Standart Excel dosya adı formatı her üretimde uygulanır.
12. Üretim sonrası ekran Excel'i Aç, Paylaş, Yazdır ve Kapat eylemlerini sunar.
13. Kullanıcı silme, tüm geçmiş raporlarda orijinal oluşturan adını bozulmadan bırakır.
14. İmza kullanıcı başına bir kez kaydedilir ve otomatik eklenir; Kullanıcı sayfasından
    güncellenebilir. Şifre Değiştir Kullanıcı sayfasında mevcuttur.
15. Fotoğraflar asla yeni oluşturulan bir çalışma sayfasına yerleştirilmez; orijinal
    şablon yapısı korunur.

— Ürün Gereksinim Dokümanı Sonu —

Bu doküman uygulamaya hazırdır. Yetkin bir geliştirme ekibi veya yapay zeka kod
asistanı, gereksinimler konusunda ek açıklama olmadan kodlamaya başlayabilmelidir.
