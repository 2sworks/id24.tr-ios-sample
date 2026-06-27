# IdentifySDK — Modül Entegrasyon Rehberleri

Bu klasör, `IdentifySDK` Default UI katmanındaki **her modül** için ayrı bir entegrasyon
dokümanı içerir. Önce bu sayfayı okuyun: tüm modüllerde ortak olan **kurulum, akış,
özelleştirme ve "bypass yok" kuralı** burada anlatılır. Sonra ilgilendiğiniz modülün
kendi dosyasına geçin.

> SDK ikili (binary) XCFramework'tür ve SPM ile dağıtılır. Modül ekranları (`SDKXxxView`)
> drop-in'dir: hiçbir şey yazmadan hazır akışı çalıştırabilir; istediğiniz ekranı kendi
> tasarımınızla değiştirebilirsiniz. **İç mantık (OCR, soket, WebRTC, yükleme) hep SDK'da
> kalır** — siz yalnızca UI'ı değiştirirsiniz.

---

## 1. Mimari — üç parça

| Parça | Tip | Görev |
|---|---|---|
| `SDKFlowCoordinator` | `ObservableObject` | Akışın beyni: modül geçişleri (ileri/atla/geri), navigasyon `path`, ilerleme, `IdentifyManager` köprüsü |
| `SDKViewRegistry` | sınıf | Ekran çözümleme defteri: bir SDK ekranını override etmek veya araya custom ekran eklemek |
| `SDKFlowHostView` | `View` | Kök view: `coordinator.path`'teki rotayı çizer, önce registry'ye bakar, yoksa SDK default'una düşer |

Her modülün üç dosyası vardır:

- `SDKXxxView.swift` — drop-in SwiftUI ekranı
- `SDKXxxViewModel.swift` — `public final class : SDKBaseModuleViewModel` (iş mantığı + state)
- (host tarafında, opsiyonel) `XxxHostViewModel` — SDK VM'ini **saran** kendi VM'iniz

`SDKBaseModuleViewModel` tüm modül VM'lerinin tabanıdır:

```swift
@MainActor open class SDKBaseModuleViewModel: ObservableObject {
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    let manager = IdentifyManager.shared   // singleton orchestrator (soket + WebRTC burada yaşar)
}
```

---

## 2. Kurulum — uçtan uca

### 2.1 Kök view

```swift
struct RootView: View {
    @StateObject private var coordinator = SDKFlowCoordinator()
    @State private var registry = SDKViewRegistry()

    var body: some View {
        SDKFlowHostView(coordinator: coordinator, registry: registry) {
            LoginView()                       // kök (host'un kendi giriş ekranı)
                .environmentObject(coordinator)
        }
    }
}
```

### 2.2 setupSDK — sıralama kritik

`coordinator.prepareForSetup()` **setupSDK'dan ÖNCE** çağrılmalı. Aksi halde SDK
`modulesControllersArray`'i farklı instance'larla kurar ve modüller hiç başlamaz.

```swift
func connect(coordinator: SDKFlowCoordinator) {
    coordinator.prepareForSetup()             // 1) placeholder controller'ları kaydet

    IdentifyManager.shared.setupSDK(
        identId: "...",
        baseApiUrl: "https://v2api.identify.com.tr/",
        networkOptions: SDKNetworkOptions(useSslPinning: false),
        kpsData: nil,
        signLangSupport: false,
        nfcMaxErrorCount: 3,
        selectedModules: [],                  // boş = backend'in döndürdüğü sıra
        turnKey: "...",
        wsSecretKey: "...",
        showThankYouPage: true
    ) { socket, roomResponse, error in
        Task { @MainActor in
            if error == nil, socket?.isConnected == true, roomResponse.result == true {
                coordinator.start()           // 2) ilk modüle geç
            }
        }
    }
}
```

`setupSDK` → backend `RoomResponse.modules` döndürür → `addModules` modül dizisini kurar →
`coordinator.start()` → `advanceToNextModule()` → ilk rota `path`'e push edilir →
`SDKFlowHostView` o rotanın ekranını çizer.

