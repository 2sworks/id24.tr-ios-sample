# VideoRecorder — Video kayıt (okuma metni)

Kullanıcı ekrandaki metni okurken kısa bir video (varsayılan 5 sn) çeker. Opsiyonel olarak
konuşma tanıma ile okunan metni doğrular. Video `manager.upload` ile **HTTP** üzerinden
yüklenir; başarıda `onCompleted`.

| | |
|---|---|
| Backend key | `SdkModules.videoRecord` |
| Rota | `SDKModuleRoute.videoRecorder` |
| Drop-in view | `SDKVideoRecorderView` (+ `SDKVideoCamera`) |
| ViewModel | `SDKVideoRecorderViewModel` |
| Bağımlılık | **HTTP** (`upload`) + opsiyonel konuşma tanıma (on-device) |

---

## VM API — `SDKVideoRecorderViewModel`

### State
| Üye | Tip | Erişim | Anlam |
|---|---|---|---|
| `videoData` | `Data?` | r/w | Çekilen video verisi |
| `videoURL` | `URL?` | r/w | Çekilen video dosya yolu |
| `uploadCompleted` | `Bool` | salt-okunur | Yükleme tamamlandı mı |
| `readingText` | `String?` | salt-okunur | Okunacak metin |
| `recognizedText` | `String` | salt-okunur | Tanınan metin (konuşma) |
| `speechSuccess` | `Bool` | salt-okunur | Metin eşleşti mi |
| `isTranscribing` | `Bool` | salt-okunur | Transkripsiyon sürüyor mu |

### Sabit
| Üye | Değer | Anlam |
|---|---|---|
| `videoTimeLimit` | `5.0` | Maksimum kayıt süresi (sn) |

### Girdi (metotlar)
| Metot | Etki |
|---|---|
| `updateReadingText(_ text: String)` | Okunacak metni günceller |
| `videoSelected(url: URL)` | Çekilen videoyu yükler (transkripsiyon + boyut kontrolü) |
| `deleteVideo()` | Çekilen videoyu siler (yeniden çekim) |
| `uploadVideo()` | Videoyu sunucuya gönderir (`manager.upload`) → `onCompleted` |

### Çıktı (closure)
| Üye | Ne zaman |
|---|---|
| `onCompleted: (() -> Void)?` | Yükleme başarılı |

---

## Sinyal zinciri

```
updateReadingText(_:)   → readingText (UI)
videoSelected(url:)      → transkripsiyon + boyut kontrolü (on-device) → videoData/videoURL
uploadVideo()            → manager.upload [HTTP] → onCompleted?()
host: → coordinator.advanceToNextModule() [modulePresented]
```

---

## Drop-in / Host VM / Custom

```swift
// Drop-in
case .videoRecorder: SDKVideoRecorderView()

// Host VM
final class VideoRecorderHostViewModel: HostModuleViewModel {
    let sdk = SDKVideoRecorderViewModel()
    override init() {
        super.init(); bridge(sdk)
        sdk.onCompleted = { [weak self] in self?.log("video_done") }
    }
    var prompt: String { sdk.readingText ?? "" }
    func picked(_ url: URL) { sdk.videoSelected(url: url) }
    func upload() { sdk.uploadVideo() }
}

// Custom (override)
registry.override(.videoRecorder) { MyVideoView() }

struct MyVideoView: View {
    @EnvironmentObject var coordinator: SDKFlowCoordinator
    @StateObject private var vm = SDKVideoRecorderViewModel()
    var body: some View {
        if let text = vm.readingText { Text(text) }
        // kayıt bitince:  vm.videoSelected(url: recordedURL)   ✅
        Button("Gönder") { vm.uploadVideo() }                  // ✅ manager.upload
            .disabled(vm.videoData == nil && vm.videoURL == nil)
            .onAppear { vm.onCompleted = { coordinator.advanceToNextModule() } } // ✅
        Button("Tekrar çek") { vm.deleteVideo() }
    }
}
```

## Notlar
- Video boyutu `manager.requestMaxBodySize`'ı aşarsa `videoSelected` reddeder; süre sınırı `videoTimeLimit` (5 sn).
- Konuşma doğrulama opsiyoneldir; `speechSuccess`/`recognizedText` yalnızca okuma-metni senaryosunda anlamlıdır.

---

## Sesli Okuma (Read-Aloud)

Bu modül ekranı açıldığında yönergesi otomatik seslendirilebilir. Mod **modül bazında**
seçilir; tam ayrıntı: [ReadAloud](../ReadAloud/ReadAloud.md).

- **Metin key'i:** `VideoRecorderTts`  ·  **Custom audio dosyası:** `VideoRecorderTts.m4a`
- **Native (Siri / sistem sesi):**
  ```swift
  SDKSpeechConfig.shared.setMode(.native, for: .videoRecord)
  ```
- **Custom audio (kendi kaydın):** bundle'a `VideoRecorderTts.m4a` koy →
  ```swift
  SDKSpeechConfig.shared.audioBundle = Bundle.main
  SDKSpeechConfig.shared.setMode(.customAudio, for: .videoRecord)   // dosya yoksa native'e düşer
  ```
- **Kapalı:** `SDKSpeechConfig.shared.setMode(.off, for: .videoRecord)`
- **Metni ez:** `SDKLocalization.shared.setOverride(key: .videoRecorderTts, language: .tr, value: "...")`

Seslendirme, ekran açılışında `SDKFlowHostView` tarafından otomatik yapılır — modül tarafında
ekstra kod gerekmez.

> ⚠️ Kayıt sırasında mikrofon açıktır; native okuma kayda karışabilir. Yönergeyi kayıt BAŞLAMADAN okutun ya da `.customAudio` / `.off` tercih edin.

</content>
