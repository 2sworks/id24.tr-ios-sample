# Tema — SDK Ekranlarını Markanıza Boyamak

SDK'nın hazır ekranları tek bir tema kaynağından beslenir: **`SDKTheme.shared`**.
Renkleri, fontu, ikonları ve boşluk/köşe metriklerini `setupSDK`'dan önce bir kez ayarlarsınız;
tüm drop-in ekranlar otomatik olarak markanıza bürünür — **hiçbir ekranı yeniden yazmadan.**

← [README'ye dön](../../README.md) · İlgili: [Özelleştirme](customization.md) (ekranın tamamını değiştirmek için)

---

## İki Seviye Özelleştirme

1. **Tema (bu rehber)** — SDK ekranları kalır, görünümleri değişir. Çoğu marka uyumu için yeterli.
2. **Ekran override** — ekranın tamamını kendi tasarımınızla değiştirirsiniz.
   → [Özelleştirme Rehberi](customization.md)

---

## Hızlı Başlangıç

```swift
// Uygulama açılışında, setupSDK'dan ÖNCE — bir kez.
let theme = SDKTheme.shared

// Renkler
theme.colors.primary      = Color(hex: "#E4002B")     // marka ana rengi
theme.colors.primaryDark  = Color(hex: "#B80023")
theme.colors.success      = Color(hex: "#0BA34E")

// Font ailesi (uygulamada kayıtlı bir custom font)
theme.fonts.familyName = "Sofia Pro"

// İkon/illüstrasyon değişimi
theme.setIcon(.logo, Image("my_bank_logo"))
theme.setIcons([
    .thankYouSuccess: Image("my_success_hero"),
    .lostConnection:  Image("my_offline_hero"),
])
```

---

## Token Sistemi

SDK ekranları renk/font/boşluk değerlerini asla elle yazmaz; her şey token üzerinden okunur.
Token'lar `SDKTheme.shared`'a bakar — siz temayı değiştirince tüm ekranlar değişir.

| Token ailesi | Örnek | Kaynağı |
|---|---|---|
| `IDColor` | `IDColor.primary`, `IDColor.error` | `theme.colors` (`SDKColors`) |
| `IDFont` | `IDFont.font(size:weight:)` | `theme.fonts` (`SDKFonts`) |
| `IDSpacing` | `IDSpacing.md` (12pt) | `theme.metrics` (`SDKMetrics`) |
| `IDRadius` | `IDRadius.card` (36pt) | `theme.metrics` |

Kendi custom ekranlarınızda da bu token'ları kullanabilirsiniz — böylece override ettiğiniz
ekran, SDK'nın geri kalanıyla otomatik uyumlu kalır.

### Renk Paleti — `SDKColors`

| Grup | Üyeler |
|---|---|
| Marka | `primary` · `primaryDark` · `primaryLight` |
| Başarı | `success` · `successAlt` · `successBright` |
| Hata | `error` |
| Metin/yüzey (ink) | `inkDarkest` · `inkDark` · `inkMid` · `inkLight` · `inkBorder` · `inkBackground` · `inkSurface` · `inkSubtitle` |
| Koyu yüzeyler | `darkBg` · `darkBgSecondary` · `darkMuted` |
| Diğer | `divider` · `accentPurple` · `accentTeal` |

### Fontlar — `SDKFonts`

- `familyName` — tek satırla tüm SDK tipografisini değiştirir (varsayılan: **Inter**).
- Font uygulamanızda kayıtlı değilse çalışma zamanında yükleyebilirsiniz:

```swift
SDKTheme.shared.registerFont(at: fontFileURL)     // ya da
SDKTheme.shared.registerFont(data: fontData)      // bundle'a gömülü veri
SDKTheme.shared.fonts.familyName = "Sofia Pro"
```

### Metrikler — `SDKMetrics`

Boşluklar (`spacingXS` 4 → `spacingXXL` 32) ve köşe yarıçapları (`radiusSM` 8 →
`radiusCard` 36). Daha keskin köşeli bir görünüm için örneğin:

```swift
SDKTheme.shared.metrics.radiusCard = 12
```

---

## İkonlar ve İllüstrasyonlar — `SDKIconKey`

Her görsel öğe bir anahtarla değiştirilebilir; anahtarların tam listesi `SDKIconKey`
(`CaseIterable`) enum'ındadır. Önemli gruplar:

| Grup | Anahtarlar |
|---|---|
| Nav / chrome | `logo` · `hamburger` · `langButton` · `back` · `help` · `close` |
| Aksiyonlar | `retry` · `checkmark` · `camera` · `trash` · `video` · `chat` · `calendar` · `chevronRight` · `signLang` ... |
| İzin satırları (Prepare) | `permCamera` · `permMic` · `permSpeech` · `permIdCard` · `permAlone` · `permConditions` |
| İllüstrasyonlar | `incomingCall` · `nfcFront` · `nfcBack` · `thankYouSuccess` · `thankYouFail` · `uploadFile` · `lostConnection` · `idCardFront` · `idCardBack` |
| Durum/kontrol | `successCircle` · `failCircle` · `play` · `pause` · `mic` · `stopRecord` · `torchOn` · `torchOff` · `wifiGood` · `wifiBad` |
| Belge türü seçimi | `idTypeChip` · `idTypePassport` · `idTypeOther` |

```swift
theme.setIcon(.nfcFront, Image("my_nfc_illustration"))
theme.resetIcon(.nfcFront)      // SDK varsayılanına dön
```

Override etmediğiniz her anahtar SDK'nın kendi görselini kullanır.

---

## Görsel Kontrol: Showcase Kataloğu

Sample App'teki **Showcase** bölümü (`Showcase/ShowcaseCatalogView.swift`), tüm ekranları ve
tasarım sistemini tek yerden gezmenizi sağlar. Temanızı ayarladıktan sonra kataloğu açıp
markanızın her ekranda nasıl durduğunu hızlıca kontrol edin — akışı baştan sona koşturmanıza
gerek kalmaz.
