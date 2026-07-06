# CallScreen — Görüntülü Görüşme

SDK'nın kalbi ve en karmaşık modülü: müşteri ile temsilci (agent) arasındaki **canlı WebRTC
görüşmesi**. Bekleme odası, çağrı kabul, SMS doğrulama, görüşme sırasında uzaktan NFC,
işaret dili kapısı ve bağlantı-koptu kurtarma — hepsi bu ekranda buluşur. Görüşme bittiğinde
sonuç statüsü ThankYou ekranına taşınır.

Altyapıyı anlamak için: [TURN & WebRTC](../../../docs/guides/turn-webrtc.md) ·
[WebSocket](../../../docs/guides/websocket.md)

← [Modül İndeksi](../Modules.md) · [README](../../../README.md)

---

## Bir Bakışta

| | |
|---|---|
| Backend key | `SdkModules.waitScreen` |
| Rota | `SDKModuleRoute.callScreen` |
| Drop-in view | `SDKCallScreenView` (+ `SDKVideoFeedRepresentable`) |
| ViewModel | `SDKCallScreenViewModel` |
| Dış dünya | **WebRTC** + **soket** (çağrı aksiyonları) + HTTP |
| Ses anahtarı | `CallScreenTts` |

> Önemli: Bu modül çalışırken **soket dinleyicisini coordinator'dan devralır.** Ekrandan
> ayrılırken `coordinator.restoreSocketListener()` ile geri verilir (terminate akışında
> otomatik yapılır).

## Kullanıcı Ne Yaşar?

1. Bekleme odasına düşer; sıradaki konumu ve tahmini bekleme süresini görür.
2. Temsilci aradığında çağrı ekranı gelir; kabul edince görüntülü görüşme başlar.
3. Görüşme sırasında temsilci SMS kodu isteyebilir, fotoğraf alabilir, uyarı/kimlik çemberi
   açabilir, hatta uzaktan NFC okuma başlatabilir.
4. Görüşme biter; sonuç (onaylandı/reddedildi/beklemede) ThankYou'da gösterilir.

---

## Kullanım — Drop-in Şiddetle Önerilir

```swift
// Hiçbir şey yazmayın; rota gelince SDK çizer:
case .callScreen: SDKCallScreenView()
```

WebRTC peer connection, ICE aday değişimi, data channel ve soket aksiyon eşlemesi VM içinde
sıkı bağlıdır — yeniden yazmaya değmez. Marka uyumu için önce [Tema](../../../docs/guides/theming.md)'yı deneyin.

## Kendi Tasarımınızla (Override) — Dikkatli İlerleyin

Yine de tasarımı değiştirmek isterseniz iki kesin kural vardır:
**(1)** video katmanlarını VM'den alın, **(2)** tüm çağrı eylemleri VM'den geçsin.

```swift
registry.override(.callScreen) { MyCallView() }

struct MyCallView: View {
    @EnvironmentObject var coordinator: SDKFlowCoordinator
    @StateObject private var vm = SDKCallScreenViewModel()

    var body: some View {
        ZStack {
            // WebRTC video katmanları — kendiniz peer connection KURMAYIN:
            if let remote = vm.remoteVideoView { UIViewWrapper(remote) }   // ✅
            if let local  = vm.localVideoView  { UIViewWrapper(local) }    // ✅

            VStack {
                Text("Sıra: \(vm.queuePosition)")
                if vm.callState == .waiting {
                    Button("Kabul Et") { vm.acceptCall() }                 // ✅ soket + WebRTC
                }
                TextField("SMS", text: $vm.smsCode)
                Button("Doğrula") { vm.verifySMS() }
                    .disabled(!vm.isSMSCodeValid)                          // ✅
                Button("Bitir") { vm.terminateCall(coordinator: coordinator) }  // ✅
                    .disabled(!vm.endCallEnabled)
            }
        }
        .onAppear { vm.checkSignLangIfNeeded() }
    }
}
```

---

## ViewModel Referansı — `SDKCallScreenViewModel`

### Tipler
```swift
public enum SDKCallState { case waiting, /* ... */ connected, ended }
public enum SDKCallNetworkQuality { case none, /* ... */ good, poor }
```

### Çağrı durumu (`@Published`, salt-okunur)
| Üye | Tip | Anlam |
|---|---|---|
| `callState` | `SDKCallState` | Bekliyor / bağlı / bitti |
| `queuePosition` | `String` | Sıradaki konum |
| `estimatedWait` | `String` | Tahmini bekleme |
| `networkQuality` | `SDKCallNetworkQuality` | Ağ kalitesi |
| `endCallEnabled` | `Bool` | "Görüşmeyi bitir" aktif mi (agent kilitleyebilir) |
| `callCompleted` | `Bool` | Görüşme tamamlandı mı |
| `socketThankYouStatus` | `ThankYouStatus?` | Soketten gelen sonuç statüsü |
| `photoTakenToast` | `String?` | "Fotoğraf alındı" bildirimi |
| `lostConnectionCallCompleted` | `Bool` | Kopma sonrası görüşme tamamlandı mı |

