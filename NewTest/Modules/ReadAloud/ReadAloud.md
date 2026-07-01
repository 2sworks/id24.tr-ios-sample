# Sesli Okuma (Read-Aloud)

Her modül ekranı açıldığında, o modülün yönerge metni **sesli okunabilir**. Bu bir modül
değil, tüm modüllere serpiştirilmiş **kesişen (cross-cutting)** bir erişilebilirlik
özelliğidir. İki adımlıdır ve **modül bazında** seçilir:

| Mod | Ne yapar | Kaynak |
|---|---|---|
| `.native` | iOS `AVSpeechSynthesizer` (Siri / sistem sesi) `*_tts` metnini okur | `*_tts` SDKKeyword'leri |
| `.customAudio` | Host'un bundle'a koyduğu ses klibini `AVAudioPlayer` ile çalar | Bundle dosyası (isim konvansiyonu) |
| `.off` | O modülde sesli okuma yok | — |

> ⚠️ Bu özellik KYC **konuşma-TANIMA** modülüyle (`.speech` / `SDKSpeechRecView`, kullanıcının
> ifade okuduğu adım) **karıştırılmamalıdır**. Buradaki "speech" = sesli **OKUMA** (TTS).
> Ağ/model indirmesi yoktur; tamamen offline ve akışı asla bloklamaz.

---

## 1. Nasıl çalışır

Seslendirme **tek noktadan, otomatik** yapılır: `SDKFlowHostView` bir modül ekranını
çizerken `.speakOnAppear(route)` uygular. `SDKSpeechService`, o rotanın modülü için
`SDKSpeechConfig`'ten modu okur ve `route.ttsKey`'i seslendirir. **Host'un modül başına
ekstra kod yazmasına gerek yoktur** — sadece modu ayarlar.

```
Ekran açılır → SDKFlowHostView.speakOnAppear(route)
             → SDKSpeechService.speak(route:)
             → mode = SDKSpeechConfig.mode(for: route.sdkModule)
                • .native      → AVSpeechSynthesizer( translate(route.ttsKey) )
                • .customAudio → AVAudioPlayer( <route.ttsKey.rawValue>.m4a )  // yoksa native'e düş
                • .off         → sessiz
Ekrandan ayrılınca → stop()
```

---

## 2. Kurulum (host)

Modu `setupSDK`'dan önce ya da sonra, **akış başlamadan** ayarlayın.

```swift
// A) Tümü native (en basit):
SDKSpeechConfig.shared.setModeForAll(.native)

// B) Per-modül karışık:
SDKSpeechConfig.shared.defaultMode = .native
SDKSpeechConfig.shared.setMode(.customAudio, for: [.selfie, .nfc])
SDKSpeechConfig.shared.setMode(.off, for: .livenessDetection)

// C) Kısayol — setupSDK(ttsEnabled: true) defaultMode .off ise .native'e yükseltir.
IdentifyManager.shared.setupSDK(/* ... */, ttsEnabled: true) { _, resp, _ in ... }
```

> **SampleApp:** Sesli okuma, Login ekranındaki **hamburger menü → "Sesli Okuma (TTS)"**
> anahtarıyla açılıp kapatılır. Tercih `@AppStorage("sdkReadAloudEnabled")` ile kalıcıdır;
> `LoginView.onAppear` bu değeri `SDKSpeechConfig.shared.defaultMode`'a (`.native` / `.off`)
> uygular, böylece uygulama yeniden açıldığında da geçerli kalır.

---

## 3. Native ayarları (AVSpeechSynthesizer)

```swift
SDKSpeechConfig.shared.speechRate = AVSpeechUtteranceDefaultSpeechRate   // 0.0...1.0
SDKSpeechConfig.shared.pitch      = 1.0                                   // 0.5...2.0
// Belirli bir Siri/sistem sesi (yoksa aktif dile göre otomatik seçilir):
SDKSpeechConfig.shared.voiceIdentifier = "com.apple.voice.enhanced.tr-TR.Yelda"
```

