# CLAUDE.md — Berber Randevu Defteri

Bu dosya projenin tek kaynaklı (single source of truth) rehberidir. Kod yazılırken **bu kurallar zorunludur**.

---

## Proje Özeti
Bir berberin **kendi kullanımı için** randevu defteri. Amaç online müşteri rezervasyonu **değil**; "hangi gün, saat kaçta, kim geliyor" bilgisini tutan dijital bir defter. Her randevu sadece 3 bilgi tutar: **isim, telefon, tarih & saat** (sade kalması bilinçli tercih).

- **3 sabit kullanıcı**, herkes kendi defteri (sadece kendi randevularını görür).
- **Firebase** ile veri saklanır (Firestore) + giriş (Auth).
- 2 kolaylık: ana ekran **widget'ı** (dokun → defter açılır) ve **rehber entegrasyonu** (kişiden isim+telefon otomatik / rehbere kaydet).

---

## 🔒 KURALLAR (zorunlu)

1. **Akıcılık önce gelir.** Uygulama kasmayacak. Kaliteli, performanslı, temiz kod yaz.
2. **Hiçbir kod dosyası 500 satırı geçmez.** Geçiyorsa parçala.
3. **Gereksiz rebuild yok.** Mümkün olan her yerde `const` constructor; dar kapsamlı dinleme (`StreamBuilder`/`Selector`) — tüm ekranı değil sadece değişen parçayı yeniden çiz.
4. **Listeler hep lazy** (`ListView.builder`/`GridView.builder`). Takvim hücreleri hafif. Ağır iş asla `build()` içinde yapılmaz.
5. **Jank yok.** Senkron/bloklayan I/O yok; ağır hesap gerekirse `compute()`/isolate. Animasyonlar implicit ve 60/120fps hedefli.
6. **Firestore verimli.** Dar sorgu (ay/gün filtreli), offline persistence açık, stream'ler `dispose` edilir (memory leak yok).
7. **Katman ayrımı.** UI Firestore'a doğrudan erişmez → hep `repository`/`service` üzerinden. İş mantığı widget'ta durmaz.
8. **DRY.** Tekrar eden UI ortak widget'a çıkar (kart, buton, chip, üst-etiket).
9. **Hata yönetimi.** Her async işte try/catch; hard crash yok. Her ekranda **loading / empty / error** durumu ele alınır.
10. **Token'lar tek kaynak.** Renk/ölçü/radius/font asla hardcoded yazılmaz → hepsi `theme/app_theme.dart` token'larından gelir.
11. **`flutter analyze` tertemiz.** Uyarısız; `print`/kullanılmayan kod/ölü import yok. Üretim kodunda log için uygun mekanizma.

### Kararlar
- **Font:** Manrope **TTF'leri assets'e gömülür** (`google_fonts` değil) → runtime font indirmesi / FOUT yok, daha akıcı.
- **Dil:** Arayüz metinleri **Türkçe**, kod (değişken/fonksiyon/sınıf isimleri, yorumlar) **İngilizce**.

---

## Mimari & Stack
- **Flutter / Dart**, Material 3, Türkçe lokalizasyon.
- **Firebase:** `firebase_core`, `firebase_auth` (sabit 3 hesap), `cloud_firestore`. `flutterfire configure` → `lib/firebase_options.dart` (iOS+Android).
- **State:** `provider` (hafif `ChangeNotifier`) — auth durumu, seçili tarih, görünen ay. Listeler `StreamBuilder` ile canlı.
- **Tarih/saat:** `intl` + `flutter_localizations`, `tr_TR` locale ("Cuma, 26 Haziran 2026").
- **Rehber:** `flutter_contacts` (picker + rehbere kaydet).
- **Arama:** `url_launcher` (`tel:`).
- **Widget:** `home_widget` + native (iOS WidgetKit, Android AppWidgetProvider).

### Giriş (auth) modeli
Hesaplar Firebase Auth'ta önceden oluşturulur. Login ekranı tek bir form: **e-posta + şifre** → `signInWithEmailAndPassword`. PIN yok, profil kartı yok, kayıt/sign-up yok. Oturum Firebase tarafından kalıcı tutulur; kullanıcı **bir kez girer**, sonraki açılışlarda doğrudan Randevu Defteri'ne düşer (`AuthGate` + `AuthService.isReady`).

