# Selfie — Yüz Fotoğrafı

Kullanıcı ön kamerayla bir selfie çeker; SDK **cihaz üzerinde** yüz olup olmadığını doğrular
(`detectHumanFace`) ve görseli sunucuya yükler. Sunucu tarafında bu selfie, kimlik
fotoğrafı ve NFC çip fotoğrafıyla karşılaştırılır — "belgedeki kişi gerçekten bu kişi mi?"
sorusunun cevabı burada başlar.

Bu modül aynı zamanda Default UI geçişinin pilotuydu; **composition deseninin referans
örneğidir** — diğer modüllere bakmadan önce bunu okumak iyi bir başlangıçtır.

← [Modül İndeksi](../Modules.md) · [README](../../../README.md)

---

## Bir Bakışta

| | |
|---|---|
| Backend key | `SdkModules.selfie` |
| Rota | `SDKModuleRoute.selfie` |
| Drop-in view | `SDKSelfieView` |
| ViewModel | `SDKSelfieViewModel` |
| Dış dünya | Yüz tespiti (cihazda) + **HTTP** (`uploadIdPhoto`) |
| Ses anahtarı | `SelfieTts` |

## Kullanıcı Ne Yaşar?

1. Ön kamera açılır; kullanıcı yüzünü çerçeveye alır ve fotoğrafı çeker.
2. SDK cihazda yüz arar — yüz yoksa (ya da birden fazla yüz varsa) uyarı çıkar, yeniden çekilir.
3. Yüz doğrulanınca görsel yüklenir; "Devam" aktifleşir.
4. Sunucudaki karşılaştırma hakkı tükenir ve atlamaya izin varsa adım atlanabilir.

---

## Hazır Ekranla Kullanım (Drop-in)

Hiçbir şey yazmayın; rota gelince `SDKSelfieView` çizilir.

## Kendi Tasarımınızla (Override)

Kamera ve tüm UI sizin; yüz tespiti + yükleme SDK VM'inde kalır:

```swift
registry.override(.selfie) { MySelfieView() }

struct MySelfieView: View {
    @EnvironmentObject var coordinator: SDKFlowCoordinator
    @StateObject private var vm = SDKSelfieViewModel()

    var body: some View {
        VStack {
            MyFrontCameraView { captured in
                vm.processSelfie(image: captured)    // ✅ yüz tespiti + upload
            }
            Text(vm.resultText)
            Button("Yeniden Çek") { vm.reset() }
            Button("Devam") { coordinator.advanceToNextModule() }   // ✅ modulePresented
                .disabled(!vm.canContinue)
        }
        .onAppear { vm.onSkipRequested = { coordinator.skipCurrentModule() } }
    }
}
```

---

## ViewModel Referansı — `SDKSelfieViewModel`

### State
| Üye | Tip | Erişim | Anlam |
|---|---|---|---|
| `selfieImage` | `UIImage?` | r/w | Çekilen selfie |
| `faceDetected` | `Bool` | salt-okunur | Yüz tespit edildi mi |
| `canContinue` | `Bool` | salt-okunur | Devam edilebilir mi |
| `resultText` | `String` | salt-okunur | Sonuç metni |

### Metotlar
| Metot | Etki |
|---|---|
| `processSelfie(image: UIImage)` | Yüz tespiti (`detectHumanFace`) → `uploadIdPhoto` |
| `reset()` | Durumu sıfırlar (yeniden çekim) |

### Closure'lar
| Üye | Ne zaman |
|---|---|
| `onSkipRequested: (() -> Void)?` | Karşılaştırma hakkı tükenip atlamaya izin varsa |

## Sinyal Zinciri — Perde Arkası

```
processSelfie(image:)  → manager.detectHumanFace (cihazda) → uploadIdPhoto [HTTP]
                       → (selfieComparisonCount tükendi & skip izinli) → onSkipRequested?()
host: canContinue → coordinator.advanceToNextModule() [modulePresented]
```

## Host VM ile Gözlem (Composition) — Referans Desen

```swift
@MainActor
final class SelfieHostViewModel: HostModuleViewModel {
    let sdk = SDKSelfieViewModel()
    override init() {
        super.init(); bridge(sdk)                     // child objectWillChange'i yukarı ilet
        sdk.onSkipRequested = { [weak self] in self?.log("selfie_skip") }
    }
    var canContinue: Bool { sdk.canContinue }
    func process(_ img: UIImage) { log("selfie_scan"); sdk.processSelfie(image: img) }
}
```

---

## Sesli Okuma (Read-Aloud)

Ekran açıldığında yönerge otomatik seslendirilebilir (`SDKFlowHostView` yapar, kod gerekmez).

```swift
SDKSpeechConfig.shared.setMode(.native, for: .selfie)         // Siri/sistem sesi
// veya kendi kaydınız: bundle'a SelfieTts.m4a koyun →
SDKSpeechConfig.shared.audioBundle = Bundle.main
SDKSpeechConfig.shared.setMode(.customAudio, for: .selfie)    // dosya yoksa native'e düşer
```

Metni ezmek: `SDKLocalization.shared.setOverride(key: .selfieTts, language: .tr, value: "...")`
· Tüm ayrıntı: [ReadAloud](../ReadAloud.md)

## Sık Sorulanlar & Dikkat Edilecekler

- **Yüz bulunamadı:** `faceDetected` `false` kalır, `canContinue` açılmaz — kullanıcıyı
  `reset()` ile yeniden çekime yönlendirin (ışık ve tek-yüz koşulunu hatırlatın).
- **Birden fazla yüz:** SDK yalnızca **tek yüz** algılandığında ilerletir (2.3.15+).
- **Deneme hakkı:** `selfie_comparison_count` sunucudan gelir; custom ekranınızda
  `onSkipRequested`'ı bağlamayı unutmayın — yoksa hak tükenince kullanıcı sıkışır.