Ses, aktif SDK diline göre seçilir (`tr-TR`, `en-US`, `de-DE`, `ru-RU`, `az-AZ`). İlgili
dil sesi cihazda yoksa sistem varsayılanına düşer; okuma yine denenir.

---

## 4. Custom audio — kendi ses kaydını çal

Dosya adı konvansiyonu: **`<SDKKeyword.rawValue>.<uzantı>`**. Uzantı varsayılan `m4a`
(mp3/wav/caf da olur). Arama sırası: `SDKSpeechConfig.audioBundle` → SDK bundle → `Bundle.main`.

```swift
SDKSpeechConfig.shared.audioBundle = Bundle.main   // önce burada ara
SDKSpeechConfig.shared.audioFileExtension = "m4a"
SDKSpeechConfig.shared.setMode(.customAudio, for: .selfie)
```

Örnek bundle içeriği:
```
MyApp.app/
  PrepareTts.m4a
  SelfieTts.m4a
  NfcTts.m4a
  ...
```

Modül → dosya adı karşılıkları (route.ttsKey.rawValue):

| Modül | Dosya |
|---|---|
| `.prepare` | `PrepareTts.m4a` |
| `.selfie` | `SelfieTts.m4a` |
| `.selfieWithLiveness` | `SelfieWithLivenessTts.m4a` |
| `.idCard` | `IdCardTts.m4a` |
| `.idCard` (ön yüz) | `IdCardFrontTts.m4a` |
| `.idCard` (arka yüz) | `IdCardBackTts.m4a` |
| `.idCard` (pasaport) | `PassportTts.m4a` |
| `.idcard_w_ovd` | `IdCardOVDTts.m4a` |
| `.nfc` | `NfcTts.m4a` |
| `.livenessDetection` | `LivenessTts.m4a` |
| `.speech` | `SpeechTts.m4a` |
| `.addressConf` | `AddressConfirmTts.m4a` |
| `.signature` | `SignatureTts.m4a` |
| `.videoRecord` (düz video) | `VideoRecorderTts.m4a` |
| `.videoRecord` (okuma testi) | — (dinamik cümle, yalnız native) |
| `.waitScreen` | `CallScreenTts.m4a` |
| `.thankU` | `ThankYouTts.m4a` |

### Dosya bulunamazsa → native fallback
`.customAudio` seçili ama klip yoksa, **varsayılan olarak native okuma** devreye girer
(aynı `*_tts` metni). Kapatmak için:
```swift
SDKSpeechConfig.shared.fallbackToNativeIfAudioMissing = false   // yoksa sessiz kal
```

---

## 5. Ekstra / özel key ekleme (bir modüle ikinci bir okuma)

Bir modülde standart `*_tts` yönergesinin dışında ekstra bir metin okutmak istiyorsanız:

**1) Yeni key (SDK'da `SDKKeyword`).** Kendi yeni key'iniz için enum'a dokunmadan
`SDKLocalization` override'ıyla metin tanımlayabilirsiniz; SDK bundled key'leri zaten
enum'dadır.

**2) Metni ekle/ez** (XCFramework JSON'u salt-okunur → runtime override):
```swift
SDKLocalization.shared.registerOverrides([
    .tr: ["NfcRetryTts": "Okuma başarısız, tekrar deneyin."],
    .en: ["NfcRetryTts": "Reading failed, try again."]
])
```

**3) Modül VM'inden tetikle** (moda göre native metin ya da `NfcRetryTts.m4a`):
```swift
speak(.nfcRetryTts, in: .nfc)
```

`speak(_:in:)` verilen modülün moduna bakar; `.customAudio` ise `<rawValue>.m4a`'yı çalar,
yoksa native metne düşer.

---

## 6. Metinleri özelleştirme (native)

Native mod, `SDKLocalization.translate()` üzerinden metni okur ve **önce host
override'larına** bakar. Yani bundle JSON'una dokunmadan metni değiştirebilirsiniz:

