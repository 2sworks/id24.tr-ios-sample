# SignLang — İşaret Dili Kapısı

Bağımsız bir akış modülü değil, bir **kapı (gate)** ekranıdır: görüşme öncesinde kullanıcıya
"işaret dili destekli temsilci ister misiniz?" diye sorar. Tercih, backend'e sokete bildirilir
ve kullanıcı doğru temsilci kuyruğuna yönlendirilir — erişilebilirlik için küçük ama önemli
bir adım.

← [Modül İndeksi](../Modules.md) · [README](../../../README.md) · İlgili: [CallScreen](../CallScreen/CallScreen.md)

---

## Bir Bakışta

|              |                                                                       |
| ------------ | --------------------------------------------------------------------- |
| Backend key  | — (CallScreen alt-ekranı; ayrı rota yok)                              |
| Tetikleyici  | `SDKCallScreenViewModel.checkSignLangIfNeeded()` → `showSignLangGate` |
| Drop-in view | `SDKSignLangView`                                                     |
| ViewModel    | `SDKSignLangViewModel`                                                |
| Dış dünya    | **Soket** (`sendStep`)                                                |

Kapının görünmesi için `setupSDK(signLangSupport: true)` verilmelidir.

---

## ViewModel Referansı — `SDKSignLangViewModel`

VM o kadar küçük ki tamamını gösterebiliriz:

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

> Diğer modüllerin aksine `onCompleted` closure'u yoktur; `continueAction` doğrudan bir
> `onFinish` parametresi alır.

## Sinyal Zinciri — Perde Arkası

```
isSignLangEnabled = true/false           (kullanıcı tercihi)
continueAction(onFinish:)
   → manager.connectToSignLang = isSignLangEnabled
   → manager.sendStep()                  [SOKET]
   → onFinish()                          → CallScreen.signLangCompleted() / kapıyı kapat
```

---

## Kendi Tasarımınızla

Toggle'ınız nasıl görünürse görünsün, tercih **mutlaka** `continueAction`'dan geçmeli:

```swift
struct MySignLangView: View {
    @StateObject private var vm = SDKSignLangViewModel()
    let onFinish: () -> Void

    var body: some View {
        VStack {
            Toggle("İşaret dili desteği istiyorum", isOn: $vm.isSignLangEnabled)
            Button("Devam") {
                vm.continueAction(onFinish: onFinish)   // ✅ connectToSignLang + sendStep
            }
        }
    }
}
```

> ❌ **Bypass yapmayın:** `manager.connectToSignLang`'ı elle set edip geçmeyin —
> `continueAction` çağrılmazsa `sendStep` gitmez ve backend tercihi hiç görmez;
> kullanıcı yanlış kuyruğa düşer.

## Host VM ile Gözlem (Composition)

```swift
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
```

---

## Sesli Okuma (Read-Aloud)

Bu ekran bir **overlay**'dir ve akış rotası olmadığından **otomatik sesli okuma uygulanmaz.**
Gerekirse elle okutun:

```swift
SDKSpeechService.shared.speak(text: "İşaret dili desteği ister misiniz?")
SDKSpeechService.shared.stop()
```

Genel bilgi: [ReadAloud](../ReadAloud.md)

## Sık Sorulanlar & Dikkat Edilecekler

- **Kapı hiç görünmüyor:** `signLangSupport: true` verilmiş mi? Kapıyı CallScreen açar
  (`checkSignLangIfNeeded()`); tek başına bir rota yoktur.
- **Kuyruk etkisi:** İşaret dili seçen kullanıcı normal görüşme kuyruğuna düşmez —
  doğru temsilci havuzuna yönlendirilir.
