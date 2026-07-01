# IdCardOVD — Kimlik (OVD / hologram doğrulama)

IdCard'ın gelişmiş varyantı: hizalama + hologram (OVD) doğrulaması yapar. Kamera
karelerini değerlendirir (glare/texture/rainbow skorları cihazda), adım adım ilerler ve
sonucu `uploadIdPhoto` ile yükler.

| | |
|---|---|
| Backend key | `SdkModules.idcard_w_ovd` |
| Rota | `SDKModuleRoute.idCardOVD` |
| Drop-in view | `SDKIdCardOVDView` |
| ViewModel | `SDKIdCardOVDViewModel` |
| Bağımlılık | on-device skor analizi + **HTTP** (`uploadIdPhoto`) |

---

## VM API — `SDKIdCardOVDViewModel`

### Tip
```swift
public enum OVDStep: Int, CaseIterable {
    case frontAlign, ..., completed
    public var isCompleted: Bool { self == .completed }
}
```

### State (`@Published`, salt-okunur)
| Üye | Tip | Anlam |
|---|---|---|
| `step` | `OVDStep` | Mevcut adım |
| `canContinue` | `Bool` | Devam edilebilir mi |
| `isUploading` | `Bool` | Yükleme sürüyor mu |
| `rainbowProgress` | `Double` | Hologram adımı ilerlemesi |

### Ayar
| Üye | Varsayılan | Anlam |
|---|---|---|
| `requiresHologramStep` | `true` | Hologram adımı zorunlu mu |

### Hesaplanan
| Üye | Anlam |
|---|---|
| `progress: Double` | Genel ilerleme (0–1) |
| `instruction: String` | Mevcut adımın kullanıcı talimatı |

### Girdi (metotlar)
| Metot | Etki |
|---|---|
| `ingest(ciImage:roi:)` | Canlı kareyi değerlendirir (glare/texture/rainbow skorları) |
| `forceCapture(ciImage:roi:)` | Skorları beklemeden zorla yakalar |
| `capture(image:)` | Yakalanan görseli işler (`makeUIImage` + `processCaptured`) |
| `advance()` | Sonraki adıma geçer; son adımda **`onCompleted?()`** |
| `reset()` | Akışı başa alır |
| `requestSkip()` | `onSkipRequested?()` |

### Çıktı (closure)
| Üye | Ne zaman |
|---|---|
| `onCompleted: (() -> Void)?` | Tüm OVD adımları + yükleme bittiğinde |
| `onSkipRequested: (() -> Void)?` | Atlama istendiğinde |

---

## Sinyal zinciri

```
ingest(ciImage:roi:)  → manager.ovdGlareScore / ovdTextureMean / ovdRainbowScoreDetailed (on-device)
capture(image:)       → manager.makeUIImage + processCaptured + uploadIdPhoto [HTTP]
advance()  (son adım) → onCompleted?()  → host: coordinator.advanceToNextModule() [modulePresented]
```

---

## Drop-in / Host VM / Custom

```swift
// Drop-in
case .idCardOVD: SDKIdCardOVDView()

// Host VM (gözlem)
final class IdCardOVDHostViewModel: HostModuleViewModel {
    let sdk = SDKIdCardOVDViewModel()
    override init() {
        super.init(); bridge(sdk)
        sdk.onCompleted   = { [weak self] in self?.log("ovd_done") }
        sdk.onSkipRequested = { [weak self] in self?.log("ovd_skip") }
    }
    var instruction: String { sdk.instruction }
    var progress: Double { sdk.progress }
}
```

Custom tasarım (override) — kamera akışını siz çizin ama analizi VM'e verin:
```swift
registry.override(.idCardOVD) { MyOVDView() }

struct MyOVDView: View {
    @EnvironmentObject var coordinator: SDKFlowCoordinator
    @StateObject private var vm = SDKIdCardOVDViewModel()
    var body: some View {
        // her kamera karesi:  vm.ingest(ciImage: ci, roi: roi)   ✅ on-device skor
        // yakalama:           vm.capture(image: img)             ✅ upload
        // adım butonu:        vm.advance()
        Text(vm.instruction)
            .onAppear { vm.onCompleted = { coordinator.advanceToNextModule() } } // ✅
    }
}
```

> **Bypass yok:** Skorları kendiniz hesaplayıp `uploadIdPhoto`'yu atlamayın; `vm.ingest`/
> `vm.capture`/`vm.advance` zincirini kullanın, aksi halde OVD doğrulama backend'e ulaşmaz.

## Notlar
- `requiresHologramStep = false` yaparsanız hologram adımı atlanır (düşük donanımlı senaryolar).
- `ingest` her karede çağrılır; pahalı olduğundan kamera frame rate'ini makul tutun.

---

## Sesli Okuma (Read-Aloud)

Bu modül ekranı açıldığında yönergesi otomatik seslendirilebilir. Mod **modül bazında**
seçilir; tam ayrıntı: [ReadAloud](../ReadAloud/ReadAloud.md).

- **Metin key'i:** `IdCardOVDTts`  ·  **Custom audio dosyası:** `IdCardOVDTts.m4a`
- **Native (Siri / sistem sesi):**
  ```swift
  SDKSpeechConfig.shared.setMode(.native, for: .idcard_w_ovd)
  ```
- **Custom audio (kendi kaydın):** bundle'a `IdCardOVDTts.m4a` koy →
  ```swift
  SDKSpeechConfig.shared.audioBundle = Bundle.main
  SDKSpeechConfig.shared.setMode(.customAudio, for: .idcard_w_ovd)   // dosya yoksa native'e düşer
  ```
- **Kapalı:** `SDKSpeechConfig.shared.setMode(.off, for: .idcard_w_ovd)`
- **Metni ez:** `SDKLocalization.shared.setOverride(key: .idCardOVDTts, language: .tr, value: "...")`

Seslendirme, ekran açılışında `SDKFlowHostView` tarafından otomatik yapılır — modül tarafında
ekstra kod gerekmez.

</content>
