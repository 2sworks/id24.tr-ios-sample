# Full Integration — SDK'nın Tüm Özelleştirme Yetenekleri

Bu doküman, IdentifySDK Default UI'ının **dışarıdan özelleştirilebilen her şeyini** tek yerde
toplar: renkler, fontlar, ikonlar, metrikler, metinler (5 dil), sesli okuma (TTS), akış
kontrolü, ekran override / custom ekran ekleme, ortak bileşenler, olay akışı, loglama ve
`setupSDK` konfigürasyonu. Entegrasyon yaparken "bu değiştirilebilir mi?" sorusunun cevabı
buradadır.

← [README'ye dön](README.md) · Derinlemesine: [Tema](docs/guides/theming.md) · [Özelleştirme](docs/guides/customization.md) · [Lokalizasyon](docs/guides/localization.md) · [Event Sistemi](docs/guides/events.md) · [Loglama](docs/guides/logging.md) · [Sunucu & API](docs/guides/server-api.md)

---

## İçindekiler

1. [Kurulum Sırası — Neyi Ne Zaman Ayarlayacaksınız](#1-kurulum-sırası)
2. [Tema — `SDKTheme.shared`](#2-tema--sdkthemeshared)
   - [Renkler (`SDKColors`) — tam liste + varsayılanlar](#renkler--sdkcolors)
   - [Fontlar (`SDKFonts`) — aile değiştirme + runtime kayıt](#fontlar--sdkfonts)
   - [İkonlar (`SDKIconKey`) — tam liste + varsayılanlar](#i̇konlar--sdkiconkey)
   - [Metrikler (`SDKMetrics`) — boşluk + köşe yarıçapları](#metrikler--sdkmetrics)
3. [Tasarım Token'ları — `IDColor` / `IDFont` / `IDSpacing` / `IDRadius`](#3-tasarım-tokenları)
4. [Lokalizasyon — `SDKLocalization` (5 dil + override)](#4-lokalizasyon--sdklocalization)
5. [Sesli Okuma (TTS) — `SDKSpeechConfig` + `SDKSpeechService`](#5-sesli-okuma-tts)
6. [Akış Kontrolü — `SDKFlowCoordinator` + `SDKFlowHostView`](#6-akış-kontrolü)
7. [Ekran Değiştirme & Ekleme — `SDKViewRegistry`](#7-ekran-değiştirme--ekleme)
8. [Hazır Modül Ekranları ve ViewModel'leri](#8-hazır-modül-ekranları)
9. [Ortak UI Bileşenleri](#9-ortak-ui-bileşenleri)
10. [`setupSDK` — Tüm Parametreler + `SDKNetworkOptions`](#10-setupsdk-konfigürasyonu)
11. [Olay Akışı — `SDKEvent` / `eventDelegate` / `trackingDelegate`](#11-olay-akışı)
12. [Loglama — `SDKLog` / `SDKLogLevel`](#12-loglama)
13. [Global Bağlantı Kopması Katmanı](#13-global-bağlantı-kopması-katmanı)
14. ["Bypass Yok" Kuralı + Yayın Öncesi Kontrol Listesi](#14-bypass-yok-kuralı)
15. [Navigasyon Sahipliği — Sheet mi, Push mu, Window mu?](#15-navigasyon-sahipliği)
16. [IdentityScanner — Detaylı İmplementasyon](#16-identityscanner--detaylı-i̇mplementasyon)
17. [Çoklu İş Senaryosu — Aynı SDK, Farklı Akışlar](#17-çoklu-i̇ş-senaryosu)

---

## 1) Kurulum Sırası

Tüm özelleştirmeler **`setupSDK`'dan ÖNCE, uygulama açılışında bir kez** yapılır.
Önerilen sıra:

```swift
// 1. Dil
IdentifyManager.shared.setSDKLang(lang: .tr)

// 2. Tema (renk / font / ikon / metrik)
let theme = SDKTheme.shared
theme.colors.primary = Color(hex: "#E4002B")
theme.fonts.familyName = "Sofia Pro"
theme.setIcon(.logo, Image("my_logo"))

// 3. Metin override'ları (gerekirse)
SDKLocalization.shared.setOverride(key: .thankU, language: .tr, value: "İşleminiz alındı!")

// 4. Sesli okuma (gerekirse)
SDKSpeechConfig.shared.setModeForAll(.native)

// 5. Coordinator + registry (ekran override / custom ekranlar)
let coordinator = SDKFlowCoordinator()
let registry = SDKViewRegistry()
registry.override(.selfie) { MyCustomSelfieView() }
coordinator.insert(["kvkk"], before: .prepare)

// 6. Olay / log dinleyicileri (gerekirse)
IdentifyManager.shared.eventDelegate = myAnalytics

// 7. SDK kurulumu
coordinator.prepareForSetup()                    // setupSDK'dan ÖNCE — zorunlu
IdentifyManager.shared.setupSDK(...) { socket, room, error in
    if error == nil { coordinator.start() }     // ilk modüle geçer
}
```

Kök view:

```swift
SDKFlowHostView(coordinator: coordinator, registry: registry) {
    MyLoginView()        // path boşken gösterilen kök ekran (sizin login'iniz)
}
```

---

## 2) Tema — `SDKTheme.shared`

Tüm SDK ekranları renk/font/ikon/metrik değerlerini **tek kaynaktan** okur:
`SDKTheme.shared`. Bir değeri değiştirdiğinizde ekran yazmadan tüm UI değişir.

```swift
public final class SDKTheme {
    public static let shared = SDKTheme()
    public var colors  = SDKColors()      // renk paleti
    public var fonts   = SDKFonts()       // font ailesi
    public var icons   = SDKIcons()       // logo/hamburger/langButton (eski stil)
    public var metrics = SDKMetrics()     // boşluk + köşe yarıçapı

    public func setIcon(_ key: SDKIconKey, _ image: Image)   // tek ikon override
    public func setIcons(_ map: [SDKIconKey: Image])          // toplu override
    public func resetIcon(_ key: SDKIconKey)                  // varsayılana dön
    public func registerFont(at url: URL) -> Bool             // font dosyası kaydet
    public func registerFont(data: Data) -> Bool              // bellekteki font verisi
}
```

### Renkler — `SDKColors`

Tam liste ve fabrika varsayılanları:

| Property | Varsayılan | Kullanım |
|---|---|---|
| `primary` | `#446EF7` | Marka ana rengi — butonlar, vurgular, progress |
| `primaryDark` | `#2C5BF6` | Koyu temada primary karşılığı |
| `primaryLight` | `#F0F5FF` | Açık primary zemin (chip/rozet arka planı) |
| `success` | `#41D97F` | Başarı durumları |
| `successAlt` | `#56DD8C` | Alternatif başarı tonu (gradyan vb.) |
| `successBright` | `#30D158` | Parlak başarı (success buton zemini) |
| `error` | `#FF453A` | Hata durumları, cancel buton zemini |
| `inkDarkest` | `#111827` | En koyu metin (başlıklar) |
| `inkDark` | `#1A1A1A` | Koyu metin |
| `inkMid` | `#5C616F` | Orta ton metin |
| `inkLight` | `#A7AAB2` | Açık/ikincil metin |
| `inkBorder` | `#E5E7EB` | Kenarlıklar, pasif progress dolgusu |
| `inkBackground` | `#F9FAFB` | Sayfa arka planı |
| `inkSurface` | `#F6F7F8` | Kart/yüzey zemini, secondary buton |
| `inkSubtitle` | `#9CA3AF` | Alt başlık metni |
| `darkBg` | `#111827` | Koyu tema sayfa zemini |
| `darkBgSecondary` | `#1F2533` | Koyu tema yüzey zemini |
| `darkMuted` | `#57637F` | Koyu tema ikincil metin |
| `divider` | `#D1D5DB` | Ayırıcı çizgiler |
| `accentPurple` | `#8C33CC` | Alternatif vurgu (tema örnekleri için) |
| `accentTeal` | `#1A8C73` | Alternatif vurgu (tema örnekleri için) |

```swift
SDKTheme.shared.colors.primary = Color(hex: "#E4002B")   // hex init SDK'da hazır
```

> `Color(hex:)` 6 haneli (`#RRGGBB`) ve 8 haneli (`#RRGGBBAA`) formatları destekler.

### Fontlar — `SDKFonts`

- `familyName: String?` — **tek satırla tüm SDK tipografisi değişir.**
  Varsayılan: `"Inter"` (SDK bundle'ında `Inter.ttf` + `Inter-Italic.ttf` gömülü,
  ilk erişimde otomatik kaydedilir). `nil` → iOS sistem fontu.
- `font(size:weight:)` — aktif aileye göre `Font` üretir (token'lar bunu kullanır).

Uygulamanızda kayıtlı olmayan bir fontu çalışma zamanında kaydedebilirsiniz:

```swift
// Dosyadan:
SDKTheme.shared.registerFont(at: Bundle.main.url(forResource: "SofiaPro", withExtension: "ttf")!)
// veya bellekteki veriden:
SDKTheme.shared.registerFont(data: fontData)
// Sonra PostScript AİLE adıyla aktive edin:
SDKTheme.shared.fonts.familyName = "Sofia Pro"
```

> Dikkat: `familyName` dosya adı değil, fontun **PostScript family adıdır**
> (Font Book'ta görünen ad).

### İkonlar — `SDKIconKey`

SDK ekranlarındaki **her görsel öğe** bir anahtarla değiştirilebilir. `SDKIconKey`
`CaseIterable`'dır — tüm anahtarları kodla gezebilirsiniz. Tam liste ve varsayılanlar:

**Nav / chrome**

| Anahtar | Varsayılan | Nerede |
|---|---|---|
| `.logo` | `ic_identify_logo_text` (bundle) | Login nav bar, overlay bar ortası |
| `.hamburger` | `hamburger` (bundle) | Login nav bar sol menü |
| `.langButton` | `ic_lang_button_dark` (bundle) | Modül bar'ındaki yuvarlak logo |
| `.back` | SF `chevron.left` | Tüm geri butonları |
| `.help` | SF `questionmark` | Overlay bar yardım butonu |
| `.close` | SF `xmark` | Kapat butonları |

**Aksiyon glifleri**

| Anahtar | Varsayılan |
|---|---|
| `.retry` | SF `arrow.counterclockwise` |
| `.checkmark` | SF `checkmark` |
| `.camera` | SF `camera.fill` |
| `.trash` | SF `trash` |
| `.video` | SF `video.fill` |
| `.chat` | SF `message.fill` |
| `.calendar` | SF `calendar` |
| `.sparkles` | SF `sparkles` |
| `.chevronRight` | SF `chevron.right` |
| `.signLang` | SF `person.wave.2.fill` |

**Hazırlık (Prepare) izin satırı ikonları**

| Anahtar | Varsayılan (bundle, template) |
|---|---|
| `.permCamera` | `ic_camera` |
| `.permMic` | `ic_microphone` |
| `.permSpeech` | `ic_ear` |
| `.permIdCard` | `ic_id_card` |
| `.permAlone` | `ic_user_dashed` |
| `.permConditions` | `ic_lightbulb` |

**İllüstrasyon / marka görselleri**

| Anahtar | Varsayılan (bundle) | Nerede |
|---|---|---|
| `.incomingCall` | `incoming_call` | Görüşme bekleme ekranı |
| `.incomingCallButton` | `incoming_call_button` | Gelen çağrı cevaplama |
| `.nfcFront` | `id_nfc_front` | NFC yönlendirme (kimlik ön) |
| `.nfcPassportFront` | `pasaport_nfc_front` | NFC yönlendirme (pasaport ön) |
| `.nfcBack` | `nfc_back` | NFC yönlendirme (arka, ortak) |
| `.thankYouSuccess` | `ty_checkmark` | ThankYou başarı hero'su |
| `.thankYouFail` | `ty_xmark` | ThankYou başarısız hero'su |
| `.uploadFile` | `upload_file` | Adres belgesi yükleme |
| `.lostConnection` | `lost_connection` | Bağlantı koptu ekranı |
| `.idCardFront` | `frontID` | Kimlik ön yüz illüstrasyonu |
| `.idCardBack` | `backID` | Kimlik arka yüz illüstrasyonu |

**Durum / kontrol glifleri**

| Anahtar | Varsayılan |
|---|---|
| `.successCircle` | SF `checkmark.circle.fill` |
| `.failCircle` | SF `xmark.circle.fill` |
| `.play` | SF `play.fill` |
| `.pause` | SF `pause.fill` |
| `.mic` | SF `mic.fill` |
| `.stopRecord` | SF `stop.fill` |
| `.torchOn` | SF `bolt.fill` |
| `.torchOff` | SF `bolt.slash.fill` |
| `.wifiGood` | SF `wifi` |
| `.wifiBad` | SF `wifi.exclamationmark` |

**Belge türü seçim satırı (IdCard ekranı)**

| Anahtar | Varsayılan |
|---|---|
| `.idTypeChip` | SF `person.text.rectangle` |
| `.idTypePassport` | SF `book.closed` |
| `.idTypeOther` | SF `rectangle.portrait.on.rectangle.portrait` |

Kullanım:

```swift
SDKTheme.shared.setIcon(.nfcFront, Image("my_nfc_illustration"))
SDKTheme.shared.setIcons([
    .thankYouSuccess: Image("my_success_hero"),
    .lostConnection:  Image("my_offline_hero"),
])
SDKTheme.shared.resetIcon(.nfcFront)          // SDK varsayılanına geri dön

// Kendi custom ekranınızda aktif temadaki ikonu kullanmak:
Image.sdk(.camera)                             // host override varsa onu döndürür
```

> Geriye uyumluluk: `.logo` / `.hamburger` / `.langButton` için eski
> `theme.icons.logo = Image(...)` stili de çalışır; `setIcon` daha yenidir ve önceliklidir.

### Metrikler — `SDKMetrics`

| Property | Varsayılan | Kullanım |
|---|---|---|
| `spacingXS` | 4 | En küçük boşluk |
| `spacingSM` | 8 | Küçük boşluk |
| `spacingMD` | 12 | Orta boşluk |
| `spacingLG` | 16 | Standart kenar boşluğu |
| `spacingXL` | 24 | Bölüm arası |
| `spacingXXL` | 32 | Büyük bölüm arası |
| `radiusSM` | 8 | Küçük köşe |
| `radiusMD` | 12 | Orta köşe |
| `radiusLG` | 16 | Büyük köşe |
| `radiusXL` | 24 | Ekstra büyük köşe |
| `radiusCard` | 36 | Kart köşesi |
| `radiusPill` | 40 | Hap (pill) şekli |
| `radiusCircle` | 9999 | Tam yuvarlak |

```swift
SDKTheme.shared.metrics.radiusCard = 12    // daha keskin köşeli kartlar
```

---

## 3) Tasarım Token'ları

SDK ekranları değerleri asla elle yazmaz; her şey bu erişimcilerden okunur. **Kendi custom
ekranlarınızda da bunları kullanın** — override ettiğiniz ekran SDK'nın geri kalanıyla ve
temanızla otomatik uyumlu kalır.

### `IDColor`

`SDKColors`'taki her rengin statik karşılığı (`IDColor.primary`, `IDColor.error`...) artı
**dark-mode duyarlı yardımcılar**:

| Fonksiyon | Açık tema | Koyu tema |
|---|---|---|
| `IDColor.adaptivePrimary(for:)` | `primary` | `primaryDark` |
| `IDColor.adaptiveBackground(for:)` | `.white` | `darkBg` |
| `IDColor.adaptiveSurface(for:)` | `inkSurface` | `darkBgSecondary` |
| `IDColor.adaptiveTitle(for:)` | `inkDarkest` | `.white` |
| `IDColor.adaptiveSubtitle(for:)` | `inkLight` | `darkMuted` |
| `IDColor.adaptiveBorder(for:)` | `inkBorder` | `white.opacity(0.08)` |

```swift
@Environment(\.colorScheme) private var colorScheme
Text("Başlık").foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
```

### `IDFont` — tipografi ölçeği

Hepsi aktif `familyName`'den üretilir; ağırlık parametresi opsiyoneldir:

| Fonksiyon | Boyut | Varsayılan ağırlık |
|---|---|---|
| `IDFont.displayLarge()` | 28 | bold |
| `IDFont.displayMedium()` | 24 | bold |
| `IDFont.displaySmall()` | 20 | bold |
| `IDFont.bodyLarge()` | 18 | semibold |
| `IDFont.bodyMediumPlus()` | 17 | medium |
| `IDFont.bodyMedium()` | 16 | medium |
| `IDFont.bodyRegular()` | 15 | medium |
| `IDFont.bodySmall()` | 14 | medium |
| `IDFont.caption()` | 13 | medium |

```swift
Text("Alt başlık").font(IDFont.bodyRegular(.regular))
```

### `IDSpacing` ve `IDRadius`

`SDKMetrics`'in birebir yansımaları: `IDSpacing.xs/sm/md/lg/xl/xxl`,
`IDRadius.sm/md/lg/xl/card/pill/circle`.

---

## 4) Lokalizasyon — `SDKLocalization`

### Diller

`SDKLang`: `.tr` · `.eng` · `.de` · `.az` · `.ru` — SDK bundle'ında 5 JSON
(`TURKISH/ENGLISH/GERMAN/AZERI/RUSSIAN.json`). Aktif dil:

```swift
IdentifyManager.shared.setSDKLang(lang: .tr)     // nil bırakılırsa .eng
```

### Çözümleme sırası

`translate(_:)` her key için: **1) host override → 2) SDK bundle JSON → 3) key'in kendisi**.

### Host Override API'si — her metni değiştirebilirsiniz

```swift
// Tek key, tek dil:
SDKLocalization.shared.setOverride(key: .connect, language: .tr, value: "Bağlan")

// Toplu (birden fazla dil):
SDKLocalization.shared.registerOverrides([
    .tr:  ["Connect": "Bağlan", "ThankU": "Teşekkürler!"],
    .eng: ["Connect": "Connect"],
])

// Kendi JSON dosyanızdan ([String: String]) yükleme:
SDKLocalization.shared.loadOverrides(from: url, language: .tr)

// Temizlik:
SDKLocalization.shared.clearOverrides()
SDKLocalization.shared.clearCache()
```

### SwiftUI kısayolları

```swift
Text(.selfieTitle)                                 // Text init
String(.coreCancel)                                // String init
SDKKeyword.thankU.localized                        // property
SDKLocalization.shared.translate(.connect)         // klasik
```

### Kendi ekranlarınız için serbest key'ler

`SDKKeyword`'de olmayan, tamamen size ait key'ler de aynı dil sisteminden geçer:

```swift
SDKLocalization.shared.registerOverrides([.de: ["MyIntro": "Willkommen"]])
Text(SDKLocalization.shared.string(forKey: "MyIntro"))   // aktif dile göre çözülür
```

### Key envanteri — `SDKKeyword` grupları

400'e yakın key vardır; tam liste `SDKLocalization.swift`'teki `SDKKeyword` enum'undadır.
Ana gruplar:

| Grup | Örnek key'ler |
|---|---|
| Genel çekirdek | `coreOk`, `coreCancel`, `coreError`, `coreSuccess`, `coreSend`, `coreSettings`, `coreTryAgain`, `corePlsWait` |
| Onboarding/board | `board1`...`board5`, `nextPage`, `backPage`, `skipPage`, `continuePage` |
| Hazırlık (Prepare) | `permissions`, `permissionsText`, `prepareCam`, `prepareMic`, `prepareSpeech`, `readyChecklistDesc`, `idNear`, `ownAuth` |
| Selfie | `selfieTitle`, `selfieInfoTitle/Desc`, `selfieFrameInstruction`, `faceNotFound`, `selfieUploaded`, `selfieRetryTips` |
| Kimlik/OCR | `idCardInfoTitle/Desc`, `scanIdFront/Back`, `newIdCard`, `passport`, `otherCards`, `scanType`, `wrongFrontSide/BackSide`, `ocrError` |
| NFC | `nfcInfoTitle/Desc`, `nfcHoldInstruction(Passport)`, `nfcSerialNo`, `nfcBirthDate`, `nfcExpDate`, `nfcSuccess`, `nfcManualEntry`, `mrzEdit*` |
| Canlılık (Liveness) | `livenessStep1..4(+Desc)`, `livenessLookCam`, `envTooDark/Bright`, `headUp/Down`, `faceLeft/Right`, `stayStill`, `fitFaceInFrame` |
| Video kayıt + sesli doğrulama | `recordVideo`, `readingTestTitle/Desc`, `sentenceToReadLabel`, `voiceVerifying`, `youSaidLabel`, `speechNoMatchTitle`, `similarityLabel` |
| Konuşma tanıma (KYC modülü) | `speechInfoTitle/Text`, `spokenWordLabel`, `soundRecogOk/Fail`, `speechNotRecognized` |
| İmza | `signatureTitle`, `signatureInfo(Title/Desc)`, `coreDelSig`, `signatureUploadFailed` |
| Adres | `addressVerifyTitle/Desc`, `choosePhoto`, `chooseFile`, `uploadFile`, `pdfMaxSizeFmt`, `docAddressDesc` |
| Görüşme (Call) | `callTitle/Description`, `callConnectingInfo`, `callEndCall`, `callQueuePositionFmt`, `callEstimatedWaitFmt`, `missedCallTitle` |
| ThankYou | `thankU`, `thankYouMissedTitle`, `thankYouFailedTitle`, `thankYouCompletedDesc`, `resultWillBeNotified` |
| Bağlantı | `coreNoInternet(Desc)`, `coreReConnect`, `coreReconnecting`, `connectionLostTitle/Desc`, `checkMyConn`, `connectionGood` |
| Cihaz/izin hataları | `cameraPermissionDenied`, `micPermissionDenied`, `speechPermissionDenied`, `micAccessError`, `cameraAccessError`, `mediaAccessError` |
| OVD (hologram) | `ovdScanFrontSide`, `ovdHologram`, `ovdFlashMoveCard`, `ovdGlareCaptured`, `ovdUploading`... |
| IdentityScanner HUD | `scannerIdleId`, `scannerFocusing`, `scannerLockedId`, `scannerRotatePassport`, `scannerIdlePassport`... |
| TTS metinleri | `prepareTts`, `selfieTts`, `idCardTts`, `nfcTts`, `livenessTts`, `thankYouTts`... (aşağıdaki TTS bölümüne bakın) |

---

## 5) Sesli Okuma (TTS)

İki ayrı parça vardır: **konfigürasyon** (`SDKSpeechConfig.shared`) ve **çalıştırıcı**
(`SDKSpeechService.shared`). Ekranlar açılırken rotalarına atanmış metni otomatik okur.

> Karışıklık uyarısı: buradaki "speech" sesli **okuma**dır (TTS). KYC konuşma-**tanıma**
> modülü (`SdkModules.speech` / `SDKSpeechRecView`) bundan bağımsızdır.

### Modlar — modül başına seçilebilir

| Mod | Davranış |
|---|---|
| `.off` | O modülde sesli okuma yok (fabrika varsayılanı) |
| `.native` | iOS `AVSpeechSynthesizer` (Siri/sistem sesi) lokalize `*Tts` metnini okur |
| `.customAudio` | Sizin bundle'a koyduğunuz ses dosyasını `AVAudioPlayer` çalar |

```swift
SDKSpeechConfig.shared.setModeForAll(.native)                    // hepsi native (+ override'ları sıfırlar)
SDKSpeechConfig.shared.setMode(.customAudio, for: [.selfie, .nfc])
SDKSpeechConfig.shared.setMode(.off, for: .livenessDetection)
```

> `setupSDK(ttsEnabled: true)` çağrısı, `defaultMode` hâlâ `.off` ise onu `.native`'e yükseltir.
> Host'un açık mod ataması her zaman kazanır.

### Tüm konfigürasyon alanları

| Property | Varsayılan | Açıklama |
|---|---|---|
| `defaultMode` | `.off` | Per-modül override yoksa geçerli mod |
| `interruptPolicy` | `.interruptOnNext` | Aşağıya bakın |
| `respectVoiceOver` | `true` | VoiceOver açıkken SDK okuması devre dışı |
| `speechRate` | sistem | `AVSpeechUtterance.rate` (0.0–1.0) |
| `pitch` | `1.0` | Perde çarpanı (0.5–2.0) |
| `voiceIdentifier` | `nil` | Belirli Siri/sistem sesi ID'si; nil → aktif dile göre |
| `audioBundle` | `nil` | Custom ses dosyalarının önce aranacağı bundle |
| `audioFileExtension` | `"m4a"` | Öncelikli uzantı; bulunamazsa m4a/mp3/wav/caf/aac/aiff otomatik denenir |
| `fallbackToNativeIfAudioMissing` | `true` | `.customAudio`'da dosya yoksa native oku |

**`InterruptPolicy` seçenekleri:**

Sesli okuma ekranı **kilitlemez**; kullanıcı okuma sürerken ilerleyebilir. Geçişte okuma
kesilir, sonraki modül `onAppear`'da kendi okumasını baştan başlatır.

| Politika | Davranış |
|---|---|
| `.interruptOnNext` (varsayılan) | Modül geçişinde okuma anında kesilir; sonraki modül baştan okur |
| `.finishThenNext` | Okumalar sıraya alınır; sonraki, önceki bitince başlar |
| `.blockUntilDone` | Kullanımdan kaldırıldı; `.interruptOnNext` gibi davranır |

### Custom ses dosyası adlandırma

`.customAudio` modunda dosya adı = **TTS key'inin raw value'su** + uzantı:

- Genel klip: `<key>.<ext>` — örn. `SelfieTts.m4a`, `NfcTts.mp3`
- Dile özel klip: `<key>_<dil>.<ext>` — örn. `AddressConfirmTts_tr.mp3` (**önce** aranır;
  yalnızca o dil aktifken çalar, diğer dillerde genel klibe/native'e düşülür)

Arama sırası: `audioBundle` → SDK bundle → main bundle. Uzantı: önce
`audioFileExtension`, sonra diğer desteklenenler (m4a/mp3/wav/caf/aac/aiff). Dosya hiç
bulunamazsa `fallbackToNativeIfAudioMissing` açıksa native okunur; akış asla bloklanmaz.

> SDK'nın kendi bundle'ında hazır klipler olabilir (şu an `AddressConfirmTts_tr.mp3`).
> Host bir modül için **açıkça mod atamadıysa** SDK bu hazır klibi native'e tercih eder;
> açık atamanız her zaman kazanır.

### Rota → TTS key eşlemesi

| Rota | Key | Not |
|---|---|---|
| `.prepare` | `PrepareTts` | |
| `.selfie` | `SelfieTts` | Kamera hazır olana kadar ertelenir |
| `.selfieWithLiveness` | `SelfieWithLivenessTts` | Kamera beklenir |
| `.idCard` | `IdCardTypeSelectTts` | Ayrıca: `IdCardFrontTts`, `IdCardBackTts`, `PassportTts` view içinden |
| `.idCardOVD` | `IdCardOVDTts` | Kamera beklenir |
| `.nfc` | — | Otomatik okuma yok; view belge tipine göre `NfcTts` / `NfcPassportTts` okur |
| `.liveness` | `LivenessTts` | Kamera beklenir; ardından her adımın komutu okunur |
| `.speech` | `SpeechTts` | |
| `.addressConfirm` | `AddressConfirmTts` | SDK'da hazır TR klibi var (`AddressConfirmTts_tr.mp3`) |
| `.signature` | `SignatureTts` | |
| `.videoRecorder` | — | Otomatik okuma yok; view, `readingText`'e göre kendi okur |
| `.callScreen` | `CallScreenTts` | |
| `.thankYou` | `ThankYouTts` | |
| `.custom(id)` | — | Otomatik okuma yok; kendiniz tetikleyebilirsiniz |

### Aksiyona bağlı seslendirme

Açılış yönergesinin ötesinde NFC, Selfie ve Canlılık modülleri kullanıcının aksiyonunu takip eder:

- **NFC:** okuma başladı (`NfcReadingTts`) → bitti (`NfcSuccessTts`) → hata (`NfcErrorTts`).
- **Selfie:** ekrandaki yüz yönlendirmesi ne diyorsa o okunur (uzaksınız / karanlık / hareketsiz kalın).
- **Canlılık:** her adımda o adımın komutu (`LivenessSmileTts`, `LivenessBlinkTts`, …).
  ARKit'in henüz algılamadığı altı komut da beş dilde hazır bekler.

Bunun için üç giriş noktası vardır: `speak` (böler, mutlaka okunur), `speakAfterCurrent`
(sıraya girer), `announce` (tekrar eden durum; kendini kısıtlar, kare başına çağrılabilir).
Ayrıntı: `SampleApp/NewTest/Modules/ReadAloud.md` §7c.

### Programatik okuma — kendi ekranlarınızda

```swift
SDKSpeechService.shared.speak(.selfieTts, in: .selfie)   // modül moduna göre, süreni böler
SDKSpeechService.shared.speak(text: "Serbest metin")     // native, doğrudan
SDKSpeechService.shared.speakAfterCurrent(.livenessSmileTts, in: .livenessDetection)
SDKSpeechService.shared.announce(.stayStill, in: .selfie)  // kısıtlı durum anonsu
SDKSpeechService.shared.stop()
SDKSpeechService.shared.isSpeaking                       // @Published — gözlemlenebilir
SDKSpeechService.shared.isAnnouncing                     // okunan şey durum anonsu mu?

// SwiftUI: ekran açıldığında rotanın metnini oku (SDK'nın kendi ekranlarının yaptığı)
MyView().speakOnAppear(.selfie)

// VM içinden (SDKBaseModuleViewModel uzantıları):
vm.speak(.selfieTts, in: .selfie)
vm.stopSpeech()
```

---

## 6) Akış Kontrolü

### `SDKFlowCoordinator` — tam public API

**Gözlemlenebilir state (`@Published`):**

| Property | Anlamı |
|---|---|
| `path: [SDKModuleRoute]` | Navigasyon yığını (login kök, path'te tutulmaz) |
| `navDirection` | `.forward` / `.back` — geçiş animasyonu yönü |
| `activeModule: SdkModules?` | Aktif SDK modülü |
| `progressStep` / `progressTotal` | Adım sayacı (progress bar için) |
| `sdkError: String?` | Soketten gelen hata |
| `subRejected: Bool` | Oturum reddedildi bayrağı |
| `showLostConnection: Bool` | Global bağlantı-koptu ekranı görünür mü |
| `moduleRestartToken: Int` | Artınca aktif modül view+VM'i yeniden yaratılır |
| `pendingThankYouStatus` | Görüşme sonucu için geçici statü |

**Metotlar:**

| Metot | Ne yapar |
|---|---|
| `prepareForSetup()` | **setupSDK'dan ÖNCE zorunlu** — placeholder controller'ları kaydeder |
| `start()` | setupSDK başarılı olunca — ilk modüle geçer |
| `advanceToNextModule()` | Sonraki modüle geç (backend sırasına göre) |
| `skipCurrentModule()` | Modülü atla (sunucuya bildirir) + ilerle |
| `appendModules(_:)` / `appendModules(moduleList:)` | Akışın devamına yeni SDK modülleri ekler (eski `addModules` kalıbının coordinator karşılığı; `progressTotal` otomatik güncellenir) |
| `popBack()` | Görsel + SDK imleci senkron geri gider |
| `resetFlow()` | Akışı tamamen sıfırlar (login'e döner) |
| `insert(_:before:)` / `insert(_:after:)` | Custom ekranları belirli rotanın önüne/arkasına planlar |
| `showExternalScreen(_:)` | Anlık custom ekran push eder (adım sayacı değişmez) |
| `advanceExternal()` | Custom ekranın "Devam"ı — kuyruktaki sonraki ekrana/modüle geçer |
| `pushThankYouDirectly(status:)` | Doğrudan ThankYou'ya git (statülü) |
| `restartCurrentModule()` | Reconnect sonrası aktif modülü baştan başlat |
| `dismissLostConnection()` | Bağlantı-koptu ekranını restart etmeden kapat |
| `restoreSocketListener()` | CallScreen'den dönüşte soket dinleyicisini geri al |

### `SDKFlowHostView` — kök view

```swift
SDKFlowHostView(coordinator: coordinator, registry: registry) { MyLoginView() }
```

Yaptıkları (hepsi otomatik):
- Path boşken kök (login) view'ınızı, doluysa en üstteki rotayı çizer (iOS 15 uyumlu, `NavigationStack` yok).
- İleri geçiş sağdan, geri geçiş soldan animasyonlu.
- Her rota için önce registry'ye bakar → override / custom / SDK default.
- `speakOnAppear` ile rota TTS'ini tetikler. Okuma ekranı **kilitlemez**; modül geçişinde kesilir.
- Global klavye tap-to-dismiss (yalnızca SDK akış ekranlarında; kök/login ekranınız ve kendi sheet'leriniz kendi klavye davranışını yönetir).
- Arka plana geçişi loglar + `app.background` olayını yayınlar.
- `.connectionErr` geldiğinde `SDKLostConnectionView`'ı fullscreen açar; reconnect başarısında aktif modülü yeniden başlatır.

### `SDKModuleRoute` — tüm rotalar

`.prepare` · `.selfie` · `.selfieWithLiveness` · `.idCard` · `.idCardOVD` · `.nfc` ·
`.liveness` · `.speech` · `.addressConfirm` · `.signature` · `.videoRecorder` ·
`.callScreen` · `.thankYou(ThankYouStatus?)` · `.custom(String)`

`ThankYouStatus`: `.completed` · `.missedCall` · `.notCompleted`

---

## 7) Ekran Değiştirme & Ekleme

### A) Tam ekran override — tasarım sizin, iş mantığı SDK'nın

```swift
let registry = SDKViewRegistry()
registry.override(.selfie) { MyCustomSelfieView() }    // artık selfie rotasında sizin view çizilir
```

Override ekranınız **SDK ViewModel'ini kullanmaya devam etmelidir** (bkz. bölüm 14):

```swift
struct MyCustomSelfieView: View {
    @EnvironmentObject var coordinator: SDKFlowCoordinator
    @StateObject private var vm = SDKSelfieViewModel()
    // vm.processSelfie(image:) → yüz tespiti + upload + adım sinyali SDK'da kalır
}
```

### B) Akışa custom ekran ekleme

```swift
registry.custom("welcome") { MyIntroView() }             // 1) ekranı tanımla
coordinator.insert(["welcome"], before: .selfie)         // 2) yerini söyle
coordinator.insert(["ara-basari"], after: .idCard)
Button("Devam") { coordinator.advanceExternal() }        // 3) ekranın Devam butonu:
coordinator.showExternalScreen("kvkk")                   // Anlık gösterim (sırayı bozmadan):
```

Custom ekranlar **pasiftir**: `moduleStepOrder` değişmez, soket etkilenmez — istediğiniz
kadar ekleyin.

### Hazır generic bilgi ekranı — `SDKExternalInfoView`

Kendi view yazmadan araya bilgi ekranı eklemek için:

```swift
registry.custom("onay") {
    SDKExternalInfoView(
        title: "Onay",
        subtitle: "Devam etmeden önce koşulları kabul edin.",
        systemIcon: "doc.text",           // SF Symbol (varsayılan: info.circle.fill)
        buttonTitle: "Devam Et"           // varsayılan: "Devam Et"
    )
}
coordinator.insert(["onay"], before: .selfie)
```

"Devam" butonu otomatik olarak `advanceExternal()` çağırır.

### C) Host VM composition — değiştirmeden gözlemleme

SDK ekranı kalsın ama analitik/log/kendi state'inizi eklemek istiyorsanız SDK VM'ini kendi
VM'inizle sarın (modül VM'leri `public final`'dır, subclass **edilemez** — bilinçli karar):

```swift
@MainActor final class SelfieHostViewModel: HostModuleViewModel {
    let sdk = SDKSelfieViewModel()
    override init() { super.init(); bridge(sdk) }        // objectWillChange köprüsü
    func process(_ img: UIImage) { log("selfie_scan"); sdk.processSelfie(image: img) }
}
```

---

## 8) Hazır Modül Ekranları

Her modülün View + ViewModel'i public'tir; override ederken VM'i yeniden kullanırsınız.
Modül bazlı VM API tabloları için [Modül Kataloğu](README.md#modül-kataloğu)ndaki
ilgili rehbere bakın.

| Rota | Default View | ViewModel | İşlev |
|---|---|---|---|
| `.prepare` | `SDKPrepareView` | `SDKPrepareViewModel` | İzinler + hazırlık kontrol listesi + hız testi |
| `.selfie` | `SDKSelfieView` | `SDKSelfieViewModel` | Selfie çekimi + yüz tespiti + upload |
| `.selfieWithLiveness` | `SDKSelfieWithLivenessView` | (controller) | Canlılıklı selfie |
| `.idCard` | `SDKIdCardView` | `SDKIdCardViewModel` | Belge türü seçimi + OCR tarama (kimlik/pasaport/diğer) |
| `.idCardOVD` | `SDKIdCardOVDView` | `SDKIdCardOVDViewModel` | Hologram (OVD) doğrulamalı kimlik tarama |
| `.nfc` | `SDKNfcView` | `SDKNfcViewModel` | MRZ girişi + NFC çip okuma |
| `.liveness` | `SDKLivenessView` | `SDKLivenessViewModel` | Canlılık adımları (ARKit) + video kaydı |
| `.speech` | `SDKSpeechRecView` | `SDKSpeechRecViewModel` | Konuşma tanıma (kelime söyleme) |
| `.addressConfirm` | `SDKAddressConfirmView` | `SDKAddressConfirmViewModel` | Adres belgesi (foto/PDF) yükleme |
| `.signature` | `SDKSignatureView` | `SDKSignatureViewModel` | İmza çizimi + upload |
| `.videoRecorder` | `SDKVideoRecorderView` | `SDKVideoRecorderViewModel` | Video kaydı (+ sesli okuma doğrulaması) |
| `.callScreen` | `SDKCallScreenView` | `SDKCallScreenViewModel` | WebRTC görüntülü görüşme + bekleme odası |
| `.thankYou` | `SDKThankYouView` | `SDKThankYouViewModel` | Sonuç ekranı (statülü/statüsüz) |
| (global) | `SDKLostConnectionView` | `SDKLostConnectionViewModel` | Bağlantı koptu + reconnect |
| (görüşme içi) | `SDKSignLangView` | `SDKSignLangViewModel` | İşaret dili tercümanı |

> Kimlik/pasaport tarama motorunu (IdentityScanner) akıştan bağımsız da kullanabilirsiniz —
> profiller, alan OCR'ı, TCKN/MRZ doğrulama: [IdentityScanner Rehberi](docs/guides/identity-scanner.md).
> Tarayıcı HUD metinleri de lokalizasyon sisteminden geçer (`scanner*` key'leri, bölüm 4).

---

## 9) Ortak UI Bileşenleri

Hepsi public — custom ekranlarınızda kullanarak SDK görünümüyle bütünlük sağlarsınız.
Hepsi tema token'larından beslenir → temanızı otomatik takip eder.

### `SDKButton`

```swift
SDKButton(title: "Devam", style: .primary, isLoading: vm.isLoading, isDisabled: !vm.canContinue) { ... }
```

| Stil | Zemin | Metin |
|---|---|---|
| `.primary` | `IDColor.primary` | beyaz |
| `.cancel` | `IDColor.error` | beyaz |
| `.secondary` | adaptif yüzey | adaptif başlık rengi |
| `.success` | `IDColor.successBright` | beyaz |

Kapsül şekilli; basılınca hafif küçülme animasyonu + haptic feedback; `isLoading` spinner
gösterir; `isDisabled` %45 opaklık + tıklanamaz.

### `SDKNavigationBar`

```swift
SDKNavigationBar(style: .progress(steps: coordinator.progressTotal, current: coordinator.progressStep),
                 title: "Kimlik Doğrulama", subtitle: "Adım 2",
                 onBack: { coordinator.popBack() })
```

| Stil | Görünüm |
|---|---|
| `.login` | Hamburger + logo + trailing slot |
| `.module` | Geri + langButton logosu + başlık/alt başlık + trailing |
| `.progress(steps:current:)` | Modül barı + adım şeridi (beyaz — renkli zemin üstü) |
| `.progressClear(steps:current:)` | Aynısı, tema renkleriyle (açık zemin üstü) |
| `.overlay` | Kamera üstü: yarı saydam geri/yardım + gradyan |

Slotlar: `onBack`, `onMenu`, `onHelp` closure'ları, `trailing: AnyView?`.
İkonları `.back` / `.hamburger` / `.logo` / `.langButton` / `.help` anahtarlarından alır.

### `IDAlertView` — SDK stili alert

```swift
// Model ile:
.idAlert(item: $alertModel)
// Bool ile:
.idAlert(isPresented: $showAlert, alert: IDAlertModel(type: .info, title: "...", message: "...",
                                                      actions: [IDAlertAction(title: "Tamam")]))
// errorMessage binding'ini otomatik hata alert'ine bağla:
.idErrorAlert($vm.errorMessage)
```

Tipler: `.normal` · `.error` · `.info` · `.success` (ikon + vurgu rengi otomatik).
Aksiyon stilleri: `.primary` · `.cancel` · `.destructive`.

### Diğer yardımcılar

| API | Erişim | İşlev |
|---|---|---|
| `Image.sdk(.camera)` | public | Aktif temadaki ikonu çizer (host override'ı otomatik uygular) |
| `SDKPreviewGallery` | public | Tüm SDK ekranlarının Xcode Preview kataloğu (geliştirme yardımı) |
| `.successBanner(_:isVisible:)` | internal | Üstten kayan başarı bandı — SDK ekranları içinde kullanılır, host çağıramaz |
| `.dismissKeyboardOnTap()` | internal | SDK akışında global klavye kapatma — `SDKFlowHostView` otomatik uygular; kendi login/sheet'lerinizde kendi jestinizi kurun |

---

## 10) `setupSDK` Konfigürasyonu

### Tüm parametreler

```swift
IdentifyManager.shared.setupSDK(
    identId: String,                        // zorunlu — doğrulama oturumu ID'si
    baseApiUrl: String,                     // zorunlu — backend URL
    networkOptions: SDKNetworkOptions,      // zorunlu — timeout + SSL pinning
    kpsData: SDKKpsData?,                   // opsiyonel — NFC/MRZ ön-doldurma (birthDate, validDate, serialNo)
    identCardType: [CardType]?,             // varsayılan [.idCard, .passport, .oldSchool]
    signLangSupport: Bool,                  // işaret dili tercümanı desteği
    nfcMaxErrorCount: Int,                  // NFC deneme hakkı
    logLevel: SDKLogLevel?,                 // varsayılan .all — bkz. Loglama
    logOnlineSecretKey: String?,            // online log şifreleme anahtarı
    bigCustomerCam: Bool?,                  // görüşmede büyük müşteri kamerası (vars. false)
    selectedModules: [SdkModules],          // vars. [] — backend sırası kullanılır
    idCardLang: IDLang?,                    // OCR belge dili: .TR / .AZ / .OTHER (vars. .TR)
    needCertForNfc: Bool?,                  // NFC sertifika (CSCA) doğrulaması (vars. false)
    turnKey: String,                        // zorunlu — TURN kimlik üretim anahtarı
    wsSecretKey: String?,                   // WebSocket token anahtarı
    showThankYouPage: Bool?,                // akış sonunda ThankYou göster (vars. false)
    showNFCNotFoundPage: Bool?,             // NFC yoksa bilgi sayfası (vars. false)
    supportU18: Bool?,                      // 18 yaş altı desteği (vars. false)
    AESKey: String?,                        // AES şifreleme anahtarı
    enableAutoRotateOCR: Bool?,             // OCR otomatik oryantasyon düzeltme (vars. false)
    ttsEnabled: Bool?,                      // sesli okumayı native modda aç (vars. false)
    callback: (WebSocket?, RoomResponse, SDKWebError?) -> ()
)
```

Parametrelerin sunucu tarafı ayrıntıları: [Sunucu & API Rehberi](docs/guides/server-api.md).

### `SDKNetworkOptions`

```swift
let options = SDKNetworkOptions(
    timeoutIntervalForRequest: 30,          // saniye (varsayılan 30)
    timeoutIntervalForResource: 30,
    useSslPinning: true,                    // varsayılan false
    sslPinningBundles: [Bundle(for: MyToken.self)]   // .cer aranacak EK bundle'lar
)
```

SSL pinning açıkken `.cer` arama sırası: **custom bundle'lar → SDK bundle → main bundle**.

### Dil

```swift
IdentifyManager.shared.setSDKLang(lang: .tr)    // .tr / .eng / .de / .az / .ru
```

### Belge türleri — `CardType`

`.idCard` (çipli kimlik) · `.passport` (pasaport) · `.oldSchool` (eski tip/diğer belgeler).
`identCardType`'a verdiğiniz liste, kimlik ekranındaki tür seçim satırlarını belirler.

---

## 11) Olay Akışı

### Yeni birleşik sistem — `eventDelegate` (önerilen)

```swift
final class MyAnalytics: SDKEventListener {
    func onSDKEvent(_ event: SDKEvent) {
        // event.name       — "module.presented", "app.background", "call.ended"...
        // event.category   — .navigation / .network / .media / .verification / .call / .lifecycle...
        // event.status     — .info / .success / .failure / .warning
        // event.module     — "selfie", "nfc"...
        // event.sessionId, event.timestampMs, event.message, event.metadata [String:String]
        // event.toDictionary() / event.toJSONString() — RN/Flutter köprüsü için hazır
    }
}
IdentifyManager.shared.eventDelegate = myAnalytics    // weak tutulur — referansı siz saklayın
```

### Eski sistem — `trackingDelegate` (geriye uyum)

```swift
IdentifyManager.shared.trackingDelegate = self   // IdentifyTrackingListener.eventReceived(event:)
```

İkisi bağımsızdır, aynı anda kullanılabilir. Kategori/isim envanteri ve RN/Flutter köprü
örnekleri: [Event Sistemi Rehberi](docs/guides/events.md).

---

## 12) Loglama

### Seviye — `setupSDK(logLevel:)`

| Seviye | Konsol | Backend |
|---|---|---|
| `.all` | ✅ | ❌ (geliştirme) |
| `.online` | ✅ | ✅ (debug + izleme) |
| `.onlineSilent` | ❌ | ✅ (prod — gürültüsüz) |
| `.noLog` | ❌ | ❌ |

### `SDKLog` facade'i — kendi kodunuzda da kullanabilirsiniz

```swift
SDKLog.debug("...", .network)
SDKLog.info("...", .lifecycle)
SDKLog.warning("...", .socket)
SDKLog.error("...", .media)
```

Severity sıralı ve karşılaştırılabilir; kategoriler (`SDKLogCategory`) socket/network/
media/lifecycle vb. akışları ayrıştırır. Base64 gibi hassas içerikler otomatik redakte
edilir. Ayrıntı: [Loglama Rehberi](docs/guides/logging.md).

---

## 13) Global Bağlantı Kopması Katmanı

Kutudan çıktığı gibi çalışır — kurulum gerekmez:

- Reachability veya soket kopması → SDK `.connectionErr` yayınlar → `SDKFlowHostView`
  hangi modülde olursanız olun `SDKLostConnectionView`'ı fullscreen açar.
- Reconnect başarılı → `coordinator.restartCurrentModule()` — aktif modül **temiz state**
  ile yeniden yaratılır (kamera yeniden başlar); adım sayacı değişmez, sunucu konumu korunur.
- CallScreen kendi in-call reconnect'ini yönetir (çifte sunum olmaz).

Özelleştirme noktaları:
- Görsel: `.lostConnection` ikonu + `connectionLostTitle` / `connectionLostDesc` /
  `coreReConnect` metin key'leri.
- Davranış: `coordinator.dismissLostConnection()` (restart etmeden kapatma),
  `moduleRestartToken` gözlemi.

---

## 14) "Bypass Yok" Kuralı

Custom ekran yazarken her iş eylemini — **tara, yükle, ilerle** — SDK VM metoduna
indirin. Her VM metodu işin yanında backend'e ilerleme sinyali (`sendStep`,
`modulePresented`) gönderir; kendi HTTP/navigasyonunuzu kurarsanız görüntü aynı olur ama
sunucu akışı ilerlemez — agent panelinde müşteri "takılı" görünür.

| ✅ Doğru | ❌ Bypass |
|---|---|
| `vm.scanFront(image:)` | Kendi OCR'ınız + kendi `POST`'unuz |
| `coordinator.advanceToNextModule()` | `path.append(...)` ile kendi geçişiniz |
| `vm.uploadSignature(image:)` | Görseli kendiniz yüklemek |
| `coordinator.skipCurrentModule()` | Modülü sessizce atlamak |

Pasif ekranlar (bölüm 7-B) kuralın dışındadır — zaten VM metodu çağırmazlar.

### Yayın öncesi kontrol listesi

- [ ] Tüm tema/dil/TTS ayarları `setupSDK`'dan **önce** yapılıyor
- [ ] `coordinator.prepareForSetup()` `setupSDK`'dan önce çağrılıyor
- [ ] Custom ekranlar iş eylemlerinde yalnızca SDK VM metotlarını çağırıyor
- [ ] Geçişler `coordinator` üzerinden (`advanceToNextModule` / `advanceExternal` / `skipCurrentModule`)
- [ ] `vm.errorMessage` ve `vm.isLoading` kullanıcıya yansıtılıyor (`.idErrorAlert` hazır)
- [ ] Custom fontun **PostScript family adı** doğrulandı (Font Book)
- [ ] Klavye içeren kendi sheet/login ekranlarınızda klavye kapatma davranışı kuruldu (SDK'nın global jesti yalnızca akış ekranlarını kapsar)
- [ ] Tema, Showcase kataloğunda (`Showcase/ShowcaseCatalog.swift`) her ekranda kontrol edildi
- [ ] Gerçek cihazda uçtan uca akış koşturuldu (NFC/görüşme simülatörde çalışmaz)

---

## 15) Navigasyon Sahipliği

Entegrasyonda en çok sorulan soru: **"SDK ekranları bizim uygulamada sheet ile mi devam
eder, yoksa push ile navigasyonu kendisi mi devralır?"**

Kısa cevap: **İkisi de değil. SDK navigasyonunuzu DEVRALMAZ; kabı siz seçersiniz.**

### SDK'nın yapmadıkları (garanti)

| Mekanizma | SDK kullanır mı? | Açıklama |
|---|---|---|
| `UIWindow` oluşturma / `makeKeyAndVisible` | ❌ **Asla** | SDK kaynak kodunda tek bir `UIWindow`/`makeKeyAndVisible` çağrısı yoktur. Key window'unuza, scene'inize dokunmaz. |
| `UINavigationController.push` | ❌ | Host'un navigation stack'ine hiçbir şey push etmez. |
| Kendi `NavigationStack` / `NavigationView`'ı | ❌ | `SDKFlowHostView` gerçek bir navigation stack kurmaz (iOS 15 uyumu). |
| Host'a `sheet` / `fullScreenCover` açma | ❌ | Sizin hiyerarşinize modal sunum yapmaz. |

### Peki ekran geçişleri nasıl oluyor?

`SDKFlowHostView` içeride **ZStack tabanlı bir sahte-stack** çizer:

- `coordinator.path` (bir `[SDKModuleRoute]` dizisi) neredeyse bir navigation path gibi
  davranır ama gerçek push yoktur — **her zaman yalnızca en üstteki rota çizilir**
  (`path.last`), altta view hiyerarşisi birikmez.
- İleri geçiş: yeni ekran **sağdan** girer, eski sola çıkar (`.move(edge:)` transition,
  0.25 s easeInOut). Geri (`popBack`): soldan girer. Yani kullanıcı deneyimi push/pop
  gibi hissettirir; teknik olarak aynı kapta içerik değişimidir.
- Sistem nav bar'ı kullanılmaz; her modül kendi `SDKNavigationBar`'ını çizer ve
  `navigationBarBackButtonHidden(true)` uygular.

SDK'nın kendi **içinde** kullandığı tek modal sunumlar, yine `SDKFlowHostView`
hiyerarşisinin içindedir ve sizin navigasyonunuza taşmaz:

- Global bağlantı-koptu ekranı (`fullScreenCover`, bölüm 13),
- CallScreen'in işaret dili overlay'i,
- bazı modüllerin kendi sheet'leri (ör. sesli doğrulama retry sheet'i),
- IdentityScanner'ın `documentScanner` modifier'ı (bölüm 16 — bunu siz kendi
  view'ınıza takarsınız; `fullScreenCover` olarak açılır).

### Kabı siz seçersiniz — üç geçerli yerleşim

`SDKFlowHostView` sıradan bir SwiftUI `View`'dır; nereye koyarsanız orada yaşar:

```swift
// A) ROOT SWAP (Sample App'in yaptığı — önerilen):
// Uygulamanın kökü doğrudan host view; login de onun root'u.
@main struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            SDKFlowHostView(coordinator: coordinator, registry: registry) {
                LoginView()                       // path boşken görünen kök
            }
        }
    }
}

// B) FULLSCREEN COVER (mevcut uygulamanıza "KYC başlat" butonu ekliyorsanız):
.fullScreenCover(isPresented: $startKyc) {
    SDKFlowHostView(coordinator: coordinator, registry: registry) {
        KycEntryView()                            // ya da doğrudan ilk ekran
    }
}
// Kamera/tam ekran modüller olduğu için fullScreenCover önerilir; teknik olarak
// .sheet içinde de çalışır ama kamera ekranlarının yarım-yükseklik sheet'te
// sunulması kullanıcı deneyimi olarak yanlıştır.

// C) UIKIT HOST (UIKit tabanlı uygulama):
let host = UIHostingController(
    rootView: SDKFlowHostView(coordinator: coordinator, registry: registry) { EmptyView() }
)
host.modalPresentationStyle = .fullScreen
present(host, animated: true)                    // modal öneririz
// navigationController?.pushViewController(host, animated: true) da çalışır;
// SDK sistem nav bar'ını kendisi gizlediği için push'ta bar çakışması olmaz.
// Ayrı bir UIWindow açmanıza (makeKeyAndVisible) GEREK YOKTUR; isterseniz
// kendi kararınızla açabilirsiniz — SDK için fark etmez.
```

### Pasif (custom) ekranlar nasıl "push"lanır?

Bölüm 7-B'deki custom ekranlar da **aynı iç sahte-stack'e** girer; host navigasyonuna
dokunulmaz:

1. `registry.custom("kvkk") { KvkkView() }` — ekranı id ile kaydedersiniz.
2. `coordinator.insert(["kvkk"], before: .selfie)` — koordinatör, selfie rotası push
   edilmeden hemen önce kuyruğa `.custom("kvkk")` rotasını sokar; `SDKFlowHostView`
   en üstteki rota olarak sizin view'ınızı çizer (sağdan-giriş animasyonuyla).
3. `coordinator.showExternalScreen("kvkk")` — anlık gösterim: `.custom("kvkk")` rotası
   doğrudan path'e eklenir (yine iç stack; sheet DEĞİL).
4. Ekranınız `@EnvironmentObject var coordinator: SDKFlowCoordinator` alır (host view
   otomatik enjekte eder) ve "Devam" butonunda `coordinator.advanceExternal()` çağırır —
   kuyrukta başka custom varsa o, yoksa bekleyen gerçek SDK modülü gösterilir.
5. Geri: `coordinator.popBack()` — custom rotalar `moduleStepOrder` imlecini
   İLERLETMEDİĞİ için geri sarımda sunucu imleci bozulmaz.

**Birden fazla ekran (2× before ve fazlası):** `insert` bir **dizi** alır ve sıra
korunur; aynı rotaya ikinci bir `insert` çağrısı da kuyruğun sonuna ekler (ezmez):

```swift
registry.custom("nfcIntro1") { NfcIntroStep1View() }
registry.custom("nfcIntro2") { NfcIntroStep2View() }
coordinator.insert(["nfcIntro1", "nfcIntro2"], before: .nfc)
// Akış: ... → nfcIntro1 → nfcIntro2 → NFC
// Her ekranın "Devam"ı advanceExternal() — kuyruğu coordinator yönetir, sayaç tutmazsınız.
```

Aynı geçişte hem önceki modülün `after` ekranları hem sonraki modülün `before`
ekranları varsa kuyruk **after'lar önce, before'lar sonra** birleşir:

```swift
coordinator.insert(["idCardOzet"], after: .idCard)
coordinator.insert(["nfcIntro1", "nfcIntro2"], before: .nfc)
// Kimlik bitince: idCardOzet → nfcIntro1 → nfcIntro2 → NFC
```

> Dikkat: `insert` kayıtları rota bazlıdır ve **birikir**. Coordinator'ı her akış
> girişinde sıfırdan kurduğunuz sürece (bölüm 17.5) sorun olmaz; aynı coordinator'ı
> ikinci kez `start()` ederseniz ekranlar çiftlenir.

Özet: **custom ekranınız da sheet ile değil, akışın içinde "push benzeri" geçişle
gösterilir.** Kendi sheet'inizi custom ekranınızın İÇİNDEN açmakta özgürsünüz
(o sizin hiyerarşiniz).

### Görüşme bitişi (terminate call) ve KENDİ sonuç ekranlarınız

En kritik devir-teslim anı görüşmenin bitişidir. Önce SDK'nın ne yaptığını bilin —
görüşme üç yoldan biter ve **hepsi `.thankYou(status)` rotasında toplanır**:

| Tetikleyici | Socket/aksiyon | Sonuç statüsü |
|---|---|---|
| Temsilci görüşmeyi sonuçlandırır | `.terminateCall(reason, statusType)` / `.endCall` | `statusType == "positive"` → `.completed`, değilse → `.notCompleted` |
| Kullanıcı "Görüşmeyi bitir"e basar | `vm.terminateCall(coordinator:)` → `terminateCallByUser` | `.notCompleted` |
| Çağrı cevaplanmaz | `.missedCall` | `.missedCall` |

Yani başarı/başarısızlık kararı **sunucudan gelir**; SDK bu statüyü rotaya gömüp kendi
`SDKThankYouView(status:)` ekranını çizer. O ekranın "Tamam" butonu
`coordinator.resetFlow()` çağırır → akış köke (login/root'unuza) döner.

Kendi başarı/başarısız ekranlarınızı kullanmanın **iki yolu** var:

**Yol 1 — ThankYou'yu override edin (akışın içinde kalır):**

`.thankYou` rotası statüyü **associated value** olarak taşır ve registry eşleşmesi
birebir Hashable eşleşmesidir. Bu yüzden tek bir `override(.thankYou(nil))` yetmez —
**dört varyantı ayrı ayrı** kaydedin:

```swift
registry.override(.thankYou(.completed))    { MySuccessView() }     // görüşme pozitif
registry.override(.thankYou(.notCompleted)) { MyFailureView() }     // negatif / kullanıcı bitirdi
registry.override(.thankYou(.missedCall))   { MyMissedCallView() }  // cevapsız çağrı
registry.override(.thankYou(nil))           { MySuccessView() }     // görüşmesiz akış sonu
```

Her varyant ayrı kayıt olduğundan statüyü ekranınıza parametre geçmenize gerek yok —
hangi closure çalıştıysa sonuç odur. Ekranınızın kapanış butonu SDK'nınkiyle aynı işi
yapmalı:

```swift
struct MySuccessView: View {
    @EnvironmentObject var coordinator: SDKFlowCoordinator
    var body: some View {
        VStack { ... }                                   // tamamen sizin tasarımınız
        Button("Ana Sayfaya Dön") {
            coordinator.resetFlow()                      // akışı köke döndürür
            // fullScreenCover'daysanız burada ayrıca kapatın: isPresented = false
        }
    }
}
```

**Yol 2 — SDK kabını tamamen kapatıp kendi native ekranınıza geçin:**

ThankYou'yu hiç göstermek istemiyorsanız, akış sonunu dinleyip SDK'yı barındıran kabı
(fullScreenCover / modal VC) kapatın ve kendi navigasyonunuzda devam edin:

```swift
// a) Olay akışıyla (önerilen — statü bilgisi hazır gelir):
final class MyEvents: SDKEventListener {
    func onSDKEvent(_ event: SDKEvent) {
        switch event.name {
        case "session.completed":  router.show(.kycSuccess)   // SDK kabını kapat + kendi ekranın
        case "session.failed":     router.show(.kycFailure)
        case "session.abandoned":  router.show(.kycAbandoned) // metadata.lastScreen = nerede bıraktı
        default: break
        }
    }
}
IdentifyManager.shared.eventDelegate = myEvents   // setupSDK'dan ÖNCE

// b) Veya coordinator'ı gözleyerek (SwiftUI):
.onChange(of: coordinator.path) { path in
    if case .thankYou(let status) = path.last {
        showKyc = false                            // fullScreenCover'ı kapat
        myResultRoute = (status == .completed) ? .success : .failure
    }
}
```

> İkisini karıştırmayın: Yol 1'de akış SDK kabının içinde biter (resetFlow köke döner);
> Yol 2'de kabı siz kapatırsınız. Yol 2'de bile `.thankYou` rotası bir an çizilebilir —
> istemiyorsanız dört varyantı boş/geçiş view'ı ile override edip kapanışı oradan
> tetikleyin (Yol 1 + kapatma).

> "Bypass yok" hatırlatması: görüşmeyi kendiniz bitirmek istiyorsanız bunun tek doğru
> yolu `SDKCallScreenViewModel.terminateCall(coordinator:)`'dır — sunucuya
> `terminateCallByUser` sinyalini o gönderir. Kabı görüşme SÜRERKEN sessizce kapatmak,
> temsilci tarafında müşteriyi "takılı" bırakır.

---

## 16) IdentityScanner — Detaylı İmplementasyon

Gerçek zamanlı belge tarama motoru (`IdentityScanner/`), KYC akışından **bağımsız**
kullanılabilir: kamera + dikdörtgen tespiti + bölgesel OCR + alan doğrulama + otomatik
yakalama. Kavramsal anlatım için [IdentityScanner Rehberi](docs/guides/identity-scanner.md);
burada uçtan uca implementasyon var.

### 16.1 En kısa kullanım — `documentScanner` modifier'ı

Kendi view'ınıza takarsınız; scanner `fullScreenCover` olarak açılır, sonuç closure'a düşer:

```swift
struct MyKycStep: View {
    @State private var scanning = false
    @State private var result: RecognizedDocument?

    var body: some View {
        Button("Kimliği Tara") { scanning = true }
            .documentScanner(
                isPresented: $scanning,
                profile: .turkishIDFront,            // hangi belge (16.3)
                style: .default,                     // çerçeve görünümü (16.5)
                configuration: .default              // HUD metinleri + zamanlama (16.4)
            ) { outcome in
                switch outcome {
                case .success(let doc):  result = doc          // 16.6: alanlar burada
                case .failure(let err):  handle(err)           // 16.7: hata türleri
                }
            }
    }
}
```

İkinci overload ile scanner'ın üstüne kendi nav bar'ınızı koyabilirsiniz:

```swift
.documentScanner(isPresented: $scanning, profile: .turkishIDFront,
                 externalTorchOn: $torchOn,                    // fener kontrolü sizde
                 onTorchAvailability: { available in torchSupported = available },
                 navOverlay: {
                     SDKNavigationBar(style: .overlay, onBack: { scanning = false })
                 },
                 onResult: { outcome in ... })
```

- `externalTorchOn` verirseniz scanner'ın kendi fener butonu gizlenir; binding'i siz sürersiniz.
- Tam kontrol isterseniz `IdentityScannerView(profile:style:configuration:onResult:)`'ı
  modifier olmadan istediğiniz yerde kendiniz sunabilirsiniz (o da sıradan bir View'dır).

### 16.2 Gereksinimler

- iOS 15+, gerçek cihaz (simülatörde kamera yok).
- `Info.plist` → `NSCameraUsageDescription` zorunlu.
- Kamera izni reddedilmişse sonuç `.failure(ScanningError.cameraPermissionDenied)` döner —
  ayarlara yönlendirme sizin sorumluluğunuz.

### 16.3 Hazır profiller — `DocumentProfile`

Profil = "hangi belgeyi, hangi stratejiyle, hangi alanları okuyarak tarıyorum" tanımı.

| Profil | id | Strateji | Alanlar |
|---|---|---|---|
| `.generic` | `generic` | `imageOnly` | Yok — sadece düzeltilmiş görüntü |
| `.turkishIDFront` | `tr.id.front` | `visionText` | `tckn`, `surname`, `givenNames`, `birthDate`, `documentNumber`, `expirationDate` |
| `.turkishIDBack` | `tr.id.back` | `visionText` | MRZ satırları |
| `.turkishID` | — | `visionText` | Ön/arka ayrımı olmayan genel TC kimlik |
| `.passport` | — | `visionText` | Pasaport veri sayfası (TD3 MRZ) + yana-çevir yönlendirmesi |
| `.turkishDrivingLicense` | — | `visionText` | Ehliyet alanları |
| `.bankCard` | — | — | Banka kartı |
| `.a4Document` | — | `imageOnly` | A4 belge (fatura/adres belgesi) |

Her `visionText` profili bir `DocumentKeywordSet` ile **keyword gating** yapar: kadraja
yanlış belge girerse (ör. ehliyet yerine kimlik) kilitlenmez.

### 16.4 Konfigürasyon — `ScannerConfiguration`

İki parça: `texts` (HUD metinleri) + `timing` (yakalama davranışı). Üç hazır preset:
`.default` (kimlik), `.passport`, `.document` (A4/fatura — daha muhafazakâr zamanlama).

**Tek taramalık özelleştirme:**

```swift
var config = ScannerConfiguration.document
config.texts.idle = "Faturanızı çerçeveye yerleştirin"
config.timing.lockThreshold = 12          // daha temkinli kilitlenme
.documentScanner(isPresented: $s, profile: .a4Document, configuration: config) { ... }
```

**Global özelleştirme (uygulama açılışında bir kez):**

```swift
// Metinler zaten SDKLocalization'dan gelir (aktif dile uyar). Komple değiştirmek için:
ScannerGuidanceTexts.overrideDefault  = ScannerGuidanceTexts(idle: "...", focusing: "...", ...)
ScannerGuidanceTexts.overridePassport = ...   // pasaport HUD seti
ScannerGuidanceTexts.overrideDocument = ...   // belge HUD seti
// Veya tüm konfigürasyonu:
ScannerConfiguration.overrideDefault = ScannerConfiguration(texts: myTexts, timing: myTiming)
```

> Metinleri tek tek markalamak yerine dil sistemini kullanmak genelde yeterlidir:
> HUD, `scanner*` lokalizasyon key'lerinden beslenir → `SDKLocalization.setOverride`
> ile dil bazında değiştirebilirsiniz (bölüm 4).

**Önemli `ScannerTimingConfig` düğmeleri** (tamamı için kaynak yorumları çok ayrıntılıdır):

| Alan | Varsayılan (id / belge) | Ne işe yarar |
|---|---|---|
| `lockThreshold` | 5 / 9 | Otomatik yakalama için üst üste stabil OCR karesi sayısı (~0.5 s/kare) |
| `stabilityConfirmFrames` | 4 / 3 | Hızlı yol: keskin + geometrik stabil ardışık kare sayısı |
| `minimumSharpnessScore` | 120 / 110 | Canlı kare keskinlik eşiği (Laplacian; 0 = kapalı) |
| `captureSharpnessFloor` | 95 / 85 | Çekilen NİHAİ fotoğrafın keskinlik tabanı — altındaysa çekim atılır |
| `focusSettleDelay` | 0.5 / 1.2 | Odak sonrası bekleme (bulanık çekim şikayetinde artırın) |
| `quadMissResetThreshold` | 3 / 5 | Kaç kare belge kaybolursa ilerleme sıfırlanır (titreme önleyici) |
| `manualCaptureHintDelay` | 5 s / 8 s | Manuel çekim butonunun görünme süresi |
| `maxAutoCaptureFails` | 3 | Bu kadar başarısız otomatik denemeden sonra zorunlu manuel mod |
| `lensSwitchStruggleDelay` | 3.5–4 s | Ultra-geniş lense geçmeden önceki "odaklanamıyorum" süresi |

### 16.5 Çerçeve görünümü — `QuadrilateralStyle`

Tespit edilen belge çerçevesinin görselini markalarsınız:

```swift
let style = QuadrilateralStyle(
    strokeColor: .white,                    // tarama sırasında
    lockedStrokeColor: IDColor.success,     // kilitlenince
    lineWidth: 3,
    dashPattern: [8, 6],
    cornerStyle: .square                    // .square / .none / .custom { corner, isLocked in AnyView(...) }
)
.documentScanner(isPresented: $s, profile: .turkishIDFront, style: style) { ... }
```

### 16.6 Sonuç — `RecognizedDocument`

```swift
case .success(let doc):
    doc.croppedImage                        // perspektif-düzeltilmiş belge fotoğrafı
    doc.rawText                             // OCR ham metni
    doc.profileID                           // hangi profille tarandı
    doc.isValid                             // tüm doğrulamalar geçti mi
    doc.validationResults                   // tek tek doğrulama sonuçları

    // Alanlar (profile göre):
    if let tckn = doc.fields["tckn"] {
        tckn.value                          // "12345678901"
        tckn.confidence                     // Vision güven skoru (0–1)
    }
    let birth = doc.fields["birthDate"]?.value      // "01.01.1990"
    let docNo = doc.fields["documentNumber"]?.value // "A12B34567"
```

TCKN checksum ve MRZ check-digit doğrulamaları (`MRZValidator`) otomatik koşar;
`doc.isValid == false` ise hangi kuralın kırıldığı `validationResults`'tadır.

### 16.7 Hatalar — `ScanningError`

| Case | Ne zaman |
|---|---|
| `.cancelled` | Kullanıcı "İptal"e bastı |
| `.cameraPermissionDenied` | Kamera izni reddedilmiş |
| `.cameraUnavailable` | Cihazda kamera yok (simülatör) |
| `.recognitionFailed(String)` | OCR/tespit hatası |
| `.profileNotFound(String)` | Registry'de olmayan profil id'si |
| `.timeout` | Süre aşımı |

### 16.8 Kendi belge profilinizi tanımlama

`DocumentProfile` `Codable`'dır — kodla ya da JSON'dan kurabilirsiniz:

```swift
let sigorta = DocumentProfile(
    id: "tr.insurance.card",
    displayName: "Sigorta Kartı",
    strategy: .visionText,
    fields: [
        FieldDescriptor(key: "policyNo",
                        pattern: #"\bP\d{9}\b"#,
                        valueType: .number,
                        isRequired: true,
                        // Normalize koordinatlar (0–1): belgenin sağ üst çeyreği
                        regionOfInterest: FieldRegion(x: 0.55, y: 0.10, width: 0.40, height: 0.15)),
        FieldDescriptor(key: "holder",
                        pattern: #"[A-ZÇĞİÖŞÜ]{2,}(?:\s+[A-ZÇĞİÖŞÜ]{2,})*"#,
                        valueType: .text, isRequired: true, regionOfInterest: nil),
    ],
    keywordSet: DocumentKeywordSet(keywords: [
        DocumentKeyword(variants: ["SİGORTA", "SIGORTA"]),          // OCR varyantlarıyla
        DocumentKeyword(variants: ["POLİÇE", "POLICE"], weight: 1.5),
    ], minimumScore: 0.2)
)

// (Opsiyonel) merkezi kayıt — id ile erişmek isterseniz:
await DocumentProfileRegistry.shared.register(sigorta)

// Kullanım — doğrudan verin:
.documentScanner(isPresented: $s, profile: sigorta, configuration: .document) { ... }
```

- `regionOfInterest` verilen alanlar yalnızca o bölgedeki OCR metniyle eşleştirilir
  (yanlış alan yakalamayı ciddi azaltır). Bölge yoksa tüm metinde aranır.
- `isRequired: true` alanların TAMAMI çıkarılamadan otomatik yakalama tetiklenmez.
- `keywordSet`: belge üzerinde bulunması beklenen kelimeler; `minimumScore` altında
  kalan kareler "yanlış belge" sayılır ve kilitlenmez.

### 16.9 Kendi doğrulayıcınız — `DocumentValidator`

```swift
struct PolicyNoValidator: DocumentValidator {
    let key = "policyNo"
    func validate(_ document: inout RecognizedDocument) -> [ValidationResult] {
        guard let v = document.fields["policyNo"]?.value else { return [] }
        let ok = v.hasPrefix("P") && v.count == 10
        return [ValidationResult(field: key, passed: ok,
                                 message: ok ? nil : "Poliçe no biçimi geçersiz")]
    }
}
await DocumentValidatorRegistry.shared.register(PolicyNoValidator())
```

Kayıtlı tüm doğrulayıcılar her başarılı taramada koşar ve sonuçları
`doc.validationResults`'a eklenir (`doc.isValid` bunlara göre hesaplanır).

### 16.10 KYC akışıyla ilişkisi

- SDK'nın kendi kimlik/pasaport modülleri (`SDKIdCardView` vb.) bu motoru zaten içeride
  kullanır — akış içindeyseniz ekstra bir şey yapmanız gerekmez.
- Bağımsız kullanım (bu bölüm) hiçbir soket/adım sinyali GÖNDERMEZ — "bypass yok"
  kuralı (bölüm 14) ihlal edilmez çünkü akışın parçası değildir. Taradığınız veriyi
  KYC oturumuna işlemek istiyorsanız yine ilgili modül VM metodunu kullanın.

---

## 17) Çoklu İş Senaryosu

Gerçek entegrasyonlarda KYC altyapısı tek bir amaç için kullanılmaz. Aynı uygulama
içinde birden çok iş akışı aynı SDK'dan geçer: yeni müşteri kaydı, periyodik yeniden
doğrulama, limit artırımı, cihaz değişikliği, adres güncelleme... **Her akışın başlığı,
ekran seti, ara ekranları ve sonuç davranışı farklıdır — ama SDK kurulumu tektir.**

Önerilen kalıp: host tarafında bir **senaryo bağlamı** (enum) tanımlayın, akışa girerken
BİR KEZ set edin, SDK'ya dokunan her kararı bu bağlamdan türetin.

### 17.1 Senaryo bağlamı

```swift
/// Uygulamadaki tüm KYC'li iş akışları. Akışa girerken bir kez set edilir.
enum KycScenario {
    case onboarding          // yeni müşteri — tam KYC + görüşme
    case reKyc               // periyodik yeniden doğrulama — kısaltılmış akış
    case limitIncrease       // limit artırımı — kimlik + canlılık yeter
    case deviceChange        // yeni cihaz onayı — selfie + NFC
    case addressUpdate       // adres güncelleme — adres belgesi + kimlik

    /// SDK dil sistemiyle çözülen başlık/alt başlık (5 dil desteği ile gelir —
    /// key'leri registerOverrides ile siz eklersiniz, bkz. bölüm 4).
    var title: String    { SDKLocalization.shared.string(forKey: titleKey) }
    var subtitle: String { SDKLocalization.shared.string(forKey: "RemoteVerifySubtitle") }

    private var titleKey: String {
        switch self {
        case .onboarding:    return "OnboardingTitle"     // "Aramıza Katıl"
        case .reKyc:         return "ReKycTitle"          // "Kimlik Yenileme"
        case .limitIncrease: return "LimitIncreaseTitle"  // "Limit Artırımı"
        case .deviceChange:  return "DeviceChangeTitle"   // "Cihaz Onayı"
        case .addressUpdate: return "AddressUpdateTitle"  // "Adres Güncelleme"
        }
    }
}

final class KycContext {
    static let shared = KycContext()
    private init() {}
    var scenario: KycScenario = .onboarding
}
```

> Başlık metinlerini enum'a gömmek yerine `string(forKey:)`'den okumak bilinçli bir
> tercih: senaryo başlıkları da kullanıcının seçtiği dile uyar ve sunucudan/JSON'dan
> güncellenebilir (bölüm 4'teki `registerOverrides` / `loadOverrides`).

### 17.2 Senaryo → modül seti

**Birinci tercih: sunucu belirlesin.** Her senaryo için backend'de ayrı işlem türü
tanımlayın; `identId` zaten o işleme aitse `RoomResponse.modules` doğru seti döner ve
istemcide hiçbir dallanma gerekmez. Bu, "bypass yok" felsefesinin akış planına
uzantısıdır: modül sırasının sahibi sunucudur.

İstemci tarafı sabitleme gerekiyorsa `setupSDK(selectedModules:)` senaryodan türetilir:

```swift
extension KycScenario {
    var modules: [SdkModules] {
        switch self {
        case .onboarding:    return []                                   // boş = sunucu sırası (önerilen)
        case .reKyc:         return [.prepare, .idCard, .selfie]
        case .limitIncrease: return [.prepare, .idCard, .livenessDetection]
        case .deviceChange:  return [.prepare, .selfie, .nfc]
        case .addressUpdate: return [.prepare, .idCard, .addressConf]
        }
    }
}

IdentifyManager.shared.setupSDK(
    identId: session.identId,
    ...
    selectedModules: KycContext.shared.scenario.modules,
    ...
)
```

**Akışın ortasında modül eklemek** (dallanan senaryolar — ör. bir adımın sonucuna göre
akışın uzaması) için coordinator'ın kendi API'sini kullanın; eski UIKit kalıbındaki
(`manager.addModules` + `getNextModule`) elle çağrıların coordinator karşılığıdır ve
imleç/ilerleme senkronunu kendisi yönetir:

```swift
// Örn. canlılık adımı bitti; sunucu "ek doğrulama gerekli" dedi → akışı uzat:
coordinator.appendModules([.idCard, .waitScreen])
coordinator.advanceToNextModule()          // kalan sıra bitince eklenenler gelir

// String varyantı (RN/Flutter köprüsü veya eski çağrı stili):
coordinator.appendModules(moduleList: ["idCard", "waitScreen"])
```

Davranış notları:

- Eklenenler kalan modüllerin **SONUNA** gider (araya sokma yok). Araya yalnızca
  **ekran** sokulabilir (`insert(_:before:/after:)` — pasif custom ekran); araya
  **modül** sokmak sunucu imleciyle çakışacağı için desteklenmez.
- `progressTotal` (ilerleme şeridi) otomatik güncellenir; `moduleStepOrder` bozulmaz.
- `.nfc`, cihazda NFC yoksa SDK tarafından sessizce atlanabilir; `.login` / `.thankU`
  eklenemez (yok sayılır).
- Akış ThankYou'ya ulaştıysa çağrı yok sayılır (log düşer) — bitmiş akış uzatılamaz;
  yeni akış = `resetFlow()` + `prepareForSetup()` + `setupSDK`.
- Doğrudan `manager.addModules(...)` çağırmayın: dizi büyür ama `progressTotal`
  güncellenmez ve adım şeridi yanlış gösterir.

  (`isAdvancing` kilidi — asenkron pencerede gelen ikinci çağrı yok sayılır) ve
  `appendModules` imleci hiç ilerletmez. Tek disiplin: örneklerdeki sırayı koruyun —
  **önce append, sonra advance**. Kalan SON modüldeyken advance'i tetikleyip aynı anda
  append yaparsanız akış-sonu dalı kazanabilir ve ekleme yok sayılır.
- Aynı modülü ikinci kez eklerseniz ekran temiz state ile yeniden kurulur; ancak
  `insert(_:before:/after:)` kayıtları rota bazlı olduğundan o rotaya bağlı custom
  ekranlar **her** görünüşte tekrar gösterilir.

### 17.3 Senaryo → ekranlar (registry akışa girerken kurulur)

Registry ve coordinator'ı senaryoya göre **akışa her girişte yeniden** kurun —
singleton state'e senaryo sızıntısı olmaz:

```swift
@MainActor
func makeRegistry(for scenario: KycScenario) -> SDKViewRegistry {
    let registry = SDKViewRegistry()

    // 1) Senaryoya özel ARA ekranlar (pasif — bölüm 7-B):
    switch scenario {
    case .onboarding:
        registry.custom("welcome") { WelcomeView() }             // marka karşılama
        registry.custom("contract") { ContractApprovalView() }   // sözleşme onayı
    case .addressUpdate:
        registry.custom("addressInfo") {
            SDKExternalInfoView(title: KycScenario.addressUpdate.title,
                                subtitle: String(.docAddressDesc),
                                systemIcon: "house")
        }
    default:
        break
    }

    // 2) Senaryoya özel SONUÇ ekranları (bölüm 15'teki 4-varyant kuralı):
    switch scenario {
    case .onboarding:
        registry.override(.thankYou(.completed))    { OnboardingSuccessView() }  // "Hesabın hazır!"
        registry.override(.thankYou(.notCompleted)) { OnboardingFailedView() }
        registry.override(.thankYou(.missedCall))   { OnboardingMissedView() }
        registry.override(.thankYou(nil))           { OnboardingSuccessView() }
    case .limitIncrease:
        registry.override(.thankYou(.completed))    { LimitResultView(approved: true) }
        registry.override(.thankYou(.notCompleted)) { LimitResultView(approved: false) }
        registry.override(.thankYou(.missedCall))   { LimitResultView(approved: false) }
        registry.override(.thankYou(nil))           { LimitResultView(approved: true) }
    default:
        break                                        // diğerleri SDK ThankYou'sunu kullanır
    }

    return registry
}

@MainActor
func startKycFlow(scenario: KycScenario, identId: String) {
    KycContext.shared.scenario = scenario

    let coordinator = SDKFlowCoordinator()
    let registry = makeRegistry(for: scenario)

    // Ara ekranların akıştaki yeri de senaryoya göre:
    if scenario == .onboarding {
        coordinator.insert(["welcome"], before: .prepare)
        coordinator.insert(["contract"], after: .idCard)
    }
    if scenario == .addressUpdate {
        coordinator.insert(["addressInfo"], before: .addressConfirm)
    }

    coordinator.prepareForSetup()
    IdentifyManager.shared.setupSDK(identId: identId, ...) { _, resp, err in
        Task { @MainActor in
            if err == nil, resp.result == true { coordinator.start() }
        }
    }
}
```

Custom/override ekranlarınız nav bar'ında senaryo başlığını gösterir:

```swift
SDKNavigationBar(style: .module,
                 title: KycContext.shared.scenario.title,
                 subtitle: KycContext.shared.scenario.subtitle,
                 onBack: { coordinator.popBack() })
```

SDK'nın HAZIR ekranlarındaki metinleri senaryoya göre değiştirmek isterseniz akışa
girerken lokalizasyon override'ı basın (global olduğunu unutmayın — çıkışta geri alın
ya da her akış girişinde yeniden yazın):

```swift
SDKLocalization.shared.setOverride(key: .idVerifyTitle, language: .tr,
                                   value: scenario.title)
```

### 17.4 Senaryo → sonuç davranışı ve host olayları

Bölüm 15'teki iki yolun senaryoya bağlanması: kimi akış SDK içinde sonuç ekranı
gösterir, kimi akış kabı kapatıp uygulamanın kendi sayfasına döner:

```swift
final class KycEventBridge: SDKEventListener {
    func onSDKEvent(_ event: SDKEvent) {
        let scenario = KycContext.shared.scenario
        switch (event.name, scenario) {
        case ("session.completed", .limitIncrease):
            appRouter.dismissKyc(); appRouter.show(.limitApproved)   // kendi native sayfası
        case ("session.completed", .deviceChange):
            appRouter.dismissKyc(); appRouter.show(.deviceTrusted)
        case ("session.failed", _):
            analytics.log("kyc_failed", ["scenario": "\(scenario)",
                                          "lastScreen": event.metadata["lastScreen"] ?? "-"])
        case ("session.abandoned", _):
            appRouter.dismissKyc()                                    // yarıda bıraktı
        default:
            break
        }
    }
}
IdentifyManager.shared.eventDelegate = bridge     // setupSDK'dan ÖNCE, referansı sakla
```

### 17.5 Disiplin kuralları

- **Senaryo akış girişinde bir kez set edilir**, akış boyunca değiştirilmez.
- Coordinator + registry **her akış girişinde sıfırdan kurulur**; akış bitince
  `coordinator.resetFlow()` (ya da kabın kapanması) ile temizlenir.
- Singleton'lara yazılan senaryoya özgü şeyler (lokalizasyon override'ı, tema rengi
  değişikliği) **akış çıkışında geri alınır** — bir sonraki senaryoya sızmasın.
- Senaryo bilgisini analitiğe `event.metadata` ile değil kendi log çağrınızda ekleyin
  (SDK olayları senaryonuzu bilmez; köprü sınıfınız bilir — 17.4'teki gibi).
- Karar tablosu basit kalsın: senaryo sayısı arttıkça `switch`'leri tek dosyada
  (senaryo enum'unun extension'larında) toplayın; ekranlara `if scenario == ...`
  serpiştirmeyin.
