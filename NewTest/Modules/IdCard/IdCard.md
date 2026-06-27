# IdCard — Kimlik (OCR)

Kimlik/pasaportun ön ve arka yüzünü kamerayla okur. OCR **cihaz üzerinde** çalışır
(`startFrontIdOcr` / `startBackIdOcr` / `startPassportMrzKey`), sonuç fotoğrafı **HTTP**
ile yüklenir (`uploadIdPhoto`). Karşılaştırma denemeleri tükenip atlamaya izin varsa
`onSkipRequested` tetiklenir.

| | |
|---|---|
| Backend key | `SdkModules.idCard` |
| Rota | `SDKModuleRoute.idCard` |
| Drop-in view | `SDKIdCardView` |
| ViewModel | `SDKIdCardViewModel` |
| Bağımlılık | on-device OCR + **HTTP** (`uploadIdPhoto`) |

---

## VM API — `SDKIdCardViewModel`

### Tip
```swift
public enum IdCardSide: String, Identifiable, Hashable { case front, back }
```

### State
| Üye | Tip | Erişim | Anlam |
|---|---|---|---|
| `frontPhoto` | `UIImage?` | r/w | Ön yüz görseli |
| `backPhoto` | `UIImage?` | r/w | Arka yüz görseli |
| `currentSide` | `IdCardSide` | salt-okunur | Şu an okunan yüz (`.front`/`.back`) |
| `resultText` | `String` | salt-okunur | Kullanıcıya gösterilen sonuç metni |
| `canContinue` | `Bool` | salt-okunur | Devam edilebilir mi |

### Hesaplanan
| Üye | Anlam |
|---|---|
| `allowedCardTypes: [CardType]` | İzinli kart tipleri (`manager.allowedCardType`) |
| `nfcRetryExceeded: Bool` | NFC karşılaştırma 2+ kez denendi mi |

### Girdi (metotlar)
| Metot | Etki |
|---|---|
| `selectCardType(_ type: CardType)` | Kart tipini seçer (`manager.selectedCardType`) |
| `scanFront(image: UIImage)` | Ön yüz OCR (`startFrontIdOcr`) → `uploadIdPhoto` |
| `scanBack(image: UIImage)` | Arka yüz OCR (`startBackIdOcr`) → `uploadIdPhoto`; bitince akış ilerler |
| `scanPassport(image:comingData:)` | Pasaport MRZ (`startPassportMrzKey`) |

### Çıktı (closure)
| Üye | Ne zaman |
|---|---|
| `onSkipRequested: (() -> Void)?` | Karşılaştırma tükenip skip izinliyse |

---

## Sinyal zinciri

```
selectCardType(_:)                       → manager.selectedCardType (on-device)
scanFront(image:)  → startFrontIdOcr (on-device OCR) → uploadIdPhoto [HTTP] → sendStep idFront=true [SOKET]
scanBack(image:)   → startBackIdOcr  (on-device OCR) → uploadIdPhoto [HTTP] → sendStep idBack=true [SOKET]
                   → (karşılaştırma tükendi & skip izinli) → onSkipRequested?()
host: tüm yüzler tamam → coordinator.advanceToNextModule()  [modulePresented]
```

---

## Drop-in kullanım

`SDKIdCardView` iki init sunar — biri kendi VM'ini kurar, biri dışarıdan enjeksiyon:

```swift
SDKIdCardView()                       // kendi VM'i
SDKIdCardView(viewModel: myIdCardVM)  // host VM enjeksiyonu
```

View, navigasyon çıktısını kendisi bağlar (VM coordinator'ı bilmez):
```swift
viewModel.onSkipRequested = { coordinator.skipCurrentModule() }
```

## Host VM (gözlem)

```swift
@MainActor
final class IdCardHostViewModel: HostModuleViewModel {
    let sdk = SDKIdCardViewModel()
    override init() {
        super.init()
        bridge(sdk)
        sdk.onSkipRequested = { [weak self] in self?.log("skip_requested") }
    }
    var currentSideText: String { sdk.currentSide == .front ? "ön" : "arka" }
    var canContinue: Bool { sdk.canContinue }
    func scanFront(_ image: UIImage) { log("scan_front"); sdk.scanFront(image: image) }
    func scanBack(_ image: UIImage)  { log("scan_back");  sdk.scanBack(image: image) }
}
```

## Custom tasarım — 3 ekstra ekran örneği (tanıtım → ön → arka → başarı)

Kullanıcının senaryosu: IdCard'ı kendi 4 ekranıyla sarmak. **Pasif** ekranlar (tanıtım,
başarı) soketle konuşmaz; **aktif** ekranlar SDK VM metodunu çağırır.

```swift
// Tanıtım ve başarı = custom (pasif), ön/arka = override (aktif)
registry.custom("idcard_intro")   { IdCardIntroView() }    // pasif
registry.custom("idcard_success") { IdCardSuccessView() }  // pasif
registry.override(.idCard)        { MyIdCardScanView() }   // aktif (SDK VM kullanır)

coordinator.insert(["idcard_intro"],   before: .idCard)
coordinator.insert(["idcard_success"], after:  .idCard)
```

| Ekran | Tür | VM çağrısı |
|---|---|---|
| Tanıtım | custom/pasif | — (yalnızca `coordinator.advanceExternal()`) |
| Ön yüz | override/aktif | `vm.scanFront(image:)` ✅ |
| Arka yüz | override/aktif | `vm.scanBack(image:)` ✅ |
| Başarı | custom/pasif | — sonra `coordinator.advanceToNextModule()` |

Aktif ekran iskeleti:
```swift
struct MyIdCardScanView: View {
    @EnvironmentObject var coordinator: SDKFlowCoordinator
    @StateObject private var vm = SDKIdCardViewModel()

    var body: some View {
        // ... kamera + vm.currentSide / vm.resultText / vm.canContinue okuyun ...
        // capture edilen görseli:
        // vm.currentSide == .front ? vm.scanFront(image:) : vm.scanBack(image:)
        Button("Devam") { coordinator.advanceToNextModule() }   // ✅ modulePresented
            .disabled(!vm.canContinue)
            .onAppear { vm.onSkipRequested = { coordinator.skipCurrentModule() } }
    }
}
```

> **Soket/WebRTC sorun olur mu?** Hayır. Soket + WebRTC `IdentifyManager.shared`'da yaşar,
> View yaşam döngüsünden izoledir. IdCard işi on-device OCR + HTTP'dir; araya pasif ekran
> eklemek hiçbir bağlantıyı koparmaz. Tek şart: tara/yükle SDK VM'inden geçsin (bypass yok).

## Notlar
- `scanPassport` yalnızca kart tipi `.passport` seçildiğinde gerekir; `comingData: FrontIdInfo` ön bilgileri taşır.
- OCR cihazda çalışır (`ocrManager.frontScanner`); ağ yalnızca `uploadIdPhoto` için kullanılır.
</content>
