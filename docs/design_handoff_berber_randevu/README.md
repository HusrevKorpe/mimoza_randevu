# Teslim Paketi: Berber Randevu Defteri (iOS)

## Genel Bakış
Bu, **tek bir berberin kendi kullanımı için** tasarlanmış bir randevu defteri uygulamasıdır. Online/müşteri tarafı rezervasyon **yoktur** — amaç berberin "hangi gün, saat kaçta, kim geliyor" bilgisini tuttuğu dijital bir deftere sahip olması.

İki ana kolaylık tasarıma işlenmiştir:
1. **Ana ekran widget'ı** — telefonun ana ekranındaki widget'a dokununca uygulamanın randevu defteri açılır.
2. **Rehber entegrasyonu** — yeni randevu oluştururken Kişiler/Rehber'den seçilerek isim + telefon otomatik gelir; ayrıca randevu kartında/detayında "Rehbere Kaydet" ikonu ile kişi rehbere yazılır.

Her randevu yalnızca üç bilgi tutar: **isim, telefon, tarih & saat**. Sade kalması bilinçli bir tercihtir.

## Tasarım Dosyaları Hakkında
Bu pakette bulunan `Berber Randevu.dc.html` dosyası **HTML ile oluşturulmuş bir tasarım referansıdır** — istenen görünümü ve davranışı gösteren bir prototiptir, doğrudan production'a kopyalanacak kod değildir. Görev, bu tasarımları **hedef kod tabanının kendi ortamında yeniden oluşturmaktır**.

Hedef stiller **Stil A — Sade Modern (mavi)** ve **Stil C — Minimal Mono (siyah)**'dır (aşağıya bakınız). Bu bir iOS uygulaması olduğu için önerilen yol **SwiftUI**'dir. Eğer çapraz platform (iOS + Android) hedefleniyorsa **React Native** veya **Flutter** uygun olur. Mevcut bir kod tabanı yoksa bu üçünden biri seçilmeli ve tasarımlar onun kendi pattern'leriyle uygulanmalıdır. HTML olduğu gibi gönderilmemelidir.

## Fidelity (Doğruluk Seviyesi)
**Yüksek (hi-fi).** Renkler, tipografi, boşluklar ve bileşenler nihaidir. Geliştirici UI'ı bu dokümandaki tam değerlerle, pixel-perfect olarak yeniden oluşturmalıdır.

> ✅ **SEÇİLEN STİLLER: Stil A — Sade Modern (mavi) ve Stil C — Minimal Mono (siyah).** Geliştirici bu iki stilin token setini kullanmalıdır. Uygulama bir tema seçici ile ikisi arasında geçiş yapabilir ya da kullanıcı bunlardan birini nihai olarak seçer.
> - **Stil A — Sade Modern:** zemin `#F4F6FB`, vurgu mavi `#2E55E6`, yumuşak gölgeli kartlar, Manrope.
> - **Stil C — Minimal Mono:** beyaz zemin, neredeyse-siyah metin/butonlar `#111418`, ince hairline çizgiler, bol boşluk, Space Grotesk + Hanken Grotesk.
>
> Stil B — Sıcak Klasik (krem/bakır, Newsreader serif) tasarım dosyasında yalnızca referans olarak durur; **uygulanmayacaktır**. Aşağıdaki "Tasarım Token'ları" bölümünde yalnızca **Stil A** ve **Stil C** dikkate alınmalıdır.

---

## Ekranlar / Görünümler

Her stilde aynı 4 ekran vardır. Cihaz hedefi: **iPhone (390 × 844 pt, iPhone 14 sınıfı), Dynamic Island'lı**. Aşağıdaki ölçüler ve metinler tüm stiller için ortaktır; renk/font farkları "Tasarım Token'ları" bölümünde stil bazında verilmiştir.