### 2.3 Coordinator API

| Üye | Görev |
|---|---|
| `prepareForSetup()` | setupSDK'dan **önce** placeholder controller'ları kaydeder |
| `start()` | setupSDK başarılıysa ilk modüle geçer |
| `advanceToNextModule()` | Sıradaki SDK modülüne geçer; varsa önce/sonra eklenmiş custom ekranları gösterir |
| `skipCurrentModule()` | Mevcut modülü atlar (`manager.skipModule()` + ilerle) |
| `insert(_ ids:before:)` / `insert(_ ids:after:)` | Bir SDK rotasının önüne/arkasına custom ekran(lar) zincirler |
| `showExternalScreen(_ id:)` | Anlık custom ekran gösterir (`moduleStepOrder` değişmez) |
| `advanceExternal()` | Custom ekranın "Devam"ı: kuyrukta bekleyen custom → bekleyen SDK rotası → sıradaki modül |
| `popBack()` | Geri; path tek eleman kalmışsa `exitSDK()` |
| `pushThankYouDirectly(status:)` | Doğrudan ThankYou'ya geçer (görüşme sonucu için) |
| `restoreSocketListener()` | CallScreen gibi dinleyiciyi devralanlar ayrılırken geri verir |
| `resetFlow()` | Tüm state'i sıfırlar |
| **Published:** `path`, `activeModule`, `progressStep`, `progressTotal`, `sdkError`, `subRejected`, `pendingThankYouStatus` | Akış durumu (host UI bunlara bağlanabilir) |

---

## 3. Üç özelleştirme yöntemi

### A) Tam ekran override — SDK ekranını kendi tasarımınızla değiştirin
```swift
registry.override(.selfie) { MyCustomSelfieView() }
```
`SDKFlowHostView` o rota için sizin view'ınızı çizer. **Ama** view'ınız hâlâ SDK VM'inin
metotlarını çağırmalı (aşağı bkz. bypass kuralı).

### B) Araya custom ekran ekleme — yeni `.custom(id)` rotaları
```swift
registry.custom("welcome") { MyIntroView() }         // ekranı tanımla
coordinator.insert(["welcome"], before: .selfie)     // Selfie'den ÖNCE göster
```
Custom ekranın "Devam" butonu `coordinator.advanceExternal()` çağırmalı. Bu ekranlar
`moduleStepOrder`'ı etkilemez (pasiftir, soketle konuşmaz).

### C) Host VM composition — SDK VM'ini sarın (gözlem/log/analitik)
```swift
@MainActor
final class SelfieHostViewModel: HostModuleViewModel {
    let sdk = SDKSelfieViewModel()
    override init() {
        super.init()
        bridge(sdk)                                   // child objectWillChange'i yukarı ilet
        sdk.onSkipRequested = { [weak self] in self?.log("skip") }
    }
    func process(_ img: UIImage) { log("scan"); sdk.processSelfie(image: img) }
}
```
> **Karar:** Modül VM'leri `public final` + composition kalıyor; `open`/subclass'a
> geçilmiyor. Dış geliştiriciler davranışı ezmez, yalnızca gözlemler + kendi UI'ını yapar.
> Ayrıntı: bu kararın gerekçesi proje notlarında kayıtlıdır (composition + `final`).

---

## 4. "Bypass yok" kuralı — en önemli kural

Custom bir ekran yaptığınızda, her adım eylemini (**tara / yükle / sonraki modüle geç**)
**SDK VM metoduna indirmelisiniz.** Kendi HTTP isteğinizi atıp kendi navigasyonunuzu
kurarsanız, backend ilerleme sinyallerini (`sendStep`, `modulePresented`) almaz ve akış
sunucu tarafında ilerlemez.

