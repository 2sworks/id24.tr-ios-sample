# CallScreen — Görüntülü görüşme (WebRTC + soket)

SDK'nın en karmaşık modülü. Temsilciyle canlı görüntülü görüşmeyi yönetir: **WebRTC** peer
connection (yerel/uzak video), **soket** üzerinden çağrı durumu, SMS doğrulama, uzaktan
NFC tetikleme, işaret dili kapısı ve bağlantı-koptu kurtarma. Görüşme bittiğinde sonuç
statüsü ThankYou'ya taşınır.

| | |
|---|---|
| Backend key | `SdkModules.waitScreen` |
| Rota | `SDKModuleRoute.callScreen` |
| Drop-in view | `SDKCallScreenView` (+ `SDKVideoFeedRepresentable`) |
| ViewModel | `SDKCallScreenViewModel` |
| Bağımlılık | **WebRTC** (`manager.webRTCClient`) + **soket** (çağrı aksiyonları) + HTTP |

> Bu modül çalışırken **soket dinleyicisini coordinator'dan devralır.** Ekrandan ayrılırken
> `coordinator.restoreSocketListener()` ile geri verir (terminate akışında otomatik yapılır).

---

## Tipler

```swift
public enum SDKCallState { case waiting, /* ... */ connected, ended }
public enum SDKCallNetworkQuality { case none, /* ... */ good, poor }
```

## VM API — `SDKCallScreenViewModel`

### Çağrı durumu (`@Published`, salt-okunur)
| Üye | Tip | Anlam |
|---|---|---|
| `callState` | `SDKCallState` | Çağrı durumu (bekliyor/bağlı/bitti) |
| `queuePosition` | `String` | Sıradaki konum |
| `estimatedWait` | `String` | Tahmini bekleme |
| `networkQuality` | `SDKCallNetworkQuality` | Ağ kalitesi |
| `endCallEnabled` | `Bool` | "Görüşmeyi bitir" aktif mi |
| `callCompleted` | `Bool` | Görüşme tamamlandı mı |
| `socketThankYouStatus` | `ThankYouStatus?` | Soketten gelen sonuç statüsü |
| `photoTakenToast` | `String?` | "Fotoğraf alındı" bildirimi |
| `lostConnectionCallCompleted` | `Bool` | Kopma sonrası görüşme tamamlandı mı |

### SMS doğrulama
| Üye | Tip | Anlam |
|---|---|---|
| `smsCode` | `String` (r/w) | Girilen SMS kodu |
| `isSMSCodeValid` | `Bool` (hesaplanan) | Kod 6 haneli mi |

### Uzaktan NFC (görüşme sırasında temsilcinin tetiklediği)
| Üye | Tip | Anlam |
|---|---|---|
| `nfcStatusMessage` | `String` (salt-okunur) | NFC durum metni |
| `showNFCEdit` | `Bool` (r/w) | MRZ düzenleme ekranı |
| `nfcEditSerial / nfcEditBirth / nfcEditValid` | `String` (r/w) | Düzenlenebilir MRZ alanları |

### İşaret dili kapısı / kopma
| Üye | Tip | Anlam |
|---|---|---|
| `showSignLangGate` | `Bool` (r/w) | İşaret dili kapısı göster |
| `showLostConnection` | `Bool` (r/w) | Bağlantı-koptu overlay'i |

### Video (WebRTC)
| Üye | Anlam |
|---|---|
| `remoteVideoView: UIView?` | Uzak (temsilci) video katmanı (`webRTCClient.remoteVideoView()`) |
| `localVideoView: UIView?` | Yerel (kullanıcı) video katmanı |

### Girdi (metotlar)
| Metot | Etki |
|---|---|
| `checkSignLangIfNeeded()` | `connectToSignLang` ise işaret dili kapısını açar |
| `signLangCompleted()` | İşaret dili adımını tamamlar |
| `acceptCall()` | Çağrıyı kabul eder (`manager.acceptCall`) |
| `terminateCall(coordinator:)` | Görüşmeyi bitirir (`terminateCallByUser`) + dinleyiciyi geri verir + ThankYou'ya geçer |
| `verifySMS()` | SMS kodunu doğrular (`manager.smsVerification`) |
| `startRemoteNFC(birthDate:validDate:docNo:)` | Uzaktan NFC okumayı başlatır (`manager.startRemoteNFC`) |
| `saveAndRestartRemoteNFC(serial:birth:valid:)` | MRZ'yi kaydedip NFC'yi yeniden başlatır |
| `handleReconnectCompleted()` / `handleReconnectCompletedWithStatus(...)` | Kopma sonrası kurtarma |
| `cleanup()` | Kaynakları temizler (ekrandan ayrılırken) |

