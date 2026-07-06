# NFC — Kimlik/Pasaport Çip Okuma

Kimlik doğrulamanın en güçlü kanıtı: belgedeki **çipin** okunması. SDK, tam bir ICAO
yığını taşır (BAC/PACE ile anahtar anlaşması → Secure Messaging → veri grupları) ve çipteki
fotoğraf/kimlik verisini güvenle çıkarır. Çipe erişimin anahtarı, bir önceki OCR adımında
okunan üç MRZ alanıdır: **seri no + doğum tarihi + son geçerlilik tarihi**.

← [Modül İndeksi](../Modules.md) · [README](../../../README.md)

---

## Bir Bakışta

| | |
|---|---|
| Backend key | `SdkModules.nfc` |
| Rota | `SDKModuleRoute.nfc` |
| Drop-in view | `SDKNfcView` |
| ViewModel | `SDKNfcViewModel` |
| Dış dünya | CoreNFC (cihazda çip) + **HTTP** (sonuç yükleme) |
| Ses anahtarı | `NfcTts` |

**Kurulum gereksinimi:** entitlement dosyasına
`com.apple.developer.nfc.readersession.formats` → `TAG`, Info.plist'e
`NFCReaderUsageDescription` ve
`com.apple.developer.nfc.readersession.iso7816.select-identifiers` → `A0000002471001`.

## Kullanıcı Ne Yaşar?

1. "Kimliğinizi telefonun arkasına yaslayın" yönergesini görür.
2. "Çipi Oku"ya dokununca sistemin NFC sayfası açılır; belgeyi telefonun üst-arka kısmına tutar.
3. Okuma sırasında durum metni akar (`nfcStatus`); başarıda otomatik ilerlenir.
4. MRZ alanları yanlışsa manuel düzeltme ekranı açılabilir; deneme hakkı tükenirse adım atlanabilir.

---

## Hazır Ekranla Kullanım (Drop-in)

Hiçbir şey yazmayın; rota gelince `SDKNfcView` çizilir. NFC illüstrasyonlarını
değiştirmek için tema anahtarları: `nfcFront`, `nfcBack` ([Tema](../../../docs/guides/theming.md)).

## Kendi Tasarımınızla (Override)

```swift
registry.override(.nfc) { MyNfcView() }

struct MyNfcView: View {
    @EnvironmentObject var coordinator: SDKFlowCoordinator
    @StateObject private var vm = SDKNfcViewModel()

    var body: some View {
        VStack {
            Text(vm.nfcStatus)                                      // canlı durum
            Button("Çipi Oku") { vm.startNFC() }                    // ✅ manager.startNFC
            Button("Devam") { coordinator.advanceToNextModule() }   // ✅
                .disabled(!vm.canContinue)
        }
        .onAppear {
            vm.onCompleted     = { coordinator.advanceToNextModule() }
            vm.onSkipRequested = { coordinator.skipCurrentModule() }
        }
    }
}
```

---

## ViewModel Referansı — `SDKNfcViewModel`

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

### Metotlar
| Metot | Etki |
|---|---|
| `startNFC()` | MRZ anahtarıyla çip okumayı başlatır (`manager.startNFC`) |
| `saveManualDates()` | Manuel girilen MRZ alanlarını kaydeder |

### Closure'lar
| Üye | Ne zaman |
|---|---|
| `onCompleted: (() -> Void)?` | Okuma başarılı |
| `onSkipRequested: (() -> Void)?` | Deneme hakkı tükenip atlamaya izin varsa |

MRZ alanları VM açılışında otomatik dolar: `manager.mrzDocNo`, `manager.mrzBirthDay`,
`manager.mrzValidDate` (önceki OCR adımından). `manager.useKpsData` aktifse KPS verisi
kullanılır — sunucudan şifreli MRZ da gelebilir
([Sunucu & API → şifreli MRZ](../../../docs/guides/server-api.md#şifreli-mrz-verisi-kpsdata-yerine)).

## Sinyal Zinciri — Perde Arkası

```
(VM init) ← manager.mrzDocNo / mrzBirthDay / mrzValidDate (önceki OCR'dan)
startNFC()  → manager.startNFC (CoreNFC çip okuma) → nfcMsgHandler (durum) → onCompleted?()
            → (nfcComparisonCount tükendi & skip izinli) → onSkipRequested?()
host: → coordinator.advanceToNextModule() [modulePresented]
```

## Host VM ile Gözlem (Composition)

```swift
@MainActor
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
```

---

## Sesli Okuma (Read-Aloud)

Ekran açıldığında yönerge otomatik seslendirilebilir (`SDKFlowHostView` yapar, kod gerekmez).

```swift
SDKSpeechConfig.shared.setMode(.native, for: .nfc)          // Siri/sistem sesi
// veya kendi kaydınız: bundle'a NfcTts.m4a koyun →
SDKSpeechConfig.shared.audioBundle = Bundle.main
SDKSpeechConfig.shared.setMode(.customAudio, for: .nfc)     // dosya yoksa native'e düşer
```

Metni ezmek: `SDKLocalization.shared.setOverride(key: .nfcTts, language: .tr, value: "...")`
· Tüm ayrıntı: [ReadAloud](../ReadAloud.md)

## Sık Sorulanlar & Dikkat Edilecekler

- **Simülatörde çalışmaz** — CoreNFC gerçek cihaz ister; NFC'yi test etmeden yayına çıkmayın.
- **Okuma başarısız oluyor:** Kılıfı çıkartın, belgeyi telefonun **üst-arka** kısmına tutun,
  okuma bitene kadar oynatmayın. Hata sayısı `setupSDK(nfcMaxErrorCount:)` ile sınırlanır.
- **MRZ yanlış okunmuşsa:** `showEditScreen = true` + `saveManualDates()` ile kullanıcı
  düzeltebilir; agent uzaktan da NFC düzeltme başlatabilir (`editNfcProcess` soket aksiyonu).
- **Çipsiz belge:** `setupSDK(showNFCNotFoundPage: true)` ile "NFC bulunamadı" ekranı
  gösterilebilir; event akışında `notFound` durumu görülür ([Event Sistemi](../../../docs/guides/events.md)).
- **Sertifika doğrulama:** `needCertForNfc: true` ile çip sertifika zinciri, gömülü CSCA
  listesine karşı doğrulanır.
