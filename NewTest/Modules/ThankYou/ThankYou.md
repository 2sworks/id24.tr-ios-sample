# ThankYou — Teşekkür / sonuç ekranı

Akışın terminal ekranı. KYC sonucunu gösterir. İki biçimde gelir:
- **Statüsüz** (`SDKThankYouView()`): `manager.kycIsCompleted`'a göre genel başarı.
- **Statülü** (`SDKThankYouView(status:)`): görüşme sonucu (pozitif/negatif/missed) —
  CallScreen tarafından `coordinator.pendingThankYouStatus`'a yazılıp rotaya gömülür.

| | |
|---|---|
| Backend key | `SdkModules.thankU` |
| Rota | `SDKModuleRoute.thankYou(ThankYouStatus?)` |
| Drop-in view | `SDKThankYouView` |
| ViewModel | `SDKThankYouViewModel` |
| Bağımlılık | — (pasif terminal; soket/HTTP yok) |

---

## Tip — `ThankYouStatus`

```swift
public enum ThankYouStatus: Hashable {
    case completed        // genel başarı
    // ... görüşme sonuç varyantları (pozitif / negatif / missed) ...
}
```

## VM API — `SDKThankYouViewModel`

### Init
```swift
public init(status: ThankYouStatus = .completed)
```

### State (`@Published`, salt-okunur)
| Üye | Tip | Anlam |
|---|---|---|
| `status` | `ThankYouStatus` | Gösterilen sonuç |
| `isSelfieIdentification` | `Bool` | Selfie-only kimlik akışı mıydı (`manager.isSelfieIdent`) |
| `kycCompleted` | `Bool` | KYC tamamlandı mı (`manager.kycIsCompleted`) |

Bu modülün **girdi metodu veya çıktı closure'u yoktur** — pasiftir. Terminal olduğundan
ekrandan sonra `advanceToNextModule` yoktur; akış burada biter (`getNextModule` modül
sırası tükendiğinde SDK `disconnect()` çağırır).

---

## Rota çizimi

`SDKFlowHostView` statüye göre ayrım yapar:

```swift
case .thankYou(let status):
    if let status { SDKThankYouView(status: status) }
    else          { SDKThankYouView() }
```

Görüşme akışında doğrudan geçiş:
```swift
coordinator.pushThankYouDirectly(status: .completed)
// veya CallScreen: coordinator.pendingThankYouStatus = status; coordinator.advanceToNextModule()
```

---

## Drop-in / Custom

```swift
// Drop-in (statüsüz)
SDKThankYouView()

// Drop-in (statülü)
SDKThankYouView(status: .completed)

// Custom (override) — statüyü rotadan alın
registry.override(.thankYou(.completed)) {
    MyThankYouView(status: .completed)
}
```

> **Not:** `.thankYou(_)` rotası **associated value** taşır; override'ı belirli bir statü
> için kaydedersiniz. Tüm statüleri tek tasarımla karşılamak istiyorsanız, host view'ınız
> kendi içinde statü ayrımını yapsın ve her olası statü için `registry.override` kaydı
> ekleyin (ya da basitçe drop-in'i kullanın).

## Notlar
- Bu ekran pasiftir: hiçbir VM metodu soket/HTTP tetiklemez. Araya/yerine custom koymak akışı bozmaz.
- `showThankYouPage: true` setupSDK parametresi bu ekranın gösterilip gösterilmeyeceğini belirler.
- KYC sonrası kapanış (`disconnect`/`closeSDK`) SDK tarafında, ekrandan bağımsız yönetilir.

---

## Sesli Okuma (Read-Aloud)

Bu modül ekranı açıldığında yönergesi otomatik seslendirilebilir. Mod **modül bazında**
seçilir; tam ayrıntı: [ReadAloud](../ReadAloud.md).

- **Metin key'i:** `ThankYouTts`  ·  **Custom audio dosyası:** `ThankYouTts.<uzantı>`
  (uzantı serbest: `m4a`/`mp3`/`wav`/`caf`/`aac`/`aiff` otomatik denenir)
- **Native (Siri / sistem sesi):**
  ```swift
  SDKSpeechConfig.shared.setMode(.native, for: .thankU)
  ```
- **Custom audio (kendi kaydın):** bundle'a `ThankYouTts.<uzantı>` koy (örn. `ThankYouTts.m4a` veya `ThankYouTts.mp3`) →
  ```swift
  SDKSpeechConfig.shared.audioBundle = Bundle.main
  SDKSpeechConfig.shared.setMode(.customAudio, for: .thankU)   // dosya yoksa native'e düşer
  ```
- **Kapalı:** `SDKSpeechConfig.shared.setMode(.off, for: .thankU)`
- **Metni ez:** `SDKLocalization.shared.setOverride(key: .thankYouTts, language: .tr, value: "...")`

Seslendirme, ekran açılışında `SDKFlowHostView` tarafından otomatik yapılır — modül tarafında
ekstra kod gerekmez.

</content>