---

## Klasör Yapısı (`lib/`)
```
lib/
  main.dart                            // Firebase init, intl init, app root
  theme/app_theme.dart                 // Stil A token'ları (renk, radius, gölge, text)
  models/appointment.dart              // Appointment modeli + Firestore (de)serialize
  services/auth_service.dart           // Firebase Auth wrapper (e-posta+şifre -> signin)
  services/appointment_repository.dart // Firestore CRUD + ay/gün stream'leri
  services/contacts_service.dart       // picker + rehbere kaydet
  services/widget_service.dart         // home_widget güncelleme
  screens/login_screen.dart
  screens/calendar_screen.dart         // Randevu Defteri (ana ekran, deep-link hedefi)
  screens/new_appointment_screen.dart
  screens/appointment_detail_screen.dart
  widgets/                             // ortak UI (kart, buton, saat chip, takvim grid)
```

---

## Firestore Şeması
Kullanıcıya özel subcollection (temiz izolasyon):
```
users/{uid}/appointments/{id}
  name: string
  phone: string
  dateKey: string    // "2026-06-26"  (gün/ay sorgusu için)
  time: string       // "09:30"
  start: Timestamp   // sıralama için
  note: string?      // opsiyonel
  createdAt: Timestamp
```
- Ay sorgusu: `where dateKey >= '2026-06-01' and <= '2026-06-30'` → takvim noktaları.
- Gün listesi: `where dateKey == seçiliGün` → `order by start`.

**Security rules:** `match /users/{uid}/appointments/{doc} { allow read, write: if request.auth.uid == uid; }`

---

## Tasarım — Stil A (Sade Modern, mavi)
Referans: `docs/design_handoff_berber_randevu/README.md` ve `Berber Randevu.dc.html` (görsel). Logo: `docs/.../logo.png`.

**Renkler:** Zemin `#F4F6FB` · Kart `#FFFFFF` · Vurgu `#2E55E6` · Yumuşak mavi `#EAF0FF` · Metin `#16203A` · İkincil `#46506A` · Soluk `#8A94AC` · Kenarlık `#E6EBF5` · Yeşil (Ara) `#34C759` · Kırmızı (Sil) `#FF3B30`.

**Radius:** kart 18–28 · buton/chip 12–16 · FAB 20.
**Gölge:** kart `0 6px 16px rgba(20,30,60,.05)` · FAB `0 14px 26px rgba(46,85,230,.4)`.
**Font:** Manrope 500/600/700/800. **Bugün hücresi:** dolu mavi kare (radius 12), beyaz rakam.
**Takvim:** Pazartesi başlangıç (`Pt Sa Ça Pe Cu Ct Pz`), randevulu günde alt nokta.

**Ekranlar:** 1) Ana ekran + Widget · 2) Randevu Defteri (takvim + günün listesi, FAB) · 3) Yeni Randevu (form + rehber butonu + saat chip'leri) · 4) Randevu Detayı (ara, rehbere kaydet, düzenle, sil).

---

## Fazlar
Detaylı plan: `~/.claude/plans/kral-imdi-seninle-bir-crystalline-eclipse.md`
- **Faz 0** — Kurulum & Kurallar (bu dosya, pubspec, Firebase bağlantısı)
- **Faz 1** — Tema & İskelet
- **Faz 2** — Auth (sabit 3 hesap)
- **Faz 3** — Randevu Defteri (ana ekran)
- **Faz 4** — Yeni Randevu + Rehber
- **Faz 5** — Randevu Detayı
- **Faz 6** — Ana ekran Widget'ı
- **Faz 7** — Kolaylıklar (opsiyonel: bildirim, WhatsApp/SMS hatırlatma, arama, not)
- **Faz 8** — Cila & Test

---

## Komutlar
```bash
flutter pub get          # bağımlılıklar
flutter run              # çalıştır (simülatör/emülatör/cihaz)
flutter analyze          # lint — daima temiz olmalı
flutter test             # testler
flutterfire configure    # Firebase bağlama (Faz 0, interaktif)
```

> Not: Tasarım dökümanı "offline, backend yok" der; kullanıcının açık isteğiyle **Firebase ile** kuruluyor — bu nokta dökümanı geçersiz kılar.
