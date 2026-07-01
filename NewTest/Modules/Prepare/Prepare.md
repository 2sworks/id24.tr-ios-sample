# Prepare — Hazırlık (izinler + hız testi)

Akışın ilk modülü. Kamera/mikrofon/konuşma izinlerini ister ve (gerekiyorsa) ağ hız testi
yapar. Hepsi tamamlanınca `sendPreparetatus` ile soket üzerinden backend'e "hazır"
bilgisini gönderir ve sıradaki modüle geçer.

| | |
|---|---|
| Backend key | `SdkModules.prepare` |
| Rota | `SDKModuleRoute.prepare` |
| Drop-in view | `SDKPrepareView` |
| ViewModel | `SDKPrepareViewModel` |
| Bağımlılık | İzinler (on-device) + hız testi + **soket sinyali** (`sendPreparetatus`) |

---

## VM API — `SDKPrepareViewModel`

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

### Girdi (metotlar)
| Metot | Etki |
|---|---|
| `checkCamera()` | Kamera iznini ister/günceller |
| `checkMicrophone()` | Mikrofon iznini ister |
| `checkSpeech()` | Konuşma iznini ister |
| `startSpeedTest()` | `manager.startSpeedTest()` ile hız ölçer |
| `completePrepare()` | **`manager.sendPreparetatus` (soket) + `onCompleted?()`** |

### Çıktı (closure)
| Üye | Ne zaman |
|---|---|
| `onCompleted: (() -> Void)?` | Hazırlık bittiğinde — host `coordinator.advanceToNextModule()` çağırır |

---

## Sinyal zinciri

```
checkCamera()/checkMicrophone()/checkSpeech()  → izinler (on-device)
startSpeedTest()                               → manager.startSpeedTest (on-device ölçüm)
completePrepare()  → manager.sendPreparetatus  [SOKET: hazır]  → onCompleted?()
                                                                ↓ host
                                              coordinator.advanceToNextModule()  [modulePresented]
```

---

## Drop-in kullanım

```swift
// Hiçbir şey yazmayın — SDKFlowHostView default'u çizer:
case .prepare: SDKPrepareView()
```

## Host VM (gözlem)

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

## Custom tasarım (override) — bypass-safe

```swift
registry.override(.prepare) {
    MyPrepareView()   // @StateObject var vm = SDKPrepareViewModel()
}
```

İçeride **mutlaka** SDK VM'ini kullanın:

```swift
struct MyPrepareView: View {
    @EnvironmentObject var coordinator: SDKFlowCoordinator
    @StateObject private var vm = SDKPrepareViewModel()

    var body: some View {
        VStack {
            // ... kendi izin/hız UI'ınız, vm.cameraAuthorized vb. okuyun ...
            Button("Devam") {
                vm.completePrepare()                  // ✅ sendPreparetatus (soket)
            }
            .disabled(!vm.allPermissionsGranted)
        }
        .onAppear {
            vm.onCompleted = { coordinator.advanceToNextModule() }  // ✅ modulePresented
            vm.checkCamera(); vm.checkMicrophone()
        }
    }
}
```

> ❌ Kendi izin kontrolünüzü yapıp `coordinator.advanceToNextModule()`'ü doğrudan çağırmayın:
> `sendPreparetatus` gitmez, backend hazırlığı görmez.

## Notlar
- `needsSpeedTest` `false` ise hız testi atlanabilir; yine de `completePrepare()` çağrılmalı.
- İzin reddinde `showSettingsAlert` + `settingsOpenAction` ile kullanıcıyı Ayarlar'a yönlendirin.

---

## Sesli Okuma (Read-Aloud)

Bu modül ekranı açıldığında yönergesi otomatik seslendirilebilir. Mod **modül bazında**
seçilir; tam ayrıntı: [ReadAloud](../ReadAloud.md).

- **Metin key'i:** `PrepareTts`  ·  **Custom audio dosyası:** `PrepareTts.<uzantı>`
  (uzantı serbest: `m4a`/`mp3`/`wav`/`caf`/`aac`/`aiff` otomatik denenir)
- **Native (Siri / sistem sesi):**
  ```swift
  SDKSpeechConfig.shared.setMode(.native, for: .prepare)
  ```
- **Custom audio (kendi kaydın):** bundle'a `PrepareTts.<uzantı>` koy (örn. `PrepareTts.m4a` veya `PrepareTts.mp3`) →
  ```swift
  SDKSpeechConfig.shared.audioBundle = Bundle.main
  SDKSpeechConfig.shared.setMode(.customAudio, for: .prepare)   // dosya yoksa native'e düşer
  ```
- **Kapalı:** `SDKSpeechConfig.shared.setMode(.off, for: .prepare)`
- **Metni ez:** `SDKLocalization.shared.setOverride(key: .prepareTts, language: .tr, value: "...")`

Seslendirme, ekran açılışında `SDKFlowHostView` tarafından otomatik yapılır — modül tarafında
ekstra kod gerekmez.

</content>
