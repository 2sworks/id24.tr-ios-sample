# IdCardOVD — Kimlik Tarama + Hologram Doğrulama

IdCard'ın güvenlik seviyesi yükseltilmiş hali. Fotoğraf çekmekle kalmaz: kamera akışını
canlı analiz ederek belgenin **optik değişken öğelerini (OVD — hologram)** doğrular.
Parlama (glare), doku (texture) ve gökkuşağı (rainbow) skorları **cihaz üzerinde** hesaplanır;
fotokopi ya da ekran görüntüsüyle yapılan sahtecilik denemeleri bu adımda elenir.

← [Modül İndeksi](../Modules.md) · [README](../../../README.md)

---

## Bir Bakışta

| | |
|---|---|
| Backend key | `SdkModules.idcard_w_ovd` |
| Rota | `SDKModuleRoute.idCardOVD` |
| Drop-in view | `SDKIdCardOVDView` |
| ViewModel | `SDKIdCardOVDViewModel` |
| Dış dünya | Cihazda skor analizi + **HTTP** (`uploadIdPhoto`) |
| Ses anahtarı | `IdCardOVDTts` |

## Kullanıcı Ne Yaşar?

1. Kimliğini çerçeveye hizalar; SDK kareleri canlı değerlendirir.
2. Hologram adımında kimliği hafifçe oynatması istenir — gökkuşağı efekti ölçülür
   (`rainbowProgress` doluyor).
3. Adımlar (`OVDStep`) sırayla tamamlanır; her yakalama sunucuya yüklenir.
4. Son adım bitince akış otomatik ilerler.

---

## Hazır Ekranla Kullanım (Drop-in)

Hiçbir şey yazmayın; rota gelince `SDKIdCardOVDView` çizilir.

## Kendi Tasarımınızla (Override)

Kamera akışını siz çizersiniz; **her kareyi analiz için VM'e verirsiniz**:

```swift
registry.override(.idCardOVD) { MyOVDView() }

struct MyOVDView: View {
    @EnvironmentObject var coordinator: SDKFlowCoordinator
    @StateObject private var vm = SDKIdCardOVDViewModel()

    var body: some View {
        VStack {
            Text(vm.instruction)                       // adım talimatı
            ProgressView(value: vm.progress)           // genel ilerleme
            MyCameraFeed { ciImage, roi in
                vm.ingest(ciImage: ciImage, roi: roi)  // ✅ her kare: cihazda skor
            }
            // yakalama: vm.capture(image: img)        // ✅ işle + upload
            // adım geçişi: vm.advance()
        }
        .onAppear { vm.onCompleted = { coordinator.advanceToNextModule() } }  // ✅
    }
}
```

> ❌ **Bypass yapmayın:** Skorları kendiniz hesaplayıp upload'u atlamayın —
> `ingest` → `capture` → `advance` zincirini kullanın, aksi halde OVD doğrulaması
> backend'e hiç ulaşmaz. Kural: [bypass yok](../../../docs/guides/customization.md#bypass-yok-kuralı).

---

## ViewModel Referansı — `SDKIdCardOVDViewModel`

### Tip
```swift
public enum OVDStep: Int, CaseIterable {
    case frontAlign, ..., completed
    public var isCompleted: Bool { self == .completed }
}
```

### State (`@Published`, salt-okunur)
| Üye | Tip | Anlam |
|---|---|---|
| `step` | `OVDStep` | Mevcut adım |
| `canContinue` | `Bool` | Devam edilebilir mi |
| `isUploading` | `Bool` | Yükleme sürüyor mu |
| `rainbowProgress` | `Double` | Hologram adımı ilerlemesi |

### Ayar
| Üye | Varsayılan | Anlam |
|---|---|---|
| `requiresHologramStep` | `true` | Hologram adımı zorunlu mu |

### Hesaplanan
| Üye | Anlam |
|---|---|
| `progress: Double` | Genel ilerleme (0–1) |
| `instruction: String` | Mevcut adımın kullanıcı talimatı |

### Metotlar
| Metot | Etki |
|---|---|
| `ingest(ciImage:roi:)` | Canlı kareyi değerlendirir (glare/texture/rainbow skorları) |
| `forceCapture(ciImage:roi:)` | Skorları beklemeden zorla yakalar |
| `capture(image:)` | Yakalanan görseli işler (`makeUIImage` + `processCaptured`) |
| `advance()` | Sonraki adım; son adımda **`onCompleted?()`** |
| `reset()` | Akışı başa alır |
| `requestSkip()` | `onSkipRequested?()` tetikler |

### Closure'lar
| Üye | Ne zaman |
|---|---|
| `onCompleted: (() -> Void)?` | Tüm OVD adımları + yükleme bitti |
| `onSkipRequested: (() -> Void)?` | Atlama istendi |

## Sinyal Zinciri — Perde Arkası

```
ingest(ciImage:roi:)  → manager.ovdGlareScore / ovdTextureMean / ovdRainbowScoreDetailed (cihazda)
capture(image:)       → manager.makeUIImage + processCaptured + uploadIdPhoto [HTTP]
advance()  (son adım) → onCompleted?()  → host: coordinator.advanceToNextModule() [modulePresented]
```

## Host VM ile Gözlem (Composition)

```swift
@MainActor
final class IdCardOVDHostViewModel: HostModuleViewModel {
    let sdk = SDKIdCardOVDViewModel()
    override init() {
        super.init(); bridge(sdk)
        sdk.onCompleted     = { [weak self] in self?.log("ovd_done") }
        sdk.onSkipRequested = { [weak self] in self?.log("ovd_skip") }
    }
    var instruction: String { sdk.instruction }
    var progress: Double { sdk.progress }
}
```

---

## Sesli Okuma (Read-Aloud)

Ekran açıldığında yönerge otomatik seslendirilebilir (`SDKFlowHostView` yapar, kod gerekmez).

```swift
SDKSpeechConfig.shared.setMode(.native, for: .idcard_w_ovd)        // Siri/sistem sesi
// veya kendi kaydınız: bundle'a IdCardOVDTts.m4a koyun →
SDKSpeechConfig.shared.audioBundle = Bundle.main
SDKSpeechConfig.shared.setMode(.customAudio, for: .idcard_w_ovd)   // dosya yoksa native'e düşer
```

Metni ezmek: `SDKLocalization.shared.setOverride(key: .idCardOVDTts, language: .tr, value: "...")`
· Tüm ayrıntı: [ReadAloud](../ReadAloud.md)

## Sık Sorulanlar & Dikkat Edilecekler

- **Hologram adımı atlanabilir mi?** `requiresHologramStep = false` — düşük donanımlı
  cihaz senaryoları için.
- **Performans:** `ingest` her karede çağrılır ve pahalıdır; kamera frame rate'ini makul
  tutun (ör. 15–30 fps yeterli).
- **Skorlar takılıyorsa:** Işık koşulları kritik — kullanıcıya parlamayı azaltacak yönerge
  verin; gerekirse `forceCapture` ile kilitlemeyi kırın.
