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

---

## Sesli Okuma (Read-Aloud)

Bu modül ekranı açıldığında yönergesi otomatik seslendirilebilir. Mod **modül bazında**
seçilir; tam ayrıntı: [ReadAloud](../ReadAloud.md).

- **Metin key'i:** `AddressConfirmTts`  ·  **Custom audio dosyası:** `AddressConfirmTts.<uzantı>`
  (uzantı serbest: `m4a`/`mp3`/`wav`/`caf`/`aac`/`aiff` otomatik denenir)
- **Native (Siri / sistem sesi):**
  ```swift
  SDKSpeechConfig.shared.setMode(.native, for: .addressConf)
  ```
- **Hazır klip (SDK içinde, yalnız Türkçe):** SDK bundle'ında `AddressConfirmTts_tr.mp3`
  gelir. Sesli okuma açıkken, host bu modüle açıkça mod atamadıkça: **dil TR ise hazır
  klip çalar**, diğer dillerde klip bulunmaz ve native okuma (aktif dilin
  `AddressConfirmTts` metni) devreye girer.
  Ekstra kod gerekmez; kapatmak/ezmek için modüle açıkça mod ata:
  ```swift
  SDKSpeechConfig.shared.setMode(.native, for: .addressConf)   // hazır klibi kullanma
  ```
- **Custom audio (kendi kaydın):** `AddressConfirmTts.<uzantı>` (tüm diller) veya
  `AddressConfirmTts_<dil>.<uzantı>` (örn. `AddressConfirmTts_tr.m4a`, yalnız o dilde)
  dosyasını bundle'a koy; `audioBundle`/`Bundle.main`'deki dosya SDK'nın hazır klibine
  göre öncelik kazanır:
  ```swift
  SDKSpeechConfig.shared.audioBundle = Bundle.main
  SDKSpeechConfig.shared.setMode(.customAudio, for: .addressConf)   // dosya yoksa native'e düşer
  ```
- **Kapalı:** `SDKSpeechConfig.shared.setMode(.off, for: .addressConf)`
- **Metni ez:** `SDKLocalization.shared.setOverride(key: .addressConfirmTts, language: .tr, value: "...")`

Seslendirme, ekran açılışında `SDKFlowHostView` tarafından otomatik yapılır — modül tarafında
ekstra kod gerekmez.

</content>
