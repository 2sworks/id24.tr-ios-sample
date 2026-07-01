# Speech — Konuşma doğrulama

Kullanıcıya bir hedef kelime gösterir (ör. "Berlin"), mikrofonla söyletir ve Apple
**Speech** framework'ü ile tanır. Tanınan metin hedefle eşleşince doğrulanır;
`confirmSpeech()` sonucu **soket** üzerinden bildirir (`sendSpeechStatus`).

| | |
|---|---|
| Backend key | `SdkModules.speech` |
| Rota | `SDKModuleRoute.speech` |
| Drop-in view | `SDKSpeechRecView` |
| ViewModel | `SDKSpeechRecViewModel` |
| Bağımlılık | Speech framework (on-device) + **soket** (`sendSpeechStatus`) |

> `Info.plist` → `NSSpeechRecognitionUsageDescription` ve `NSMicrophoneUsageDescription`.

---

## VM API — `SDKSpeechRecViewModel`

### State (`@Published`, salt-okunur)
| Üye | Tip | Anlam |
|---|---|---|
| `targetWord` | `String` | Söylenmesi gereken kelime (varsayılan "Berlin") |
| `isRecording` | `Bool` | Kayıt sürüyor mu |
| `recognizedText` | `String` | Tanınan metin |
| `speechSuccess` | `Bool` | Hedefle eşleşti mi |

### Girdi (metotlar)
| Metot | Etki |
|---|---|
| `startRecording()` | Mikrofon + tanımayı başlatır |
| `stopRecording()` | Kaydı durdurur, sonucu değerlendirir |
| `confirmSpeech()` | **`manager.sendSpeechStatus` (soket)** + `onCompleted?()` |

### Çıktı (closure)
| Üye | Ne zaman |
|---|---|
| `onCompleted: (() -> Void)?` | Doğrulama tamamlanınca |

---

## Sinyal zinciri

```
startRecording()  → Speech tanıma (on-device) → recognizedText / speechSuccess
stopRecording()   → değerlendirme
confirmSpeech()   → manager.sendSpeechStatus [SOKET] → onCompleted?()
host: → coordinator.advanceToNextModule() [modulePresented]
```

---

## Drop-in / Host VM / Custom

```swift
// Drop-in
case .speech: SDKSpeechRecView()

// Host VM
final class SpeechHostViewModel: HostModuleViewModel {
    let sdk = SDKSpeechRecViewModel()
    override init() {
        super.init(); bridge(sdk)
        sdk.onCompleted = { [weak self] in self?.log("speech_done") }
    }
    var word: String { sdk.targetWord }
    var heard: String { sdk.recognizedText }
    func start() { sdk.startRecording() }
    func stop()  { sdk.stopRecording() }
}

// Custom (override)
registry.override(.speech) { MySpeechView() }

struct MySpeechView: View {
    @EnvironmentObject var coordinator: SDKFlowCoordinator
    @StateObject private var vm = SDKSpeechRecViewModel()
    var body: some View {
        Text("Söyleyin: \(vm.targetWord)")
        Text(vm.recognizedText)
        Button(vm.isRecording ? "Durdur" : "Konuş") {
            vm.isRecording ? vm.stopRecording() : vm.startRecording()
        }
        Button("Onayla") { vm.confirmSpeech() }              // ✅ sendSpeechStatus (soket)
            .disabled(!vm.speechSuccess)
            .onAppear { vm.onCompleted = { coordinator.advanceToNextModule() } } // ✅
    }
}
```

> **Bypass yok:** `confirmSpeech()` çağrılmadan ilerlerseniz `sendSpeechStatus` gitmez,
> backend konuşma doğrulamasını görmez.

## Notlar
- `targetWord` sunucudan/akıştan gelir; sabit değildir.
- Tanıma cihazda çalışır; yalnızca sonuç soketle bildirilir.

---

## Sesli Okuma (Read-Aloud)

Bu modül ekranı açıldığında yönergesi otomatik seslendirilebilir. Mod **modül bazında**
seçilir; tam ayrıntı: [ReadAloud](../ReadAloud/ReadAloud.md).

- **Metin key'i:** `SpeechTts`  ·  **Custom audio dosyası:** `SpeechTts.m4a`
- **Native (Siri / sistem sesi):**
  ```swift
  SDKSpeechConfig.shared.setMode(.native, for: .speech)
  ```
- **Custom audio (kendi kaydın):** bundle'a `SpeechTts.m4a` koy →
  ```swift
  SDKSpeechConfig.shared.audioBundle = Bundle.main
  SDKSpeechConfig.shared.setMode(.customAudio, for: .speech)   // dosya yoksa native'e düşer
  ```
- **Kapalı:** `SDKSpeechConfig.shared.setMode(.off, for: .speech)`
- **Metni ez:** `SDKLocalization.shared.setOverride(key: .speechTts, language: .tr, value: "...")`

Seslendirme, ekran açılışında `SDKFlowHostView` tarafından otomatik yapılır — modül tarafında
ekstra kod gerekmez.

> ⚠️ Bu modül KYC konuşma-**TANIMA** adımıdır (kullanıcı mikrofona okur). Read-aloud yalnızca YÖNERGEYİ okur; kullanıcı kaydederken sesle çakışmaması için gerekiyorsa `.off` seçin.

</content>