```swift
SDKLocalization.shared.setOverride(key: .selfieTts, language: .tr,
    value: "Yüzünüzü çerçeveye alın ve sabit durun.")
```

Çözüm sırası: **host override → bundle JSON (5 dil) → key'in kendisi.**

---

## 7. Kesme / kilit politikası (yarıda kesilme)

Kullanıcı bir yönerge okunurken sonraki modüle geçerse okuma yarıda kalabilir. Davranış
`SDKSpeechConfig.shared.interruptPolicy` ile seçilir:

| Politika | Davranış |
|---|---|
| `.blockUntilDone` **(varsayılan)** | Okuma bitene kadar ekran etkileşimi **kilitlenir**; kullanıcı erken ilerleyemez, yönerge tam duyulur. `SDKFlowHostView`, `SDKSpeechService.shared.isSpeaking` iken ekranı `.disabled` yapar. |
| `.interruptOnNext` | Geçişte kesilmez; yalnızca **sonraki ekranın kendi okuması** öncekini keser. Sonraki modül `.off` ise önceki doğal biter. |
| `.finishThenNext` | Okumalar **sıraya** alınır (native `AVSpeechSynthesizer` doğal kuyruğu). Custom audio için kuyruk yoktur; kesintili çalar. |

```swift
SDKSpeechConfig.shared.interruptPolicy = .blockUntilDone   // varsayılan
```

**Emniyet:** blockUntilDone'da bitiş bildirimi hiç gelmezse ekran süresiz kilitli kalmasın
diye 30 sn'lik watchdog kilidi zorla çözer.

**Neden thread değil?** `AVSpeechSynthesizer` / `AVAudioPlayer` zaten **asenkron** çalar;
main thread'i bloklamaz. Kesilme bir yaşam-döngüsü kararıdır (ekran kaybolunca `stop()`),
eşzamanlılık sorunu değil — bu yüzden çözüm politika/kilit, background thread değildir.

**Geri / çıkış:** İleri geçişte okuma (politikaya göre) sürer; **geri** gidildiğinde
(`navDirection == .back`) okuma anında durur.

### Kamera-öncelikli modüller (kamera hazır olunca oku)
Selfie, Liveness, VideoRecorder, SelfieWithLiveness ve OVD gibi ekran açılır açılmaz kamera
başlatan modüllerde okuma **hemen değil, kamera hazır olunca** başlar. Kamera oturumu
(`AVCaptureSession`) başlarken ses oturumunu yeniden kurar ve okumayı yarıda keserdi; bu yüzden
`SDKSpeechService`, sistemin `AVCaptureSession.didStartRunningNotification` sinyalini dinleyip
okumayı o ana erteler (modül başına wiring yok). Kamera hiç başlamazsa (izin yok / ARKit)
2 sn'lik fallback ile okuma yine de yapılır. `SDKModuleRoute.usesCamera` bunu belirler;
`IdentityScannerView` ise `speak(..., whenCameraReady: true)` ile aynı davranışı alır.

### VideoRecorder — iki mod, iki farklı metin
VideoRecorder'ın seslendirmesi çalışma anındaki `readingText`'e göre **dinamik**tir (bu yüzden
route'un statik `ttsKey`'i kapalıdır; view kendi seslendirir):

| Durum | Okunan |
|---|---|
| **Okuma testi** (`readingText` dolu) | `VideoRecorderReadingTts` formatı + cümle → *"Kayıt düğmesine basın ve ekrandaki şu cümleyi kameraya bakarak yüksek sesle okuyun: {cümle}"* (dinamik metin → yalnız native) |
| **Düz video** (`readingText` boş) | `.videoRecorderTts` → *"Sizden kısa bir video kaydı alacağız. Kayıt düğmesine basın, kameraya bakın ve doğal bir şekilde bekleyin."* (modül moduna göre native/customAudio) |

Her iki durumda da kamera hazır olunca okunur (`whenCameraReady`).

### VoiceOver
`respectVoiceOver = true` (varsayılan) iken VoiceOver açıksa kendi sesli okumamız
**devre dışı** kalır (sistem ekran okuyucusuyla çakışmayı önlemek için).

