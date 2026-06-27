# AddressConfirm — Adres onayı

Kullanıcı adresini girer ve bir kanıt belgesi ekler (foto **veya** PDF). `submit()` adres +
belgeyi **HTTP** üzerinden yükler (`uploadAddressInfo` / `uploadAddressInfoWithPdf`);
başarıda `onCompleted`.

| | |
|---|---|
| Backend key | `SdkModules.addressConf` |
| Rota | `SDKModuleRoute.addressConfirm` |
| Drop-in view | `SDKAddressConfirmView` |
| ViewModel | `SDKAddressConfirmViewModel` |
| Bağımlılık | **HTTP** (foto: `uploadAddressInfo`, PDF: `uploadAddressInfoWithPdf`) |

---

## VM API — `SDKAddressConfirmViewModel`

### State (`@Published`)
| Üye | Tip | Anlam |
|---|---|---|
| `addressText` | `String` | Girilen adres |
| `docPhoto` | `UIImage?` | Belge fotoğrafı |
| `pdfData` | `Data?` | Belge PDF'i |
| `showDocumentOptions` | `Bool` | Belge kaynağı seçim sheet'i |
| `showScanner` | `Bool` | Kamera/tarayıcı açık mı |
| `showPDFPicker` | `Bool` | PDF seçici açık mı |

### Hesaplanan
| Üye | Anlam |
|---|---|
| `isAddressValid: Bool` | Adres ≥ 10 karakter mi |
| `canSubmit: Bool` | Adres geçerli **ve** (foto veya PDF) var mı |
| `maxPDFSizeMB: Int` | İzinli en büyük PDF (`manager.maxAddressPDFFileSize`) |

### Girdi (metotlar)
| Metot | Etki |
|---|---|
| `openScanner()` | Belge tarayıcısını açar |
| `openPDFPicker()` | PDF seçiciyi açar |
| `photoSelected(_ image: UIImage)` | Seçilen fotoğrafı set eder |
| `pdfSelectedFromURL(_ url: URL)` | URL'den PDF yükler |
| `pdfSelected(_ data: Data, preview: UIImage?)` | PDF verisini set eder |
| `submit()` | Adres + belgeyi yükler → `onCompleted` |

### Çıktı (closure)
| Üye | Ne zaman |
|---|---|
| `onCompleted: (() -> Void)?` | Yükleme başarılı |

---

## Sinyal zinciri

```
photoSelected / pdfSelected...  → docPhoto / pdfData (UI durumu)
submit()
   ├─ PDF var  → manager.uploadAddressInfoWithPdf [HTTP]
   └─ foto var → manager.uploadAddressInfo        [HTTP]
                                   → onCompleted?()
host: → coordinator.advanceToNextModule() [modulePresented]
```

---

## Drop-in / Host VM / Custom

```swift
// Drop-in
case .addressConfirm: SDKAddressConfirmView()

// Host VM
final class AddressHostViewModel: HostModuleViewModel {
    let sdk = SDKAddressConfirmViewModel()
    override init() {
        super.init(); bridge(sdk)
        sdk.onCompleted = { [weak self] in self?.log("address_done") }
    }
    var canSubmit: Bool { sdk.canSubmit }
    func submit() { sdk.submit() }
}

// Custom (override) — SampleApp'te canlı örnek var (AddressConfirmExample)
registry.override(.addressConfirm) { MyAddressView() }

struct MyAddressView: View {
    @EnvironmentObject var coordinator: SDKFlowCoordinator
    @StateObject private var vm = SDKAddressConfirmViewModel()
    var body: some View {
        TextField("Adres", text: $vm.addressText)
        Button("Belge ekle") { vm.openScanner() }            // veya vm.openPDFPicker()
        Button("Gönder") { vm.submit() }                     // ✅ uploadAddressInfo[WithPdf]
            .disabled(!vm.canSubmit)
            .onAppear { vm.onCompleted = { coordinator.advanceToNextModule() } } // ✅
    }
}
```

## Notlar
- Adres en az 10 karakter olmalı (`isAddressValid`); aksi halde `canSubmit` false.
- Foto **ve** PDF aynı anda gerekmez; biri yeterli. PDF boyutu `maxPDFSizeMB`'ı aşmamalı.
- `registry.override(.addressConfirm)` örneği SampleApp `RootView.configureIfNeeded`'da mevcuttur.
</content>
