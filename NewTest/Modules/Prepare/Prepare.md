# Prepare — Hazırlık Ekranı

Akışın kapı görevlisi. Kullanıcı daha hiçbir doğrulama adımına girmeden, sürecin sorunsuz
ilerlemesi için gerekenler burada toplanır: **kamera / mikrofon / konuşma izinleri** ve
(gerekiyorsa) **bağlantı hız testi**. Her şey hazır olduğunda backend'e soket üzerinden
"müşteri hazır" sinyali gider ve akış başlar.

Bu modül sayesinde kullanıcı, görüşmenin ortasında izin pop-up'larıyla bölünmez —
en sık düşülen kötü deneyim daha en başta engellenir.

← [Modül İndeksi](../Modules.md) · [README](../../../README.md)

---

## Bir Bakışta

| | |
|---|---|
| Backend key | `SdkModules.prepare` |
| Rota | `SDKModuleRoute.prepare` |
| Drop-in view | `SDKPrepareView` |
| ViewModel | `SDKPrepareViewModel` |
| Dış dünya | İzinler (cihazda) + hız testi + **soket sinyali** (`sendPreparetatus`) |
| Ses anahtarı | `PrepareTts` |

## Kullanıcı Ne Yaşar?

1. Ekranda izin satırları görür (kamera, mikrofon, konuşma) — her birine dokunup izni verir.
2. Gerekliyse kısa bir bağlantı hız testi koşar.
3. Hepsi yeşile dönünce "Devam" aktifleşir; dokunduğunda akışın ilk gerçek adımına geçilir.
4. Bir izni reddederse, onu Ayarlar'a yönlendiren bir uyarı görür.

---

## Hazır Ekranla Kullanım (Drop-in)

Hiçbir şey yazmayın — rota geldiğinde `SDKFlowHostView`, `SDKPrepareView`'ı kendisi çizer.
Görünümü markanıza uydurmak için [Tema rehberi](../../../docs/guides/theming.md) yeterlidir
(izin satırı ikonları: `permCamera`, `permMic`, `permSpeech`...).

## Kendi Tasarımınızla (Override)

UI tamamen sizin; izin isteme, hız testi ve "hazırım" sinyali SDK VM'inde kalır:

```swift
registry.override(.prepare) { MyPrepareView() }

struct MyPrepareView: View {
    @EnvironmentObject var coordinator: SDKFlowCoordinator
    @StateObject private var vm = SDKPrepareViewModel()

    var body: some View {
        VStack {
            // kendi izin/hız UI'ınız — vm.cameraAuthorized, vm.measuredSpeed... okuyun
            PermissionRow("Kamera", granted: vm.cameraAuthorized) { vm.checkCamera() }
            PermissionRow("Mikrofon", granted: vm.micAuthorized) { vm.checkMicrophone() }

            Button("Devam") {
                vm.completePrepare()                  // ✅ sendPreparetatus (soket)
            }
            .disabled(!vm.allPermissionsGranted)
        }
        .onAppear {
            vm.onCompleted = { coordinator.advanceToNextModule() }  // ✅ modulePresented
        }
    }
}
```

> ❌ **Bypass yapmayın:** Kendi izin kontrolünüzü yapıp doğrudan
> `coordinator.advanceToNextModule()` çağırırsanız `sendPreparetatus` gitmez —
> backend, müşterinin hazır olduğunu hiç öğrenmez. Kural: [bypass yok](../../../docs/guides/customization.md#bypass-yok-kuralı).

---

## ViewModel Referansı — `SDKPrepareViewModel`

### State (`@Published`, salt-okunur)
| Üye | Tip | Anlam |
|---|---|---|
| `speedCheckDone` | `Bool` | Hız testi tamamlandı mı |
| `measuredSpeed` | `CGFloat` | Ölçülen hız |
| `connectionQuality` | `SDKNetworkStatus` | Bağlantı kalitesi |
| `cameraAuthorized` | `Bool` | Kamera izni verildi mi |
| `micAuthorized` | `Bool` | Mikrofon izni verildi mi |
| `speechAuthorized` | `Bool` | Konuşma izni verildi mi |

### Yazılabilir state
| Üye | Tip | Anlam |
|---|---|---|
| `showSettingsAlert` | `Bool` | İzin reddedilince Ayarlar uyarısı |
| `settingsAlertMessage` | `String` | Uyarı metni |
| `settingsOpenAction` | `(() -> Void)?` | "Ayarlar'a git" aksiyonu |

### Hesaplanan
| Üye | Anlam |
|---|---|
| `allPermissionsGranted` | Tüm gerekli izinler verildi mi |
| `needsSpeedTest` | Hız testi gerekli mi (`manager.needSpeedTest`) |

### Metotlar
| Metot | Etki |
|---|---|
| `checkCamera()` | Kamera iznini ister/günceller |
| `checkMicrophone()` | Mikrofon iznini ister |
| `checkSpeech()` | Konuşma iznini ister |
| `startSpeedTest()` | `manager.startSpeedTest()` ile hız ölçer |
| `completePrepare()` | **`manager.sendPreparetatus` (soket) + `onCompleted?()`** |

### Closure'lar
| Üye | Ne zaman |
|---|---|
| `onCompleted: (() -> Void)?` | Hazırlık bitti — host `coordinator.advanceToNextModule()` çağırır |

## Sinyal Zinciri — Perde Arkası

```
checkCamera()/checkMicrophone()/checkSpeech()  → izinler (cihazda)
startSpeedTest()                               → manager.startSpeedTest (cihazda ölçüm)
completePrepare()  → manager.sendPreparetatus  [SOKET: hazır]  → onCompleted?()
                                                                ↓ host
                                              coordinator.advanceToNextModule()  [modulePresented]
```

## Host VM ile Gözlem (Composition)

Ekranı değiştirmeden log/analitik eklemek için SDK VM'ini sarın:

```swift
@MainActor
final class PrepareHostViewModel: HostModuleViewModel {
    let sdk = SDKPrepareViewModel()
    override init() {
        super.init()
        bridge(sdk)
        sdk.onCompleted = { [weak self] in self?.log("prepare_done") }
    }
    var ready: Bool { sdk.allPermissionsGranted && sdk.speedCheckDone }
    func grantCamera() { log("ask_camera"); sdk.checkCamera() }
}
```

---

## Sesli Okuma (Read-Aloud)

Ekran açıldığında yönerge otomatik seslendirilebilir (`SDKFlowHostView` yapar, kod gerekmez).

```swift
SDKSpeechConfig.shared.setMode(.native, for: .prepare)        // Siri/sistem sesi
// veya kendi kaydınız: bundle'a PrepareTts.m4a koyun →
SDKSpeechConfig.shared.audioBundle = Bundle.main
SDKSpeechConfig.shared.setMode(.customAudio, for: .prepare)   // dosya yoksa native'e düşer
```

Metni ezmek: `SDKLocalization.shared.setOverride(key: .prepareTts, language: .tr, value: "...")`
· Tüm ayrıntı: [ReadAloud](../ReadAloud.md)

## Sık Sorulanlar & Dikkat Edilecekler

- **Hız testi her zaman gerekli mi?** Hayır — `needsSpeedTest` `false` ise atlanabilir;
  ama `completePrepare()` yine de çağrılmalıdır (hazır sinyali her durumda gider).
- **Kullanıcı izni reddederse?** `showSettingsAlert` + `settingsOpenAction` ile Ayarlar'a
  yönlendirin; iOS, reddedilen izni uygulama içinden tekrar soramaz.
- **Simülatörde?** İzin akışı çalışır; hız testi gerçek ağa bağlıdır.