| ✅ Doğru | ❌ Bypass |
|---|---|
| `vm.scanFront(image:)` → OCR + upload + `sendStep` | Kendi OCR'ınız + kendi `POST`'unuz |
| `coordinator.advanceToNextModule()` → `modulePresented` sinyali | `path.append(...)` ile kendi geçişiniz |
| `vm.uploadSignature(image:)` | Görseli kendiniz yükleme |

**Soket + WebRTC `IdentifyManager.shared` singleton'ında yaşar**, View yaşam döngüsünden
izoledir. Araya **pasif** ekran (tanıtım/başarı) eklemek soketi/WebRTC'yi **etkilemez** —
o ekranlar zaten hiçbir VM metodu çağırmaz.

---

## 5. Modül listesi

| Modül | Backend key (`SdkModules`) | Rota | Bağımlılık | Doküman |
|---|---|---|---|---|
| Hazırlık | `.prepare` | `.prepare` | hız testi + izinler | [Prepare.md](Prepare/Prepare.md) |
| Kimlik (OCR) | `.idCard` | `.idCard` | on-device OCR + HTTP | [IdCard.md](IdCard/IdCard.md) |
| Kimlik (OVD/hologram) | `.idcard_w_ovd` | `.idCardOVD` | on-device skor + HTTP | [IdCardOVD.md](IdCardOVD/IdCardOVD.md) |
| NFC çip okuma | `.nfc` | `.nfc` | CoreNFC + HTTP | [NFC.md](NFC/NFC.md) |
| Selfie | `.selfie` | `.selfie` | yüz tespiti + HTTP | [Selfie.md](Selfie/Selfie.md) |
| Selfie + Liveness | `.selfieWithLiveness` | `.selfieWithLiveness` | UIKit controller + HTTP | [SelfieWithLiveness.md](SelfieWithLiveness/SelfieWithLiveness.md) |
| Canlılık (Liveness) | `.livenessDetection` | `.liveness` | adım API + HTTP | [Liveness.md](Liveness/Liveness.md) |
| Konuşma | `.speech` | `.speech` | Speech framework + soket | [Speech.md](Speech/Speech.md) |
| İmza | `.signature` | `.signature` | HTTP | [Signature.md](Signature/Signature.md) |
| Video kayıt | `.videoRecord` | `.videoRecorder` | HTTP | [VideoRecorder.md](VideoRecorder/VideoRecorder.md) |
| Adres onayı | `.addressConf` | `.addressConfirm` | HTTP (foto/PDF) | [AddressConfirm.md](AddressConfirm/AddressConfirm.md) |
| Görüntülü görüşme | `.waitScreen` | `.callScreen` | **WebRTC + soket** | [CallScreen.md](CallScreen/CallScreen.md) |
| Teşekkür / sonuç | `.thankU` | `.thankYou(_)` | — (terminal) | [ThankYou.md](ThankYou/ThankYou.md) |
| İşaret dili kapısı | — (CallScreen alt-ekranı) | — | soket (`sendStep`) | [SignLang.md](SignLang/SignLang.md) |
| Bağlantı koptu | — (overlay) | — | soket reconnect | [LostConnection.md](LostConnection/LostConnection.md) |

---

## 6. Soket/WebRTC bağımlılık özeti

| Bağımlılık | Modüller |
|---|---|
| **Yalnızca on-device** (kamera/OCR/yüz, soket yok) | IdCard(OCR), IdCardOVD, Selfie, Liveness(frame), Prepare(izin) |
| **HTTP upload** (sonuç sunucuya yüklenir) | IdCard, IdCardOVD, NFC, Selfie, Liveness, Signature, VideoRecorder, AddressConfirm |
| **Soket sinyali** (adım/durum bildirimi) | Prepare(`sendPreparetatus`), SignLang(`sendStep`), Speech(`sendSpeechStatus`), CallScreen |
| **WebRTC** (canlı görüntü + data channel) | CallScreen |

Pasif ekranlar (ThankYou, host'un tanıtım/başarı ekranları) hiçbir sinyal göndermez;
araya eklenmeleri güvenlidir.
</content>