### 1. Ana Ekran + Widget
- **Amaç:** Kullanıcı telefonun ana ekranındaki widget'a dokununca doğrudan randevu defteri açılır.
- **Düzen:** iOS ana ekranı görünümü — duvar kağıdı (yumuşak dikey gradyan), üstte orta boy (medium) bir widget, altında bir sıra uygulama ikonu (Telefon, Mesajlar, Rehber, **Berber Defteri**), en altta 4 ikonlu dock.
- **Widget içeriği:**
  - Üst satır: logo (32×32, radius 8–9) + "Berber Defteri" + "Bugün" rozeti.
  - Büyük rakam: bugün kalan randevu sayısı ("3") + "randevu kaldı" alt metni.
  - Sonraki 2 randevu: `saat` (vurgu rengi) + `isim`.
  - Widget altında ipucu metni: "Widget'a dokun → randevu defteri açılır".
- **Uygulama ikonu:** `logo.png`, 60×60, radius 16, vurgu rengiyle hafif ring/halka.

### 2. Randevu Defteri (Ana Ekran — takvim + günün listesi)
- **Amaç:** Uygulamanın ana ekranı. Ay takvimi + seçili günün randevu listesi.
- **Düzen (üstten alta):**
  1. **Başlık alanı:** küçük üst etiket "RANDEVU DEFTERİ" + büyük "Haziran 2026". Sağda ay değiştirme için sol/sağ chevron butonları.
  2. **Ay takvimi:** 7 sütunlu grid. Hafta başlıkları Pazartesi'den başlar: `Pt Sa Ça Pe Cu Ct Pz`. Gün hücreleri 40px yükseklik. Bugün/seçili gün (26) vurgulanır. Randevusu olan günlerde altında küçük nokta (dot). Örnek randevulu günler: 2, 9, 12, 18, 24, 29. (Haziran 2026 Pazartesi başlar, 30 gün, 5 satır.)
  3. **Liste başlığı:** "Cuma, 26 Haziran" + sağda "5 randevu".
  4. **Randevu listesi:** her satır → `saat` | `isim` + `telefon` | iki ikon buton: **Ara** (telefon ikonu) ve **Rehbere Kaydet** (kişi+ ikonu).
  5. **FAB (kayan + butonu):** sağ altta, yeni randevu ekler.
- **Örnek veri (seçili gün 26 Haziran):**
  | Saat | İsim | Telefon |
  |------|------|---------|
  | 09:30 | Emre Kaya | 0532 412 88 90 |
  | 10:15 | Hasan Polat | 0541 320 11 76 |
  | 11:00 | Murat Şahin | 0505 884 22 13 |
  | 14:00 | Ozan Çelik | 0533 219 67 40 |
  | 15:30 | Yusuf Arslan | 0542 770 53 18 |

### 3. Yeni Randevu
- **Amaç:** Yeni randevu oluşturma formu.
- **Alanlar (üstten alta):**
  1. Geri (chevron) + "Yeni Randevu" başlığı.
  2. **İsim** alanı + sağında belirgin **Rehber** butonu (kişi+ ikonu). Altında ipucu: "Rehberden seç — isim ve numara otomatik gelsin". → Bu, kullanıcının istediği rehber entegrasyonudur: Rehber butonuna basınca Kişiler açılır, seçilen kişinin adı ve numarası forma otomatik dolar.
  3. **Telefon** alanı (telefon ikonu) — rehberden seçilince otomatik dolar (örn. 0532 412 88 90).
  4. **Tarih** alanı (takvim ikonu) — "Cuma, 26 Haziran 2026".
  5. **Saat** seçimi — saat chip'leri (09:00, 09:30, 10:00, …); biri seçili (09:30, vurgu rengiyle dolu).
  6. **"Randevuyu Kaydet"** — tam genişlik, alta sabit, vurgu rengi, check ikonu.

