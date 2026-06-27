# Liveness — Canlılık tespiti

Kullanıcıya adım adım hareket talimatı verir (göz kırp, gülümse, sola/sağa bak), her adımı
kare yükleyerek doğrular. Tüm adımlar bitince — kayıt açıksa video yüklenir
(`uploadLivenessVideo`), kapalıysa doğrudan `onCompleted`.

| | |
|---|---|
| Backend key | `SdkModules.livenessDetection` |
| Rota | `SDKModuleRoute.liveness` |
| Drop-in view | `SDKLivenessView` |
| ViewModel | `SDKLivenessViewModel` |
| Bağımlılık | adım API (`getNextLivenessTest`) + **HTTP** (frame `uploadIdPhoto` / video `uploadLivenessVideo`) |

---

## VM API — `SDKLivenessViewModel`

### State (`@Published`, salt-okunur)
| Üye | Tip | Anlam |
|---|---|---|
| `currentStep` | `LivenessTestStep?` | Mevcut adım (nil = yok) |
| `stepInstruction` | `String` | Adım talimatı (ör. "Göz kırpın") |
| `allStepsCompleted` | `Bool` | Tüm adımlar bitti mi |

### Hesaplanan / ayar
| Üye | Anlam |
|---|---|
| `isRecordingEnabled: Bool` | Video kaydı açık mı (`manager.livenessRecordingEnabled`) |
| `maxVideoSize: Int` | İzinli en büyük video boyutu |
| `allowBlink / allowSmile / allowLeft / allowRight` | Hangi adımların etkin olduğu (r/w) |

### Girdi (metotlar)
| Metot | Etki |
|---|---|
| `fetchNextStep()` | Sıradaki adımı sunucudan alır (`getNextLivenessTest`) |
| `uploadFrame(image: UIImage)` | Mevcut adımın doğrulama karesini yükler (`uploadIdPhoto`) |
| `uploadVideo(videoData: Data)` | Tüm adımlar bitince videoyu yükler (`uploadLivenessVideo`); kayıt kapalıysa direkt `onCompleted` |
| `resetTest()` | Testi başa alır (`resetLivenessTest`) |

### Çıktı (closure)
| Üye | Ne zaman |
|---|---|
| `onCompleted: (() -> Void)?` | Tüm akış (adımlar + varsa video) tamamlanınca |

---

## Sinyal zinciri

```
fetchNextStep()          → manager.getNextLivenessTest  → currentStep / stepInstruction
uploadFrame(image:)      → manager.uploadIdPhoto [HTTP]  (her adım doğrulaması)
(adımlar bitti) → uploadVideo(videoData:)
     ├─ kayıt açık   → manager.uploadLivenessVideo [HTTP] → onCompleted?()
     └─ kayıt kapalı → onCompleted?()   (doğrudan)
host: → coordinator.advanceToNextModule() [modulePresented]
```

---

## Drop-in / Host VM / Custom

```swift
// Drop-in
case .liveness: SDKLivenessView()

// Host VM
final class LivenessHostViewModel: HostModuleViewModel {
    let sdk = SDKLivenessViewModel()
    override init() {
        super.init(); bridge(sdk)
        sdk.onCompleted = { [weak self] in self?.log("liveness_done") }
    }
    var instruction: String { sdk.stepInstruction }
    func next() { sdk.fetchNextStep() }
    func sendFrame(_ img: UIImage) { sdk.uploadFrame(image: img) }
}

// Custom (override)
registry.override(.liveness) { MyLivenessView() }

struct MyLivenessView: View {
    @EnvironmentObject var coordinator: SDKFlowCoordinator
    @StateObject private var vm = SDKLivenessViewModel()
    var body: some View {
        Text(vm.stepInstruction)
        // adım doğrulandığında:  vm.uploadFrame(image: frame)   ✅
        // tüm adımlar bitince:    vm.uploadVideo(videoData: data) ✅
        .onAppear {
            vm.onCompleted = { coordinator.advanceToNextModule() }   // ✅
            vm.fetchNextStep()
        }
    }
}
```

> **Bypass yok:** Adımları kendi mantığınızla "geçti" sayıp `advanceToNextModule`'e
> atlamayın; her adım `uploadFrame`, kapanış `uploadVideo` ile doğrulanmalı.

## Notlar
- `isRecordingEnabled` `false` ise `uploadVideo` boş `Data` ile çağrılabilir; VM yine `onCompleted`'a düşer.
- `allowBlink/allowSmile/...` ile hangi adımların isteneceğini host belirleyebilir.
</content>