### Soket dinleyici
```swift
nonisolated public func listenSocketMessage(message: SDKCallActions)
```
CallScreen aktifken soket mesajlarını **doğrudan** bu VM işler (coordinator yerine).

---

## Sinyal zinciri

```
(görünür) → checkSignLangIfNeeded() → connectToSignLang ? showSignLangGate
acceptCall()         → manager.acceptCall [SOKET] + WebRTC peer connection kurulur
                       remoteVideoView / localVideoView (WebRTC track'leri)
verifySMS()          → manager.smsVerification [SOKET]
startRemoteNFC(...)  → manager.startRemoteNFC (CoreNFC) → nfcMsgHandler
listenSocketMessage  → çağrı aksiyonları (sonuç statüsü, foto alındı, kopma...)
terminateCall(coordinator:)
   → manager.terminateCallByUser [SOKET]
   → coordinator.restoreSocketListener()
   → coordinator.pendingThankYouStatus = socketThankYouStatus
   → coordinator.advanceToNextModule()  →  .thankYou(status)
```

---

## Drop-in kullanım

CallScreen'i **drop-in kullanmanız şiddetle önerilir.** WebRTC peer connection, ICE
candidate, data channel ve soket aksiyon eşlemesi VM içinde sıkı bağlıdır.

```swift
case .callScreen: SDKCallScreenView()
```

## Host VM (gözlem) — güvenli

```swift
final class CallHostViewModel: HostModuleViewModel {
    let sdk = SDKCallScreenViewModel()
    override init() {
        super.init(); bridge(sdk)
    }
    var state: SDKCallState { sdk.callState }
    var queue: String { sdk.queuePosition }
    var quality: SDKCallNetworkQuality { sdk.networkQuality }
}
```

## Custom tasarım (override) — dikkatli

Tasarımı değiştirebilirsiniz ama **tüm çağrı eylemleri SDK VM'inden geçmeli** ve video
katmanlarını VM'den almalısınız:

```swift
registry.override(.callScreen) { MyCallView() }

struct MyCallView: View {
    @EnvironmentObject var coordinator: SDKFlowCoordinator
    @StateObject private var vm = SDKCallScreenViewModel()
    var body: some View {
        ZStack {
            // Uzak/yerel video — WebRTC katmanlarını VM'den alın (kendiniz kurmayın):
            if let remote = vm.remoteVideoView { UIViewWrapper(remote) }   // ✅
            if let local  = vm.localVideoView  { UIViewWrapper(local) }    // ✅

            VStack {
                Text("Sıra: \(vm.queuePosition)")
                if vm.callState == .waiting {
                    Button("Kabul Et") { vm.acceptCall() }                 // ✅ soket
                }
                // SMS:
                TextField("SMS", text: $vm.smsCode)
                Button("Doğrula") { vm.verifySMS() }.disabled(!vm.isSMSCodeValid) // ✅
                Button("Bitir") { vm.terminateCall(coordinator: coordinator) }    // ✅
            }
        }
        .onAppear { vm.checkSignLangIfNeeded() }
    }
}
```

> **WebRTC sorun olur mu?** Hayır — `webRTCClient` `IdentifyManager.shared`'da yaşar, View
> yaşam döngüsünden bağımsızdır. Ama video katmanlarını **mutlaka** `vm.remoteVideoView` /
> `vm.localVideoView`'den alın; kendi peer connection'ınızı kurmayın. Çağrı aksiyonları
> (`accept/verify/terminate`) VM'den geçmezse soket sinyalleri gitmez (bypass).

## Notlar
- Görüşme bitince `terminateCall(coordinator:)` hem soketi bilgilendirir hem dinleyiciyi
  coordinator'a geri verir; bunu atlamayın yoksa sonraki ekranlar soket mesajı almaz.
- İşaret dili gerekiyorsa (`connectToSignLang`) `checkSignLangIfNeeded()` kapıyı açar; bkz. [İşaret Dili](../SignLang/SignLang.md).
- Bağlantı koparsa `showLostConnection` overlay'i devreye girer; bkz. [Bağlantı Koptu](../LostConnection/LostConnection.md).
- Modül sırası bu ekranda tükenirse ThankYou'ya **statülü** geçilir (görüşme sonucu).
</content>