### 4. Randevu Detayı
- **Amaç:** Tek bir randevuyu görüntüleme/düzenleme; rehbere kaydetme.
- **Düzen:**
  1. Geri (chevron) + Düzenle (kalem) ikonu.
  2. Kişi başlığı: baş harfler avatarı ("EK") + isim ("Emre Kaya") + saat ve tarih chip'leri.
  3. **Telefon satırı:** numara + yeşil **Ara** butonu.
  4. **"Rehbere Kaydet"** — tam genişlik birincil buton (kişi+ ikonu). Bu, kullanıcının istediği "rehbere otomatik kaydet" özelliğidir.
  5. Alt sıra: **Düzenle** ve **Sil** butonları.

---

## Etkileşimler & Davranış
- **Widget'a dokunma →** uygulama açılır ve doğrudan Randevu Defteri (Ekran 2) gösterilir. iOS'ta bu, WidgetKit + deep link (URL scheme / `widgetURL`) ile yapılır.
- **Takvimde güne dokunma →** alttaki liste o günün randevularıyla güncellenir.
- **FAB / "+" →** Yeni Randevu ekranı (Ekran 3).
- **Listedeki "Ara" ikonu →** sistem arama ekranını açar (`tel:` / `CallKit`).
- **Listedeki / detaydaki "Rehbere Kaydet" ikonu →** Kişiler'e isim + telefon yazar (iOS: `CNContactStore` + `CNContactViewController`).
- **Yeni Randevu'da "Rehber" butonu →** kişi seçici açılır (iOS: `CNContactPickerViewController`); seçilen kişinin adı ve numarası forma doldurulur.
- **Saat chip'i →** seçili durum tek seçim (radio mantığı).
- **Geri / chevron →** önceki ekrana döner.
- Geçişler: standart iOS push/pop navigasyonu. Buton basışlarında hafif opacity/scale geri bildirimi.

