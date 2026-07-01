# SignLang — İşaret dili kapısı

Bağımsız bir akış modülü değil; görüşme öncesi/sırasında kullanıcıya işaret dili desteği
isteyip istemediğini soran bir **kapı (gate)** ekranıdır. Tercih `manager.connectToSignLang`
bayrağını ayarlar ve `sendStep()` ile **soket** üzerinden backend'e bildirilir.

| | |
|---|---|
| Backend key | — (CallScreen alt-ekranı; ayrı rota yok) |
| Tetikleyici | `SDKCallScreenViewModel.checkSignLangIfNeeded()` → `showSignLangGate` |
| Drop-in view | `SDKSignLangView` |
| ViewModel | `SDKSignLangViewModel` |
| Bağımlılık | **soket** (`sendStep`) |

---

## VM API — `SDKSignLangViewModel`

```swift
public final class SDKSignLangViewModel: SDKBaseModuleViewModel {
    @Published public var isSignLangEnabled: Bool = false

    public func continueAction(onFinish: @escaping () -> Void) {
        manager.connectToSignLang = isSignLangEnabled
        manager.sendStep()        // [SOKET] tercihi backend'e bildir
        onFinish()
    }
}
```

| Üye | Tip | Anlam |
|---|---|---|
| `isSignLangEnabled` | `Bool` (r/w) | İşaret dili desteği isteniyor mu |
| `continueAction(onFinish:)` | metot | Tercihi kaydeder + `sendStep` (soket) + `onFinish` |

> Diğer modüllerin aksine bağımsız bir `onCompleted` closure'u yoktur; `continueAction`
> doğrudan bir `onFinish` parametresi alır.

---

## Sinyal zinciri

```
isSignLangEnabled = true/false           (kullanıcı tercihi)
continueAction(onFinish:)
   → manager.connectToSignLang = isSignLangEnabled
   → manager.sendStep()                  [SOKET]
   → onFinish()                          → CallScreen.signLangCompleted() / kapıyı kapat
```

---

## Drop-in / Host VM / Custom

```swift
// Host VM (SampleApp'teki gerçek desen)
@MainActor
final class SignLangHostViewModel: HostModuleViewModel {
    let sdk = SDKSignLangViewModel()
    override init() { super.init(); bridge(sdk) }

    var isEnabled: Bool {
        get { sdk.isSignLangEnabled }
        set { sdk.isSignLangEnabled = newValue; log("signlang_toggle_\(newValue)") }
    }
    func applyDefault(_ enabled: Bool) { sdk.isSignLangEnabled = enabled }
    func proceed() {
        sdk.continueAction(onFinish: { [weak self] in self?.onCompleted?() })
    }
}

// Custom tasarım — toggle + devam, ama tercihi mutlaka VM'e verin
struct MySignLangView: View {
    @StateObject private var vm = SDKSignLangViewModel()
    let onFinish: () -> Void
    var body: some View {
        Toggle("İşaret dili desteği", isOn: $vm.isSignLangEnabled)
        Button("Devam") {
            vm.continueAction(onFinish: onFinish)            // ✅ connectToSignLang + sendStep
        }
    }
}
```

> **Bypass yok:** Toggle'ı kendiniz okuyup `manager.connectToSignLang`'ı elle set etmeyin;
> `continueAction` çağırın, aksi halde `sendStep` gitmez ve backend tercihi görmez.

## Notlar
- Bu ekran genelde CallScreen tarafından `showSignLangGate` ile sunulur; tek başına bir
  modül rotası (`SDKModuleRoute`) yoktur.
- `connectToSignLang` setupSDK'daki `signLangSupport` parametresiyle de başlatılabilir.

---

## Sesli Okuma (Read-Aloud)

Bu ekran bir **overlay**'dir ve akış rotası (`route.ttsKey`) yoktur; bu yüzden **otomatik
sesli okuma uygulanmaz**. Gerekirse metni elle okutabilirsiniz:

```swift
SDKSpeechService.shared.speak(text: "…")   // native (Siri)
SDKSpeechService.shared.stop()
```

Genel bilgi: [ReadAloud](../ReadAloud/ReadAloud.md).

</content>
