# SelfieWithLiveness — Selfie + canlılık (birleşik)

Selfie ile liveness adımlarını tek ekranda birleştiren varyant. Diğer modüllerden farkı:
bu modül **UIKit controller** tabanlıdır (`SDKSelfieWithLivenessController`) ve henüz
ayrı bir `SDKBaseModuleViewModel` VM'i yoktur.

| | |
|---|---|
| Backend key | `SdkModules.selfieWithLiveness` |
| Rota | `SDKModuleRoute.selfieWithLiveness` |
| Drop-in view | `SDKSelfieWithLivenessView` (controller'ı saran SwiftUI) |
| Controller | `SDKSelfieWithLivenessController` (UIKit) |
| Bağımlılık | yüz/canlılık (on-device) + **HTTP** |

---

## Mevcut durum

- Ekran `SDKSelfieWithLivenessView` ile drop-in çalışır:
  ```swift
  case .selfieWithLiveness: SDKSelfieWithLivenessView()
  ```
- İç mantık `SDKSelfieWithLivenessController` (UIKit) içindedir; SwiftUI sarmalı bunu
  `UIViewControllerRepresentable` benzeri bir köprüyle sunar.
- **Composition deseni henüz uygulanmadı.** Diğer modüllerdeki gibi `let sdk = SDKXxxVM()`
  sarma yapısı bu modülde yok.

## Özelleştirme

- **Tam override** mümkün: `registry.override(.selfieWithLiveness) { MyView() }`. Ancak
  kendi ekranınızı yazarsanız selfie+liveness iş mantığını (yakalama, yüz/canlılık
  doğrulama, yükleme) controller üzerinden tetiklemeniz gerekir — bu modülde henüz temiz
  bir public VM yüzeyi olmadığından, **özel tasarım yerine drop-in kullanımı önerilir.**
- Selfie ve Liveness'ı ayrı ayrı özelleştirmek istiyorsanız, backend'de `.selfie` +
  `.livenessDetection` modüllerini ayrı kullanın ([Selfie](../Selfie/Selfie.md),
  [Liveness](../Liveness/Liveness.md)); her ikisinin de tam VM API'si vardır.

## Notlar / TODO
- Diğer modüllerle tutarlılık için ileride `SDKSelfieWithLivenessViewModel`
  (`: SDKBaseModuleViewModel`) çıkarılması planlanabilir; o zaman bu doküman
  Selfie/Liveness ile aynı VM-tablosu formatına geçer.
- O güne kadar: gerçek host-tarafı özelleştirme gerekiyorsa ayrık `.selfie` + `.liveness`
  kullanın.
</content>