## Durum Yönetimi (State)
- `appointments: [{ id, name, phone, date, time }]` — yerel veri. Tek cihaz, tek kullanıcı; sunucu/online senkron gerekmez.
- `selectedDate` — takvimde seçili gün; listeyi filtreler.
- `visibleMonth` — takvimde gösterilen ay (chevron'larla değişir).
- Yeni Randevu formu: `name, phone, date, time` (geçici/draft).
- **Kalıcılık:** yerel depolama yeterli (iOS: SwiftData / Core Data / UserDefaults+Codable). Randevusu olan günleri takvimde noktayla işaretlemek için ay bazında gruplama.

---

## Tasarım Token'ları

Ortak: cihaz 390×844, köşe yarıçapı (telefon) 46; durum çubuğu yüksekliği ~50; Dynamic Island 118×33 (siyah, üstte ortalı); home indicator 140×5.

### Stil A — Sade Modern
- **Fontlar:** Manrope (tüm metin). Ağırlıklar 500/600/700/800.
- **Renkler:**
  - Zemin (ekran): `#F4F6FB`
  - Kart: `#FFFFFF`
  - Birincil/vurgu (mavi): `#2E55E6`
  - Yumuşak mavi (chip/buton zemini): `#EAF0FF`
  - Metin (koyu): `#16203A`
  - İkincil metin: `#46506A`
  - Soluk metin: `#8A94AC`
  - Kenarlık (input): `#E6EBF5`
  - Yeşil (Ara): `#34C759`, Kırmızı (Sil): `#FF3B30`
- **Yarıçaplar:** kart 18–28, buton/chip 12–16, FAB 20.
- **Gölge:** kartlar `0 6px 16px rgba(20,30,60,.05)`; FAB/birincil buton `0 14px 26px rgba(46,85,230,.4)`.
- **Bugün hücresi:** dolu mavi kare (radius 12), beyaz rakam.

### Stil B — Sıcak Klasik
- **Fontlar:** başlıklar **Newsreader (serif)** 500/600; gövde **Hanken Grotesk** 400/500/600/700.
- **Renkler:**
  - Zemin: `#F6EFE4` (krem)
  - Kart: `#FFFDF8`
  - Birincil/vurgu (bakır): `#B26A36`
  - Metin (koyu): `#2B2118`
  - İkincil metin: `#7A6B56`
  - Soluk metin: `#9A8A75`
  - Kenarlık: `#E2D4BD` / `#EADDC8`
  - Kırmızı aksan (Sil, dock takvim): `#9C3B33`
  - Yeşil (Ara): `#34C759`
- **Yarıçaplar:** kart 16–24, buton 12–14, FAB 50 (tam yuvarlak).
- **Stil notu:** kartlar gölge yerine 1px sıcak kenarlıkla; liste öğeleri ayrı kart değil, tek kart içinde hairline ayraçlarla (defter hissi). Saat değerleri serif.
- **Bugün hücresi:** dolu yerine **bakır renkli halka (outline)**, bakır rakam.

### Stil C — Minimal Mono
- **Fontlar:** başlık/rakam **Space Grotesk** 500/600; gövde **Hanken Grotesk** 400/500/600.
- **Renkler:**
  - Zemin: `#FFFFFF`
  - Metin (koyu/birincil): `#111418`
  - İkincil metin: `#3A3F47` / `#5B6068`
  - Soluk metin: `#9AA1AB` / `#AEB2BA`
  - Hairline kenarlık: `#E6E6E8` / `#EEEEF0` / `#EAEAEC`
  - Tek aksan (nokta/aktif): mavi `#2E55E6`
  - Kırmızı aksan (Sil): `#9C3B33`
- **Yarıçaplar:** buton/chip 9–16; gölge **yok**.
- **Stil notu:** üst etiketler küçük, harf aralıklı, BÜYÜK HARF. Liste öğeleri kart değil, hairline ayraçlı satırlar. Birincil butonlar neredeyse siyah (`#111418`).
- **Bugün hücresi:** dolu siyah kare (radius 10), beyaz rakam.

### Ortak Tipografi Skalası (yaklaşık)
- Ekran büyük başlık: 24–28
- Bölüm başlığı (gün): 16–19
- Liste isim: 14.5
- Liste telefon/yardımcı: 12
- Üst etiket (uppercase): 10–11, letter-spacing .08–.16em
- Saat (liste/widget): 15–18

### Boşluk Skalası
Ekran iç kenar boşluğu 22–26px. Bileşen aralıkları 8 / 10 / 12 / 14 / 18 / 24px gibi 2'nin/4'ün katları.

---

## İkonlar
Tüm ikonlar inline SVG, stroke tabanlı (currentColor), 1.7–2.2 kalınlık. Gerçek uygulamada **SF Symbols** (iOS) karşılıkları kullanılabilir:
- Telefon/Ara → `phone.fill`
- Rehbere kaydet / kişi seç → `person.crop.circle.badge.plus`
- Takvim → `calendar`
- Saat → `clock`
- Artı (FAB) → `plus`
- Düzenle → `pencil`
- Sil → `trash`
- Chevron sol/sağ → `chevron.left` / `chevron.right`
- Kaydet (check) → `checkmark`

## Assetler
- `logo.png` — uygulama ikonu ve widget logosu (bu pakette mevcut). Mavi zeminli marka logosu. App icon ve widget'ta kullanılır.

## Dosyalar
- `Berber Randevu.dc.html` — 3 stilin ve 4 ekranın tamamını içeren tek tasarım dosyası. Tuval (canvas) düzeninde: sütunlar = stiller (A/B/C), satırlar = ekranlar (Ana ekran widget → Randevu defteri → Yeni randevu → Detay). Tarayıcıda açıp tam ölçü/renk/yerleşimi inceleyebilirsin.
- `logo.png` — marka logosu.

## Notlar
- Bu uygulama **çevrimdışı / tek kullanıcı**dır; backend gerektirmez. Veriyi cihazda tutmak yeterlidir.
- Rehber ve arama özellikleri iOS izinleri gerektirir: `NSContactsUsageDescription` (Info.plist) kişi okuma/yazma için.
- Widget için ayrı bir **Widget Extension** (WidgetKit) hedefi gerekir; ana uygulamayla App Group üzerinden veri paylaşır ve deep link ile randevu ekranını açar.
