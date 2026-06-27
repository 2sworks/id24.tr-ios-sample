# Selfie — Selfie çekimi + yüz tespiti

Ön kameradan selfie alır, **cihaz üzerinde** yüz tespiti yapar (`detectHumanFace`) ve
görseli `uploadIdPhoto` ile yükler. Karşılaştırma denemeleri tükenip atlamaya izin varsa
`onSkipRequested`.

| | |
|---|---|
| Backend key | `SdkModules.selfie` |
| Rota | `SDKModuleRoute.selfie` |
| Drop-in view | `SDKSelfieView` |
| ViewModel | `SDKSelfieViewModel` |
| Bağımlılık | yüz tespiti (on-device) + **HTTP** (`uploadIdPhoto`) |

---

## VM API — `SDKSelfieViewModel`

### State
| Üye | Tip | Erişim | Anlam |
|---|---|---|---|
| `selfieImage` | `UIImage?` | r/w | Çekilen selfie |
| `faceDetected` | `Bool` | salt-okunur | Yüz tespit edildi mi |
| `canContinue` | `Bool` | salt-okunur | Devam edilebilir mi |
| `resultText` | `String` | salt-okunur | Sonuç metni |

### Girdi (metotlar)
| Metot | Etki |
|---|---|
| `processSelfie(image: UIImage)` | Yüz tespiti (`detectHumanFace`) → `uploadIdPhoto` |
| `reset()` | Durumu sıfırlar (yeniden çekim) |

### Çıktı (closure)
| Üye | Ne zaman |
|---|---|
| `onSkipRequested: (() -> Void)?` | Karşılaştırma tükenip skip izinliyse |

---

## Sinyal zinciri

```
processSelfie(image:)  → manager.detectHumanFace (on-device) → uploadIdPhoto [HTTP]
                       → (selfieComparisonCount tükendi & skip izinli) → onSkipRequested?()
host: canContinue → coordinator.advanceToNextModule() [modulePresented]
```

---

## Drop-in / Host VM / Custom

```swift
// Drop-in
case .selfie: SDKSelfieView()

// Host VM (pilot — referans desen)
final class SelfieHostViewModel: HostModuleViewModel {
    let sdk = SDKSelfieViewModel()
    override init() {
        super.init(); bridge(sdk)
        sdk.onSkipRequested = { [weak self] in self?.log("selfie_skip") }
    }
    var canContinue: Bool { sdk.canContinue }
    func process(_ img: UIImage) { log("selfie_scan"); sdk.processSelfie(image: img) }
}

// Custom (override)
registry.override(.selfie) { MySelfieView() }

struct MySelfieView: View {
    @EnvironmentObject var coordinator: SDKFlowCoordinator
    @StateObject private var vm = SDKSelfieViewModel()
    var body: some View {
        // kamera → çekilen görsel:
        // vm.processSelfie(image: captured)              ✅ yüz tespiti + upload
        Button("Devam") { coordinator.advanceToNextModule() }   // ✅
            .disabled(!vm.canContinue)
            .onAppear { vm.onSkipRequested = { coordinator.skipCurrentModule() } }
    }
}
```

## Notlar
- Yüz tespit edilmezse `faceDetected = false` kalır, `canContinue` false olur — kullanıcıyı yeniden çekime yönlendirin (`reset()`).
- Bu modül Default UI migrasyonunun pilotuydu; composition desen örneği olarak referans alın.
</content>
