# Liveness — Canlılık Testi

"Karşımdaki gerçek ve canlı bir insan mı, yoksa bir fotoğraf/video mu?" sorusunu cevaplar.
Kullanıcıya sırayla hareket talimatları verilir — **göz kırp, gülümse, sola bak, sağa bak** —
ve her adım bir doğrulama karesiyle kanıtlanır. Adım sırasını sunucu belirler (her oturumda
farklı olabilir), böylece önceden kaydedilmiş videoyla aldatma zorlaşır.

← [Modül İndeksi](../Modules.md) · [README](../../../README.md)

---

## Bir Bakışta

| | |
|---|---|
| Backend key | `SdkModules.livenessDetection` |
| Rota | `SDKModuleRoute.liveness` |
| Drop-in view | `SDKLivenessView` |
| ViewModel | `SDKLivenessViewModel` |
| Dış dünya | Adım API'si (`getNextLivenessTest`) + **HTTP** (kare + isteğe bağlı video) |
| Ses anahtarı | `LivenessTts` |

## Kullanıcı Ne Yaşar?

1. Ön kamera açılır; ekranda ilk talimat belirir (ör. "Gözlerinizi kırpın").
2. Hareketi yapar; doğrulama karesi arka planda yüklenir, sıradaki talimat gelir.
3. Tüm adımlar bitince — sunucu ekran kaydı istiyorsa — oturum videosu da yüklenir.
4. Akış otomatik ilerler.

---

## Hazır Ekranla Kullanım (Drop-in)

Hiçbir şey yazmayın; rota gelince `SDKLivenessView` çizilir.

## Kendi Tasarımınızla (Override)

Talimat sunumu ve kamera sizin; adım sırası, kare doğrulama ve yükleme SDK'da kalır:

```swift
registry.override(.liveness) { MyLivenessView() }

struct MyLivenessView: View {
    @EnvironmentObject var coordinator: SDKFlowCoordinator
    @StateObject private var vm = SDKLivenessViewModel()

    var body: some View {
        VStack {
            Text(vm.stepInstruction)                    // "Göz kırpın" vb.
            MyCameraFeed { frame in
                // hareket algılandığında doğrulama karesi:
                vm.uploadFrame(image: frame)            // ✅ HTTP
            }
        }
        .onAppear {
            vm.onCompleted = { coordinator.advanceToNextModule() }   // ✅
            vm.fetchNextStep()                          // ✅ ilk adımı sunucudan al
        }
        // tüm adımlar bitince: vm.uploadVideo(videoData: data)      // ✅
    }
}
```

> ❌ **Bypass yapmayın:** Adımları kendi mantığınızla "geçti" sayıp ilerlemeyin — her adım
> `uploadFrame`, kapanış `uploadVideo` ile kanıtlanmalıdır.
> Kural: [bypass yok](../../../docs/guides/customization.md#bypass-yok-kuralı).

---

## ViewModel Referansı — `SDKLivenessViewModel`

### State (`@Published`, salt-okunur)
| Üye | Tip | Anlam |
|---|---|---|
| `currentStep` | `LivenessTestStep?` | Mevcut adım (`turnLeft/turnRight/blinkEyes/smile/completed`) |
| `stepInstruction` | `String` | Adım talimatı (ör. "Göz kırpın") |
| `allStepsCompleted` | `Bool` | Tüm adımlar bitti mi |

### Hesaplanan / ayar
| Üye | Anlam |
|---|---|
| `isRecordingEnabled: Bool` | Video kaydı açık mı (`manager.livenessRecordingEnabled` — sunucudan) |
| `maxVideoSize: Int` | İzinli en büyük video boyutu |
| `allowBlink / allowSmile / allowLeft / allowRight` | Hangi adımlar etkin (r/w) |

### Metotlar
| Metot | Etki |
|---|---|
| `fetchNextStep()` | Sıradaki adımı sunucudan alır (`getNextLivenessTest`) |
| `uploadFrame(image: UIImage)` | Mevcut adımın doğrulama karesini yükler |
| `uploadVideo(videoData: Data)` | Adımlar bitince videoyu yükler; kayıt kapalıysa doğrudan `onCompleted` |
| `resetTest()` | Testi başa alır |

### Closure'lar
| Üye | Ne zaman |
|---|---|
| `onCompleted: (() -> Void)?` | Tüm akış (adımlar + varsa video) tamamlandı |

## Sinyal Zinciri — Perde Arkası

```
fetchNextStep()          → manager.getNextLivenessTest  → currentStep / stepInstruction
uploadFrame(image:)      → manager.uploadIdPhoto [HTTP]  (her adım doğrulaması)
(adımlar bitti) → uploadVideo(videoData:)
     ├─ kayıt açık   → manager.uploadLivenessVideo [HTTP] → onCompleted?()
     └─ kayıt kapalı → onCompleted?()   (doğrudan)
host: → coordinator.advanceToNextModule() [modulePresented]
```

## Host VM ile Gözlem (Composition)

```swift
@MainActor
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
```

---

## Sesli Okuma (Read-Aloud)

Ekran açıldığında yönerge otomatik seslendirilebilir (`SDKFlowHostView` yapar, kod gerekmez).

```swift
SDKSpeechConfig.shared.setMode(.native, for: .livenessDetection)        // Siri/sistem sesi
// veya kendi kaydınız: bundle'a LivenessTts.m4a koyun →
SDKSpeechConfig.shared.audioBundle = Bundle.main
SDKSpeechConfig.shared.setMode(.customAudio, for: .livenessDetection)   // dosya yoksa native'e düşer
```

Metni ezmek: `SDKLocalization.shared.setOverride(key: .livenessTts, language: .tr, value: "...")`
· Tüm ayrıntı: [ReadAloud](../ReadAloud.md)

## Sık Sorulanlar & Dikkat Edilecekler

- **Video kaydı zorunlu mu?** Sunucu belirler (`liveness_recording`). `isRecordingEnabled`
  `false` ise `uploadVideo` boş `Data` ile çağrılabilir; VM yine `onCompleted`'a düşer.
- **Adım seti:** `allowBlink/allowSmile/allowLeft/allowRight` ile hangi hareketlerin
  isteneceğini host daraltabilir.
- **Adım sırası neden rastgele?** `RoomResponse.liveness` dizisi sırayı belirler —
  replay saldırılarını zorlaştırmak için oturum başına değişebilir.
