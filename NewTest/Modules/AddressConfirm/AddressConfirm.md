# AddressConfirm — Adres Onayı

Kullanıcı ikamet adresini yazar ve kanıt olarak bir belge ekler — kamerayla çekilmiş bir
**fotoğraf** ya da bir **PDF** (ör. e-Devlet ikametgâh belgesi). "Gönder" ile adres + belge
tek istekte sunucuya yüklenir.

← [Modül İndeksi](../Modules.md) · [README](../../../README.md)

---

## Bir Bakışta

| | |
|---|---|
| Backend key | `SdkModules.addressConf` |
| Rota | `SDKModuleRoute.addressConfirm` |
| Drop-in view | `SDKAddressConfirmView` |
| ViewModel | `SDKAddressConfirmViewModel` |
| Dış dünya | **HTTP** (foto: `uploadAddressInfo` / PDF: `uploadAddressInfoWithPdf`) |
| Ses anahtarı | `AddressConfirmTts` |

## Kullanıcı Ne Yaşar?

1. Adresini metin alanına yazar (en az 10 karakter).
2. "Belge ekle" ile kaynağını seçer: kamerayla tara **veya** dosyalardan PDF seç.
3. Adres geçerli + belge ekli olunca "Gönder" aktifleşir; yükleme biter, akış ilerler.

---

## Hazır Ekranla Kullanım (Drop-in)

Hiçbir şey yazmayın; rota gelince `SDKAddressConfirmView` çizilir.

## Kendi Tasarımınızla (Override)

Sample App'te bu modülün canlı bir override örneği zaten vardır
(`AddressConfirmExample`, kayıt yeri: `RootView.configureIfNeeded`):

```swift
registry.override(.addressConfirm) { MyAddressView() }

struct MyAddressView: View {
    @EnvironmentObject var coordinator: SDKFlowCoordinator
    @StateObject private var vm = SDKAddressConfirmViewModel()

    var body: some View {
        VStack {
            TextField("Adres", text: $vm.addressText)
            Button("Belgeyi tara") { vm.openScanner() }
            Button("PDF seç") { vm.openPDFPicker() }
            Button("Gönder") { vm.submit() }        // ✅ uploadAddressInfo[WithPdf]
                .disabled(!vm.canSubmit)
        }
        .onAppear { vm.onCompleted = { coordinator.advanceToNextModule() } }  // ✅
    }
}
```

---

## ViewModel Referansı — `SDKAddressConfirmViewModel`

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

### Metotlar
| Metot | Etki |
|---|---|
| `openScanner()` | Belge tarayıcısını açar |
| `openPDFPicker()` | PDF seçiciyi açar |
| `photoSelected(_ image: UIImage)` | Seçilen fotoğrafı set eder |
| `pdfSelectedFromURL(_ url: URL)` | URL'den PDF yükler |
| `pdfSelected(_ data: Data, preview: UIImage?)` | PDF verisini set eder |
| `submit()` | Adres + belgeyi yükler → `onCompleted` |

### Closure'lar
| Üye | Ne zaman |
|---|---|
| `onCompleted: (() -> Void)?` | Yükleme başarılı |

## Sinyal Zinciri — Perde Arkası

```
photoSelected / pdfSelected...  → docPhoto / pdfData (UI durumu)
submit()
   ├─ PDF var  → manager.uploadAddressInfoWithPdf [HTTP]
   └─ foto var → manager.uploadAddressInfo        [HTTP]
                                   → onCompleted?()
host: → coordinator.advanceToNextModule() [modulePresented]
```

## Host VM ile Gözlem (Composition)

```swift
@MainActor
final class AddressHostViewModel: HostModuleViewModel {
    let sdk = SDKAddressConfirmViewModel()
    override init() {
        super.init(); bridge(sdk)
        sdk.onCompleted = { [weak self] in self?.log("address_done") }
    }
    var canSubmit: Bool { sdk.canSubmit }
    func submit() { sdk.submit() }
}
```

---

## Sesli Okuma (Read-Aloud)

Ekran açıldığında yönerge otomatik seslendirilebilir (`SDKFlowHostView` yapar, kod gerekmez).

Bu modülün bir ayrıcalığı vardır: SDK bundle'ında **hazır Türkçe klip** gelir
(`AddressConfirmTts_tr.mp3`). Sesli okuma açıkken ve bu modüle açıkça mod atamadıysanız:
dil TR ise hazır klip çalar; diğer dillerde native okuma devreye girer.

```swift
// Hazır klibi kullanma, native oku:
SDKSpeechConfig.shared.setMode(.native, for: .addressConf)

// Kendi kaydınız — tüm diller için AddressConfirmTts.m4a
// veya dil bazlı AddressConfirmTts_tr.m4a (host dosyası SDK klibini ezer):
SDKSpeechConfig.shared.audioBundle = Bundle.main
SDKSpeechConfig.shared.setMode(.customAudio, for: .addressConf)   // dosya yoksa native'e düşer

// Kapalı:
SDKSpeechConfig.shared.setMode(.off, for: .addressConf)
```

Metni ezmek: `SDKLocalization.shared.setOverride(key: .addressConfirmTts, language: .tr, value: "...")`
· Tüm ayrıntı: [ReadAloud](../ReadAloud.md)

## Sık Sorulanlar & Dikkat Edilecekler

- **Foto mu PDF mi?** Biri yeterli — ikisi aynı anda gerekmez.
- **"Gönder" pasif:** Adres 10 karakterin altındaysa `isAddressValid` `false` kalır.
- **PDF sınırı:** `maxPDFSizeMB` sunucudan gelir; seçimden önce kullanıcıya gösterin.
- **Fotoğraf kalitesi:** SDK, adres belgesini okunaklı kalacak sıkıştırma ayarlarıyla yükler
  (2.5.4'te iyileştirildi) — ekstra sıkıştırma yapmayın.
- **Belge tarayıcısı:** `openScanner()` ile açılan kamera, SDK'nın gerçek zamanlı tarama
  motorunu (`.generic` profil — otomatik kırpma + perspektif düzeltme) kullanır —
  [IdentityScanner rehberi](../../../docs/guides/identity-scanner.md).
