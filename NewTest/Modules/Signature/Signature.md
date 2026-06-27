# Signature — İmza

Kullanıcı parmağıyla imza çizer (`SDKSignatureCanvas`), imza görseli `uploadIdPhoto` ile
**HTTP** üzerinden yüklenir. Başarıda `onCompleted`.

| | |
|---|---|
| Backend key | `SdkModules.signature` |
| Rota | `SDKModuleRoute.signature` |
| Drop-in view | `SDKSignatureView` (+ `SDKSignatureCanvas`) |
| ViewModel | `SDKSignatureViewModel` |
| Bağımlılık | **HTTP** (`uploadIdPhoto`) — soket/WebRTC yok |

> Çizim için `SwiftSignatureView` (SPM) kullanılır.

---

## VM API — `SDKSignatureViewModel`

### State
| Üye | Tip | Erişim | Anlam |
|---|---|---|---|
| `signatureDrawn` | `Bool` | r/w | En az bir çizim yapıldı mı |
| `uploadCompleted` | `Bool` | salt-okunur | Yükleme tamamlandı mı |

### Girdi (metotlar)
| Metot | Etki |
|---|---|
| `signatureDidDraw()` | Çizim başladığını işaretler (`signatureDrawn = true`) |
| `clearSignature()` | Tuvali temizler |
| `uploadSignature(image: UIImage)` | İmza görselini yükler (`uploadIdPhoto`) → `onCompleted` |

### Çıktı (closure)
| Üye | Ne zaman |
|---|---|
| `onCompleted: (() -> Void)?` | Yükleme başarılı |

---

## Sinyal zinciri

```
signatureDidDraw()              → signatureDrawn = true (UI durumu)
uploadSignature(image:)         → manager.uploadIdPhoto [HTTP] → onCompleted?()
host: → coordinator.advanceToNextModule() [modulePresented]
```

---

## Drop-in / Host VM / Custom

```swift
// Drop-in
case .signature: SDKSignatureView()

// Host VM
final class SignatureHostViewModel: HostModuleViewModel {
    let sdk = SDKSignatureViewModel()
    override init() {
        super.init(); bridge(sdk)
        sdk.onCompleted = { [weak self] in self?.log("signature_done") }
    }
    var canUpload: Bool { sdk.signatureDrawn }
    func upload(_ img: UIImage) { sdk.uploadSignature(image: img) }
}

// Custom (override) — kendi tuvalinizi kullanabilirsiniz, ama yükleme VM'den geçsin
registry.override(.signature) { MySignatureView() }

struct MySignatureView: View {
    @EnvironmentObject var coordinator: SDKFlowCoordinator
    @StateObject private var vm = SDKSignatureViewModel()
    var body: some View {
        // kendi imza tuvaliniz; çizim olduğunda: vm.signatureDidDraw()
        Button("Temizle") { vm.clearSignature() }
        Button("Gönder") {
            // tuvali UIImage'a render edin → renderedImage
            vm.uploadSignature(image: renderedImage)         // ✅ uploadIdPhoto
        }
        .disabled(!vm.signatureDrawn)
        .onAppear { vm.onCompleted = { coordinator.advanceToNextModule() } } // ✅
    }
}
```

## Notlar
- Kendi tuvalinizi kullansanız bile imza görselini SDK'ya `uploadSignature` ile verin; kendi POST'unuzu atmayın (bypass).
- `clearSignature()` sonrası `signatureDrawn` tekrar `false` olur, "Gönder" pasifleşir.
</content>