### SMS doğrulama
| Üye | Tip | Anlam |
|---|---|---|
| `smsCode` | `String` (r/w) | Girilen SMS kodu |
| `isSMSCodeValid` | `Bool` | Kod 6 haneli mi |

### Uzaktan NFC (temsilci tetikler)
| Üye | Tip | Anlam |
|---|---|---|
| `nfcStatusMessage` | `String` | NFC durum metni |
| `showNFCEdit` | `Bool` (r/w) | MRZ düzenleme ekranı |
| `nfcEditSerial / nfcEditBirth / nfcEditValid` | `String` (r/w) | Düzenlenebilir MRZ alanları |

### İşaret dili / kopma
| Üye | Tip | Anlam |
|---|---|---|
| `showSignLangGate` | `Bool` (r/w) | İşaret dili kapısını göster |
| `showLostConnection` | `Bool` (r/w) | Bağlantı-koptu overlay'i |

### Video (WebRTC)
| Üye | Anlam |
|---|---|
| `remoteVideoView: UIView?` | Uzak (temsilci) video katmanı |
| `localVideoView: UIView?` | Yerel (kullanıcı) video katmanı |

### Metotlar
| Metot | Etki |
|---|---|
| `checkSignLangIfNeeded()` | `connectToSignLang` ise işaret dili kapısını açar |
| `signLangCompleted()` | İşaret dili adımını tamamlar |
| `acceptCall()` | Çağrıyı kabul eder (`manager.acceptCall`) — TURN kimliği + SDP offer |
| `terminateCall(coordinator:)` | Görüşmeyi bitirir + dinleyiciyi geri verir + ThankYou'ya geçer |
| `verifySMS()` | SMS kodunu doğrular (`manager.smsVerification`) |
| `startRemoteNFC(birthDate:validDate:docNo:)` | Uzaktan NFC okumayı başlatır |
| `saveAndRestartRemoteNFC(serial:birth:valid:)` | MRZ'yi düzeltip NFC'yi yeniden başlatır |
| `handleReconnectCompleted()` / `handleReconnectCompletedWithStatus(...)` | Kopma sonrası kurtarma |
| `cleanup()` | Kaynakları temizler (ekrandan ayrılırken) |

### Soket dinleyici
```swift
nonisolated public func listenSocketMessage(message: SDKCallActions)
```
CallScreen aktifken soket mesajlarını **doğrudan bu VM** işler (coordinator yerine).
Aksiyonların tam listesi: [WebSocket → Aksiyon Kataloğu](../../../docs/guides/websocket.md#aksiyon-kataloğu--sdkcallactions).

## Sinyal Zinciri — Perde Arkası

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

## Host VM ile Gözlem (Composition) — Güvenli

```swift
@MainActor
final class CallHostViewModel: HostModuleViewModel {
    let sdk = SDKCallScreenViewModel()
    override init() { super.init(); bridge(sdk) }
    var state: SDKCallState { sdk.callState }
    var queue: String { sdk.queuePosition }
    var quality: SDKCallNetworkQuality { sdk.networkQuality }
}
```

---

## Sesli Okuma (Read-Aloud)

Ekran açıldığında yönerge otomatik seslendirilebilir (`SDKFlowHostView` yapar, kod gerekmez).

```swift
SDKSpeechConfig.shared.setMode(.native, for: .waitScreen)         // Siri/sistem sesi
// veya kendi kaydınız: bundle'a CallScreenTts.m4a koyun →
SDKSpeechConfig.shared.audioBundle = Bundle.main
SDKSpeechConfig.shared.setMode(.customAudio, for: .waitScreen)    // dosya yoksa native'e düşer
```

> ⚠️ Okuma, WebRTC sesiyle çakışmasın diye `.duckOthers` ile kısılır; canlı görüşme
> başladıktan sonra bu modülde `.off` önerilir.

Metni ezmek: `SDKLocalization.shared.setOverride(key: .callScreenTts, language: .tr, value: "...")`
· Tüm ayrıntı: [ReadAloud](../ReadAloud.md)

## Sık Sorulanlar & Dikkat Edilecekler

- **`terminateCall(coordinator:)`'ı asla atlamayın** — hem soketi bilgilendirir hem
  dinleyiciyi coordinator'a geri verir; atlarsanız sonraki ekranlar soket mesajı almaz.
- **İşaret dili:** `signLangSupport: true` ise `checkSignLangIfNeeded()` kapıyı açar —
  [SignLang rehberi](../SignLang/SignLang.md).
- **Bağlantı koparsa:** `showLostConnection` overlay'i devreye girer —
  [LostConnection rehberi](../LostConnection/LostConnection.md).
- **Görüşme kurulamıyor / tek yönlü medya:** Neredeyse her zaman TURN kimlik sorunudur —
  [TURN & WebRTC → Sorun Giderme](../../../docs/guides/turn-webrtc.md#sorun-giderme).
- **Simülatör:** Kamera yok — görüşme yalnızca gerçek cihazda test edilir.