---

## 7b. IdentityScanner (canlı tarayıcı) desteği

Canlı belge tarayıcısı `IdentityScannerView`, akış içinde `.fullScreenCover` ile sunulur ve
host-level `speakOnAppear(route)` kapsamı dışındadır. Bu yüzden read-aloud'u **opt-in
parametrelerle** doğrudan destekler:

```swift
IdentityScannerView(
    profile: profile,
    speechKey: .idCardTts,     // nil → okuma yok (standalone geriye uyumlu)
    speechModule: .idCard      // nil → native metin (modül modu uygulanmaz)
) { result in ... }
```

- `onAppear` → `speak(key, in: module)`, `onDisappear` → `stop()`.
- `blockUntilDone` politikasında, okuma süresince tarayıcı içeriği `.disabled` olur (yönerge
  tam duyulur); cover'ın **geri** butonu etkilenmez, kullanıcı kilitli kalmaz.

**Yön/tarafa özel yönerge (idCard):** SDK'nın hazır IdCard modülü tarayıcıyı, taranan **yüze
ve kart tipine** göre farklı key ile bağlar; böylece kullanıcı hangi tarafı göstereceğini duyar:

| Durum | Okunan key |
|---|---|
| **Tip seçim** ekranı (modül açılışı) | `.idCardTypeSelectTts` — "Lütfen kimlik türünüzü seçin: çipli kimlik kartı, pasaport veya diğer kartlar." |
| Kimlik **ön** yüz | `.idCardFrontTts` — "Kimliğinizin ön yüzünü çerçeveye hizalayın…" |
| Kimlik **arka** yüz | `.idCardBackTts` — "Kimliğinizin arka yüzünü çerçeveye hizalayın…" |
| **Pasaport** (veri sayfası) | `.passportTts` — "Pasaportunuzun kimlik bilgilerinin olduğu sayfayı…" |

Beş dilde (TR/EN/DE/RU/AZ) karşılıkları hazırdır; host isterse `SDKLocalization.setOverride`
ile metinleri veya `.customAudio` modunda `IdCardFrontTts.m4a` / `IdCardBackTts.m4a` /
`PassportTts.m4a` ses dosyalarını değiştirebilir. Genel `.idCardTts` (yön belirtmeyen) hâlâ
mevcuttur; standalone `IdentityScannerView` kullananlar dilediği key'i geçebilir.

> idCard modülünde yönerge iki anda okunur: modül seçim ekranına girişte (`.idCardTts`) ve
> tarayıcı tarama anında (yüze özel key). blockUntilDone'da bunlar sıralıdır (üst üste binmez).

---

## 8. API özeti

```swift
// Konfig (SDKSpeechConfig.shared)
enum Mode { case off, native, customAudio }
enum InterruptPolicy { case blockUntilDone, interruptOnNext, finishThenNext }
var defaultMode: Mode
var interruptPolicy: InterruptPolicy       // varsayılan .blockUntilDone
var respectVoiceOver: Bool                 // varsayılan true
func setMode(_:for: SdkModules)          // tek modül
func setMode(_:for: [SdkModules])        // çoklu
func setModeForAll(_:)                    // default + override temizle
var speechRate: Float; var pitch: Float; var voiceIdentifier: String?
var audioBundle: Bundle?; var audioFileExtension: String
var fallbackToNativeIfAudioMissing: Bool  // varsayılan true

// Seslendirme (SDKSpeechService.shared)
@Published private(set) var isSpeaking: Bool           // blockUntilDone kilidi bunu izler
func speak(_ key: SDKKeyword, in module: SdkModules)   // moda göre
func speak(_ key: SDKKeyword)                          // her zaman native
func speak(text: String)                               // her zaman native
func stop()
// VM köprüsü (SDKBaseModuleViewModel): speak(_:in:), speak(_:), stopSpeech()
```

Canlı demo: Örnek uygulamada **Rehber → Sesli Okuma → Sesli Okuma (Read-Aloud)**.
