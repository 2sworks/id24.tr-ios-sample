# VideoRecorder — Kısa Video Kaydı

Kullanıcı, ekrandaki metni sesli okurken kısa bir video çeker (varsayılan 5 sn). Sunucu
istiyorsa, okunan metin **konuşma tanıma ile doğrulanır** — böylece videonun gerçekten o
oturumda ve o kişi tarafından çekildiği kanıtlanır. Video HTTP ile yüklenir.

← [Modül İndeksi](../Modules.md) · [README](../../../README.md)

---

## Bir Bakışta

| | |
|---|---|
| Backend key | `SdkModules.videoRecord` |
| Rota | `SDKModuleRoute.videoRecorder` |
| Drop-in view | `SDKVideoRecorderView` (+ `SDKVideoCamera`) |
| ViewModel | `SDKVideoRecorderViewModel` |
| Dış dünya | **HTTP** (`upload`) + isteğe bağlı konuşma doğrulama |
| Ses anahtarı | `VideoRecorderTts` |

## Kullanıcı Ne Yaşar?

1. Ekranda okunacak metni görür (metin sunucudan gelir).
2. Kayda başlar, metni sesli okur; süre dolunca kayıt biter.
3. (Sesli doğrulama açıksa) okunan metin arka planda eşleştirilir; tutmuyorsa yeniden çeker.
4. "Gönder" ile video yüklenir, akış ilerler.

---

## Hazır Ekranla Kullanım (Drop-in)

Hiçbir şey yazmayın; rota gelince `SDKVideoRecorderView` çizilir.

## Kendi Tasarımınızla (Override)

Kamera/kayıt UI'ı sizin; transkripsiyon, boyut kontrolü ve yükleme SDK'da kalır:

```swift
registry.override(.videoRecorder) { MyVideoView() }

struct MyVideoView: View {
    @EnvironmentObject var coordinator: SDKFlowCoordinator
    @StateObject private var vm = SDKVideoRecorderViewModel()

    var body: some View {
        VStack {
            if let text = vm.readingText { Text(text) }       // okunacak metin
            MyRecorderView { recordedURL in
                vm.videoSelected(url: recordedURL)            // ✅ transkripsiyon + kontrol
            }
            Button("Tekrar çek") { vm.deleteVideo() }
            Button("Gönder") { vm.uploadVideo() }             // ✅ manager.upload
                .disabled(vm.videoData == nil && vm.videoURL == nil)
        }
        .onAppear { vm.onCompleted = { coordinator.advanceToNextModule() } }  // ✅
    }
}
```

---

## ViewModel Referansı — `SDKVideoRecorderViewModel`

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
| `videoTimeLimit` | `5.0` | Maksimum kayıt süresi (sn) — sunucu farklı süre gönderebilir |

### Metotlar
| Metot | Etki |
|---|---|
| `updateReadingText(_ text: String)` | Okunacak metni günceller |
| `videoSelected(url: URL)` | Videoyu işler (transkripsiyon + boyut kontrolü) |
| `deleteVideo()` | Videoyu siler (yeniden çekim) |
| `uploadVideo()` | Videoyu sunucuya gönderir → `onCompleted` |

### Closure'lar
| Üye | Ne zaman |
|---|---|
| `onCompleted: (() -> Void)?` | Yükleme başarılı |

## Sinyal Zinciri — Perde Arkası

```
updateReadingText(_:)   → readingText (UI)
videoSelected(url:)     → transkripsiyon + boyut kontrolü (cihazda) → videoData/videoURL
uploadVideo()           → manager.upload [HTTP] → onCompleted?()
host: → coordinator.advanceToNextModule() [modulePresented]
```

## Host VM ile Gözlem (Composition)

```swift
@MainActor
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
```

---

## Sesli Okuma (Read-Aloud)

Ekran açıldığında yönerge otomatik seslendirilebilir (`SDKFlowHostView` yapar, kod gerekmez).

```swift
SDKSpeechConfig.shared.setMode(.native, for: .videoRecord)        // Siri/sistem sesi
// veya kendi kaydınız: bundle'a VideoRecorderTts.m4a koyun →
SDKSpeechConfig.shared.audioBundle = Bundle.main
SDKSpeechConfig.shared.setMode(.customAudio, for: .videoRecord)   // dosya yoksa native'e düşer
```

> ⚠️ Kayıt sırasında mikrofon açıktır; native okuma kayda karışabilir. Yönergeyi kayıt
> **başlamadan** okutun ya da bu modülde `.customAudio` / `.off` tercih edin.

Metni ezmek: `SDKLocalization.shared.setOverride(key: .videoRecorderTts, language: .tr, value: "...")`
· Tüm ayrıntı: [ReadAloud](../ReadAloud.md)

## Sık Sorulanlar & Dikkat Edilecekler

- **Sesli doğrulama nasıl açılır?** Sunucu tarafından (`video_record_speech` bayrağı) —
  okunacak metin, eşleşme eşiği ve süre de sunucudan gelir
  ([Sunucu & API](../../../docs/guides/server-api.md#roomresponse--akışı-şekillendiren-alanlar)).
- **Video reddediliyor:** Boyut `manager.requestMaxBodySize`'ı aşıyorsa `videoSelected`
  kabul etmez; süreyi ve çözünürlüğü düşürün.
- **`speechSuccess` ne zaman anlamlı?** Yalnızca okuma-metni senaryosunda; doğrulama
  kapalıysa bu alanları yok sayın.
