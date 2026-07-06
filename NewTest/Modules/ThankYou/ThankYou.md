# ThankYou — Sonuç Ekranı

Akışın son durağı. Kullanıcıya KYC sürecinin sonucunu gösterir: başarıyla tamamlandı,
reddedildi ya da cevapsız çağrı. **Tamamen pasiftir** — hiçbir soket/HTTP çağrısı yapmaz;
bu yüzden en güvenle özelleştirilebilen ekrandır.

← [Modül İndeksi](../Modules.md) · [README](../../../README.md)

---

## Bir Bakışta

| | |
|---|---|
| Backend key | `SdkModules.thankU` |
| Rota | `SDKModuleRoute.thankYou(ThankYouStatus?)` |
| Drop-in view | `SDKThankYouView` |
| ViewModel | `SDKThankYouViewModel` |
| Dış dünya | — (pasif terminal; soket/HTTP yok) |
| Ses anahtarı | `ThankYouTts` |

## İki Biçimde Gelir

- **Statüsüz** — `SDKThankYouView()`: `manager.kycIsCompleted`'a göre genel başarı/başarısızlık.
- **Statülü** — `SDKThankYouView(status:)`: görüşme sonucu (pozitif/negatif/cevapsız).
  CallScreen, sonucu `coordinator.pendingThankYouStatus`'a yazar; statü rotaya gömülür.

```swift
public enum ThankYouStatus: Hashable {
    case completed        // genel başarı
    // ... görüşme sonuç varyantları (pozitif / negatif / missed) ...
}
```

---

## Kullanım

```swift
// Drop-in (statüsüz)
SDKThankYouView()

// Drop-in (statülü)
SDKThankYouView(status: .completed)

// Görüşme akışından doğrudan geçiş
coordinator.pushThankYouDirectly(status: .completed)
```

`SDKFlowHostView` rotayı statüye göre çizer:

```swift
case .thankYou(let status):
    if let status { SDKThankYouView(status: status) }
    else          { SDKThankYouView() }
```

## Kendi Tasarımınızla (Override)

```swift
registry.override(.thankYou(.completed)) {
    MyThankYouView(status: .completed)
}
```

> **Dikkat:** `.thankYou(_)` rotası **associated value** taşır — override belirli bir statü
> için kaydedilir. Tüm statüleri tek tasarımla karşılamak istiyorsanız her olası statü için
> ayrı `registry.override` kaydı ekleyin (ya da drop-in kullanıp
> [tema](../../../docs/guides/theming.md) ile `thankYouSuccess`/`thankYouFail`
> illüstrasyonlarını değiştirin).

---

## ViewModel Referansı — `SDKThankYouViewModel`

### Init
```swift
public init(status: ThankYouStatus = .completed)
```

### State (`@Published`, salt-okunur)
| Üye | Tip | Anlam |
|---|---|---|
| `status` | `ThankYouStatus` | Gösterilen sonuç |
| `isSelfieIdentification` | `Bool` | Selfie-only kimlik akışı mıydı |
| `kycCompleted` | `Bool` | KYC tamamlandı mı |

Bu VM'in **girdi metodu veya çıktı closure'u yoktur** — terminal ekrandır. Modül sırası
tükendiğinde SDK bağlantıyı kendisi kapatır (`disconnect()`); ekrandan sonra
`advanceToNextModule` yoktur.

---

## Sesli Okuma (Read-Aloud)

Ekran açıldığında sonuç mesajı otomatik seslendirilebilir (`SDKFlowHostView` yapar).

```swift
SDKSpeechConfig.shared.setMode(.native, for: .thankU)         // Siri/sistem sesi
// veya kendi kaydınız: bundle'a ThankYouTts.m4a koyun →
SDKSpeechConfig.shared.audioBundle = Bundle.main
SDKSpeechConfig.shared.setMode(.customAudio, for: .thankU)    // dosya yoksa native'e düşer
```

Metni ezmek: `SDKLocalization.shared.setOverride(key: .thankYouTts, language: .tr, value: "...")`
· Tüm ayrıntı: [ReadAloud](../ReadAloud.md)

## Sık Sorulanlar & Dikkat Edilecekler

- **Bu ekran gösterilmesin istiyorum:** `setupSDK(showThankYouPage: false)` — akış sonunda
  kontrol size döner; kendi kapanış deneyiminizi kurarsınız.
- **Özelleştirmesi risksiz mi?** Evet — pasif olduğundan yerine/arasına ne koyarsanız koyun
  akış bozulmaz.
- **Kapanış kim yapar?** KYC sonrası `disconnect`/`closeSDK` SDK tarafında, ekrandan
  bağımsız yönetilir.
