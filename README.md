# IdentifySDK — iOS Sample App & Geliştirici Rehberi

**IdentifySDK**, uçtan uca dijital kimlik doğrulama (KYC) akışını uygulamanıza gömmenizi sağlayan
bir iOS SDK'sıdır: kimlik kartı/pasaport tarama (OCR), NFC çip okuma, selfie + canlılık testi,
sesli okuma doğrulaması, imza, adres belgesi ve **agent ile canlı görüntülü görüşme** — hepsi
tek bir akış içinde, sunucu tarafından yönetilen modül sırasıyla çalışır.

Bu depo, SDK'yı edinen bir geliştiricinin **ilk bakacağı yer** olarak tasarlandı:

- **Çalışan bir örnek uygulama** (`NewTest/`) — her modülün hazır ekranı ve host-tarafı örneği
- **Modül bazlı entegrasyon rehberleri** — her ekran için "kendi tasarımınla nasıl çalıştırırsın"
- **Kavram rehberleri** — sunucu yapısı, WebSocket, TURN/WebRTC, log, event, tema, dil

> Resmi dökümantasyon ve SDK indirme linki: <https://docs.identify.com.tr/docs/ios/first-setup/>

---

## İçindekiler

1. [5 Dakikada Başlangıç](#5-dakikada-başlangıç)
2. [SDK Nasıl Çalışır — Kuşbakışı](#sdk-nasıl-çalışır--kuşbakışı)
3. [Modül Kataloğu](#modül-kataloğu)
4. [Kavram Rehberleri](#kavram-rehberleri)
5. [Ekranları Özelleştirme](#ekranları-özelleştirme)
6. [Kesişen Özellikler](#kesişen-özellikler)
7. [React Native & Flutter](#react-native--flutter)
8. [Örnek Uygulamanın Yapısı](#örnek-uygulamanın-yapısı)
9. [Sürüm Geçmişi](#sürüm-geçmişi)

---

## 5 Dakikada Başlangıç

### 1. Paketi ekleyin (Swift Package Manager)

Xcode → *File → Add Package Dependencies* →

```
https://github.com/2sworks/id24.tr-ios-sdk-spm
```

Paket, SDK ile birlikte üç çalışma zamanı bağımlılığını da getirir: `OpenSSL` (NFC kripto),
`Starscream` (WebSocket) ve `WebRTC` (görüntülü görüşme).

### 2. İzinleri tanımlayın

| İzin | Anahtar | Hangi modül için |
|---|---|---|
| Kamera | `NSCameraUsageDescription` | Kimlik, Selfie, Canlılık, Video, Görüşme |
| Mikrofon | `NSMicrophoneUsageDescription` | Görüşme, Video kayıt, Konuşma |
| Konuşma tanıma | `NSSpeechRecognitionUsageDescription` | Konuşma (Speech) modülü |
| NFC | `com.apple.developer.nfc.readersession.formats` → `TAG` (entitlement) + Info.plist'e `com.apple.developer.nfc.readersession.iso7816.select-identifiers` → `A0000002471001` | NFC çip okuma |

### 3. Akışı başlatın

Uygulamanızın kökünde `SDKFlowHostView` kurun, sonra `setupSDK` çağırın.
**Sıralama kritik:** `coordinator.prepareForSetup()` her zaman `setupSDK`'dan **önce** çağrılmalı.

```swift
import IdentifySDK
import SwiftUI

struct RootView: View {
    @StateObject private var coordinator = SDKFlowCoordinator()
    @State private var registry = SDKViewRegistry()

    var body: some View {
        SDKFlowHostView(coordinator: coordinator, registry: registry) {
            LoginView()                      // sizin giriş ekranınız (kök)
                .environmentObject(coordinator)
        }
    }
}

func connect(coordinator: SDKFlowCoordinator) {
    coordinator.prepareForSetup()            // 1) setupSDK'dan ÖNCE

    IdentifyManager.shared.setupSDK(
        identId: "MÜŞTERİ-İŞLEM-NO",
        baseApiUrl: "https://v2api.identify.com.tr/",
        networkOptions: SDKNetworkOptions(useSslPinning: false),
        kpsData: nil,
        signLangSupport: false,
        nfcMaxErrorCount: 3,
        selectedModules: [],                 // boş = sırayı backend belirler
        turnKey: "TURN-ANAHTARINIZ",
        wsSecretKey: "WS-ANAHTARINIZ",
        showThankYouPage: true
    ) { socket, roomResponse, error in
        Task { @MainActor in
            if error == nil, socket?.isConnected == true, roomResponse.result == true {
                coordinator.start()          // 2) ilk modüle geç
            }
        }
    }
}
```

Bu kadar. Backend'in `modules` listesinde ne varsa, ekranlar o sırayla otomatik gelir.
Hiçbir modül ekranı yazmanıza gerek yok — hepsinin hazır (drop-in) SwiftUI sürümü SDK'nın içindedir.
Tam parametre listesi için: [Sunucu & API Rehberi](docs/guides/server-api.md).

> Minimum iOS sürümü: **iOS 14** (örnek uygulama iOS 15 hedefler).

---

## SDK Nasıl Çalışır — Kuşbakışı

```
Host App                         IdentifySDK                        Identify Backend
────────                         ───────────                        ────────────────
setupSDK(identId, ...)  ───────► connectToRoom ────────────────────► oda + modül listesi
                                 RoomResponse.modules ◄─────────────  (RoomResponse)
coordinator.start()     ───────► SDKFlowCoordinator
                                   │  path'e rota push eder
                                   ▼
                                 SDKFlowHostView ─► registry'de override var mı?
                                   │                   evet → sizin ekranınız
                                   │                   hayır → SDK'nın hazır ekranı
                                   ▼
                                 Modül VM'i (OCR / NFC / upload / soket sinyali)
                                   │
                                   ▼
                                 advanceToNextModule() ────────────► adım tamamlandı sinyali
                                   (son modülden sonra ThankYou)
```

Üç yapı taşını tanımak yeterli:

| Yapı | Ne işe yarar |
|---|---|
| `IdentifyManager.shared` | Tek orkestratör: HTTP, WebSocket ve WebRTC burada yaşar. Ekranlardan bağımsızdır. |
| `SDKFlowCoordinator` | Akışın beyni: hangi modüldeyiz, ileri/atla/geri, ilerleme yüzdesi. |
| `SDKViewRegistry` | Ekran defteri: bir SDK ekranını kendi tasarımınızla değiştirmek veya araya ekran sokmak için. |

Derinlemesine anlatım: [Mimari Rehberi](docs/guides/architecture.md).

---

## Modül Kataloğu

Her modülün kendi rehberi vardır: ekranın ne yaptığı, kullanıcının ne yaşadığı, hazır ekranı
kullanma, **kendi tasarımınla değiştirme** ve ViewModel referansı — hepsi tek dosyada.

| Modül             | Ne yapar                                                             | Rehber                                                                         |
| ----------------- | -------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Hazırlık          | İzinleri ve bağlantı hızını kontrol eder, kullanıcıyı akışa hazırlar | [Prepare](NewTest/Modules/Prepare/Prepare.md)                                  |
| Kimlik (OCR)      | Kimlik kartının ön/arka yüzünü çeker, cihaz üzerinde okur            | [IdCard](NewTest/Modules/IdCard/IdCard.md)                                     |
| Kimlik (OVD)      | Hologram/optik doğrulama ile sahte kimlik tespiti                    | [IdCardOVD](NewTest/Modules/IdCardOVD/IdCardOVD.md)                            |
| NFC               | Kimlik/pasaport çipini okur (ICAO: BAC/PACE/CA)                      | [NFC](NewTest/Modules/NFC/NFC.md)                                              |
| Selfie            | Selfie çeker, cihaz üzerinde yüz tespiti yapar                       | [Selfie](NewTest/Modules/Selfie/Selfie.md)                                     |
| Selfie + Canlılık | Selfie ile canlılık testini birleştirir                              | [SelfieWithLiveness](NewTest/Modules/SelfieWithLiveness/SelfieWithLiveness.md) |
| Canlılık          | Sola dön / göz kırp / gülümse adımlarıyla canlılık testi             | [Liveness](NewTest/Modules/Liveness/Liveness.md)                               |
| Konuşma           | Ekrandaki metni sesli okutup doğrular (STT)                          | [Speech](NewTest/Modules/Speech/Speech.md)                                     |
| İmza              | Ekranda imza alır ve yükler                                          | [Signature](NewTest/Modules/Signature/Signature.md)                            |
| Video Kayıt       | Kısa video kaydı alır ve yükler                                      | [VideoRecorder](NewTest/Modules/VideoRecorder/VideoRecorder.md)                |
| Adres Onayı       | Adres belgesi fotoğrafı/PDF'i yükler                                 | [AddressConfirm](NewTest/Modules/AddressConfirm/AddressConfirm.md)             |
| Görüntülü Görüşme | Agent ile canlı WebRTC görüşmesi                                     | [CallScreen](NewTest/Modules/CallScreen/CallScreen.md)                         |
| Teşekkür          | Akış sonucu ekranı (başarılı/başarısız/beklemede)                    | [ThankYou](NewTest/Modules/ThankYou/ThankYou.md)                               |
| İşaret Dili       | Görüşme öncesi işaret dili tercihi kapısı                            | [SignLang](NewTest/Modules/SignLang/SignLang.md)                               |
|  Bağlantı Koptu   | Bağlantı kopunca çıkan overlay + otomatik toparlanma                 | [LostConnection](NewTest/Modules/LostConnection/LostConnection.md)             |

➡️ Ortak kurallar (kurulum, üç özelleştirme yöntemi, "bypass yok" kuralı) için önce
**[Modül Rehberleri İndeksi](NewTest/Modules/Modules.md)**'ni okuyun.

> Not: Bu rehberler kasıtlı olarak **SampleApp (public repo)** içindedir. SDK, ikili (binary)
> XCFramework olarak dağıtıldığından SDK kaynak ağacına konan dokümanlar tüketici tarafından
> okunamaz; tek kaynak burasıdır.

---

## Kavram Rehberleri

Modüllerin altında yatan sistemleri anlamak için:

| Rehber | İçerik |
|---|---|
| [Mimari](docs/guides/architecture.md) | `IdentifyManager`, modül hattı, DefaultUI üçlüsü, yaşam döngüsü |
| [Sunucu & API](docs/guides/server-api.md) | `setupSDK` tüm parametreleri, `RoomResponse`, modül sırası, SSL pinning |
| [WebSocket](docs/guides/websocket.md) | Soket aksiyonları, `socket_auth` token'ı, reconnect ve LostConnection katmanı |
| [TURN & WebRTC](docs/guides/turn-webrtc.md) | STUN/TURN kimlik üretimi, şifreli TURN, görüşme akışı |
| [Loglama](docs/guides/logging.md) | `SDKLog` facade'i, severity/kategori, online log, redaksiyon |
| [Event Sistemi](docs/guides/events.md) | `SDKEvent`, `IdentifyTrackingListener`, analitik entegrasyonu |
| [Tema](docs/guides/theming.md) | `SDKTheme` — renk/font/ikon/metrik override |
| [Lokalizasyon](docs/guides/localization.md) | 5 dil (TR/EN/DE/AZ/RU), metin override |
| [Özelleştirme](docs/guides/customization.md) | Üç özelleştirme yöntemi derinlemesine + "bypass yok" kuralı |
| [IdentityScanner](docs/guides/identity-scanner.md) | Gerçek zamanlı belge tarama motoru: profiller, alan OCR, TCKN/MRZ doğrulama, bağımsız kullanım |

---

## Ekranları Özelleştirme

Kısa özet — üç seviye vardır, dilediğinizde karıştırabilirsiniz:

```swift
// A) Hiçbir şey yapma → SDK'nın hazır ekranları çalışır (drop-in)

// B) Bir ekranı kendi tasarımınla değiştir
registry.override(.selfie) { MySelfieView() }

// C) Araya kendi ekranını sok (tanıtım, sözleşme, başarı...)
registry.custom("welcome") { MyIntroView() }
coordinator.insert(["welcome"], before: .selfie)
```

Tek altın kural: custom ekranınız **iş mantığını SDK ViewModel'ine bırakmalı**
(taramayı `vm.scanFront(image:)`, geçişi `coordinator.advanceToNextModule()` yapar).
Kendi HTTP isteğinizi atarsanız backend akışı ilerlemez.
Ayrıntı: [Özelleştirme Rehberi](docs/guides/customization.md).

---

## Kesişen Özellikler

Modüllerden bağımsız, akışın tamamına dokunan yetenekler:

- **Sesli okuma (Read-Aloud)** — her modül ekranı açıldığında yönergesi otomatik seslendirilebilir;
  modül başına `.native` (Siri sesi) / `.customAudio` (kendi ses kaydınız) / `.off` seçilir.
  → [ReadAloud Rehberi](NewTest/Modules/ReadAloud.md)
- **Tema** — tüm renk/font/ikon/metrik token'ları `SDKTheme.shared` üzerinden değiştirilebilir.
  → [Tema Rehberi](docs/guides/theming.md)
- **Dil** — TR, EN, DE, AZ, RU; her metni tek tek ezebilirsiniz.
  → [Lokalizasyon Rehberi](docs/guides/localization.md)
- **Log & İzleme** — konsol + online log, kategori bazlı; `TrackingEventType` ile her modülün
  gösterildi/tamamlandı/atlandı olaylarını dinlersiniz.
  → [Loglama](docs/guides/logging.md) · [Event Sistemi](docs/guides/events.md)

---

## React Native & Flutter

SDK'yı köprüleyerek RN/Flutter uygulamalarında da kullanabilirsiniz. Hazır köprü iskeletleri:

- [React Native entegrasyonu](docs/integration/react-native/README.md)
- [Flutter entegrasyonu](docs/integration/flutter/README.md)

---

## Örnek Uygulamanın Yapısı

```
NewTest/
├── App/            AppDelegate + RootView (SDKFlowHostView kurulumu)
├── Core/           Debug araçları, extension'lar
├── Modules/        Modül başına: örnek ekran + HostViewModel + <Modül>.md rehberi
│   ├── Login/      Host'un giriş ekranı örneği (identId girişi + setupSDK)
│   ├── Selfie/     SelfieExample, SelfieHostViewModel, Selfie.md ...
│   └── ...
├── Showcase/       Yetenek vitrini: event akış ekranı, sesli okuma denemesi,
│                   cross-platform rehber ekranı, tasarım kataloğu
└── SupportingFiles/ Info.plist, entitlements, asset'ler
```

Uygulamayı açıp `NewTest.xcodeproj` ile derleyin; Login ekranına bir `identId` girip
tüm akışı cihazda uçtan uca deneyimleyebilirsiniz (NFC ve görüşme için gerçek cihaz gerekir).

---

## Sürüm Geçmişi

SDK ve Sample App sürüm notlarının tamamı için: **[CHANGELOG.md](CHANGELOG.md)**
