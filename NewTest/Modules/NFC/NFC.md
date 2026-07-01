# NFC — Kimlik/Pasaport çip okuma

ICAO çipini (BAC/PACE → Secure Messaging) okur. MRZ anahtarı (seri no + doğum tarihi +
geçerlilik tarihi) ile `startNFC` başlatılır; başarıda `onCompleted`. Karşılaştırma
denemeleri tükenip atlamaya izin varsa `onSkipRequested`.

| | |
|---|---|
| Backend key | `SdkModules.nfc` |
| Rota | `SDKModuleRoute.nfc` |
| Drop-in view | `SDKNfcView` |
| ViewModel | `SDKNfcViewModel` |
| Bağımlılık | CoreNFC (on-device çip) + **HTTP** (sonuç) |

> `Info.plist` → `NFCReaderUsageDescription` ve `*.entitlements` →
> `com.apple.developer.nfc.readersession.formats` zorunludur.

---

## VM API — `SDKNfcViewModel`

### State
| Üye | Tip | Erişim | Anlam |
|---|---|---|---|
| `serialNo` | `String` | r/w | Belge seri no (MRZ) |
| `birthDate` | `String` | r/w | Doğum tarihi (MRZ) |
| `validDate` | `String` | r/w | Geçerlilik tarihi (MRZ) |
| `nfcStatus` | `String` | salt-okunur | Okuma durumu metni |
| `nfcCompleted` | `Bool` | salt-okunur | Okuma tamamlandı mı |
| `showEditScreen` | `Bool` | r/w | Manuel MRZ düzenleme ekranı |
| `canContinue` | `Bool` | salt-okunur | Devam edilebilir mi |

### Girdi (metotlar)
| Metot | Etki |
|---|---|
| `startNFC()` | MRZ anahtarıyla çip okumayı başlatır (`manager.startNFC`) |
| `saveManualDates()` | Manuel girilen MRZ alanlarını kaydeder |

### Çıktı (closure)
| Üye | Ne zaman |
|---|---|
| `onCompleted: (() -> Void)?` | Okuma başarılı |
| `onSkipRequested: (() -> Void)?` | Karşılaştırma tükenip skip izinliyse |

MRZ alanları VM açılışında otomatik dolar: `manager.mrzDocNo`, `manager.mrzBirthDay`,
`manager.mrzValidDate` (önceki OCR adımından gelir). `manager.useKpsData` aktifse KPS
verisi kullanılır.

---

## Sinyal zinciri

```
(VM init) ← manager.mrzDocNo / mrzBirthDay / mrzValidDate (önceki OCR'dan)
startNFC()  → manager.startNFC (CoreNFC çip okuma) → nfcMsgHandler (durum) → onCompleted?()
            → (nfcComparisonCount tükendi & skip izinli) → onSkipRequested?()
host: → coordinator.advanceToNextModule() [modulePresented]
```

---

## Drop-in / Host VM / Custom

```swift
// Drop-in
case .nfc: SDKNfcView()

// Host VM
final class NfcHostViewModel: HostModuleViewModel {
    let sdk = SDKNfcViewModel()
    override init() {
        super.init(); bridge(sdk)
        sdk.onCompleted     = { [weak self] in self?.log("nfc_done") }
        sdk.onSkipRequested = { [weak self] in self?.log("nfc_skip") }
    }
    var status: String { sdk.nfcStatus }
    func start() { log("nfc_start"); sdk.startNFC() }
}

// Custom (override)
registry.override(.nfc) { MyNfcView() }

struct MyNfcView: View {
    @EnvironmentObject var coordinator: SDKFlowCoordinator
    @StateObject private var vm = SDKNfcViewModel()
    var body: some View {
        VStack {
            Text(vm.nfcStatus)
            Button("Çipi Oku") { vm.startNFC() }           // ✅ manager.startNFC
            Button("Devam") { coordinator.advanceToNextModule() } // ✅
                .disabled(!vm.canContinue)
        }
        .onAppear {
            vm.onCompleted     = { coordinator.advanceToNextModule() }
            vm.onSkipRequested = { coordinator.skipCurrentModule() }
        }
    }
}
```

## Notlar
- NFC okuma sistem NFC sheet'ini açar; simülatörde çalışmaz, gerçek cihaz gerekir.
- MRZ alanları yanlışsa `showEditScreen = true` + `saveManualDates()` ile düzeltilebilir.
- `onSkipRequested`, NFC çoklu denemede başarısız olursa akışı kilitlememek içindir.

---

## Sesli Okuma (Read-Aloud)

Bu modül ekranı açıldığında yönergesi otomatik seslendirilebilir. Mod **modül bazında**
seçilir; tam ayrıntı: [ReadAloud](../ReadAloud.md).

- **Metin key'i:** `NfcTts`  ·  **Custom audio dosyası:** `NfcTts.<uzantı>`
  (uzantı serbest: `m4a`/`mp3`/`wav`/`caf`/`aac`/`aiff` otomatik denenir)
- **Native (Siri / sistem sesi):**
  ```swift
  SDKSpeechConfig.shared.setMode(.native, for: .nfc)
  ```
- **Custom audio (kendi kaydın):** bundle'a `NfcTts.<uzantı>` koy (örn. `NfcTts.m4a` veya `NfcTts.mp3`) →
  ```swift
  SDKSpeechConfig.shared.audioBundle = Bundle.main
  SDKSpeechConfig.shared.setMode(.customAudio, for: .nfc)   // dosya yoksa native'e düşer
  ```
- **Kapalı:** `SDKSpeechConfig.shared.setMode(.off, for: .nfc)`
- **Metni ez:** `SDKLocalization.shared.setOverride(key: .nfcTts, language: .tr, value: "...")`

Seslendirme, ekran açılışında `SDKFlowHostView` tarafından otomatik yapılır — modül tarafında
ekstra kod gerekmez.

</content>
