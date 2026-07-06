# LostConnection — Bağlantı Koptu Ekranı

İnternet ya da soket bağlantısı koptuğunda kullanıcıyı karşılayan kurtarma ekranı. Bağımsız
bir akış modülü değildir — kullanıcı **hangi modülde olursa olsun** devreye girebilen bir
overlay'dir. Amaç basit: paniği önle, yeniden bağlan, kullanıcıyı **kaldığı yerden** devam ettir.

Kopmanın nasıl tespit edildiği ve reconnect'in perde arkası için:
[WebSocket → Bağlantı Kopması](../../../docs/guides/websocket.md#bağlantı-kopması-ve-toparlanma)

← [Modül İndeksi](../Modules.md) · [README](../../../README.md)

---

## Bir Bakışta

| | |
|---|---|
| Backend key | — (overlay; ayrı rota yok) |
| Tetikleyici | Global `.connectionErr` yayını (reachability veya soket kopması) / `SDKCallScreenViewModel.showLostConnection` |
| Drop-in view | `SDKLostConnectionView` |
| ViewModel | `SDKLostConnectionViewModel` |
| Dış dünya | **Soket** reconnect (`manager.reconnectToSocket`) |

## Kullanıcı Ne Yaşar?

1. Bağlantı gider; ekranda "Bağlantı koptu" overlay'i belirir.
2. Cihaz ağa dönene kadar "Yeniden bağlan" pasiftir (`isNetworkAvailable` izlenir).
3. Butona basınca reconnect denenir; başarıda overlay kapanır, akış kaldığı modülden sürer.
4. Kopma görüşme sırasındaysa ve temsilci bu arada sonucu girdiyse, kullanıcı doğrudan
   sonuç ekranına taşınır.

---

## Kullanım

```swift
// Drop-in (overlay olarak)
if vm.showLostConnection {
    SDKLostConnectionView()
}
```

DefaultUI kullanıyorsanız bunun için kod yazmanız gerekmez — global `.connectionErr`
yayını overlay'i otomatik tetikler.

## Kendi Tasarımınızla

```swift
struct MyLostConnectionView: View {
    @StateObject private var vm = SDKLostConnectionViewModel()

    var body: some View {
        VStack {
            Text(vm.isNetworkAvailable ? "Bağlantı koptu" : "İnternet bağlantınız yok")
            if vm.isReconnecting { ProgressView() }
            Button("Yeniden bağlan") { vm.reconnect() }       // ✅ reconnectToSocket
                .disabled(!vm.canReconnect)
        }
        .onAppear {
            vm.onReconnectCompleted = { /* overlay'i kapat */ }
            vm.onReconnectCompletedWithStatus = { ok, status in /* sonuç geldiyse işle */ }
        }
    }
}
```

---

## ViewModel Referansı — `SDKLostConnectionViewModel`

### State (`@Published`, salt-okunur)
| Üye | Tip | Anlam |
|---|---|---|
| `isReconnecting` | `Bool` | Yeniden bağlanma sürüyor mu |
| `isNetworkAvailable` | `Bool` | Cihazın ağ erişimi var mı |

### Hesaplanan
| Üye | Anlam |
|---|---|
| `canReconnect: Bool` | Denenebilir mi (ağ var **ve** deneme sürmüyor) |

### Metotlar
| Metot | Etki |
|---|---|
| `reconnect()` | Soketi yeniden bağlar (`manager.reconnectToSocket`) |

### Closure'lar
| Üye | Ne zaman |
|---|---|
| `onReconnectCompleted: (() -> Void)?` | Yeniden bağlanma başarılı (statüsüz) |
| `onReconnectCompletedWithStatus: ((Bool, String?) -> Void)?` | Sonuç + opsiyonel görüşme statüsüyle |

## Sinyal Zinciri — Perde Arkası

```
(internet gitti / soket koptu) → .connectionErr (tek sefer) → overlay görünür
reconnect()  → manager.reconnectToSocket [SOKET]
   ├─ socket_auth aktifse yeni token üretilir
   ├─ başarılı (statüsüz)       → onReconnectCompleted?()
   └─ başarılı (sonuç statülü)  → onReconnectCompletedWithStatus?(success, status)
host/CallScreen: overlay kapanır, akış kaldığı modülden devam eder
```

CallScreen tarafında bu closure'lar `handleReconnectCompleted()` /
`handleReconnectCompletedWithStatus(...)` metotlarına bağlanır.

---

## Sesli Okuma (Read-Aloud)

Bu ekran bir **overlay**'dir ve akış rotası olmadığından **otomatik sesli okuma uygulanmaz.**
Gerekirse elle okutun:

```swift
SDKSpeechService.shared.speak(text: "Bağlantınız koptu, lütfen yeniden bağlanın.")
SDKSpeechService.shared.stop()
```

Genel bilgi: [ReadAloud](../ReadAloud.md)

## Sık Sorulanlar & Dikkat Edilecekler

- **"Yeniden bağlan" hep pasif:** Cihazın ağı yok (`isNetworkAvailable == false`) —
  kullanıcıyı Wi-Fi/hücresel ayarlarına yönlendirin; ağ dönünce buton açılır.
- **Reconnect ile ne geri gelir?** Soket bağlantısı ve oturum kaydı; kullanıcı görüşme
  ekranındaysa WebRTC oturumu da CallScreen tarafından yeniden kurulur.
- **Sürekli başarısızsa:** Akış `disconnect()` yoluna gidebilir ve oturum sonlanır;
  kullanıcı yeni bir `identId` süreciyle geri döner.
- **Overlay her modülde çıkar mı?** Evet — kopma tespiti globaldir (reachability + soket);
  KYC tamamlandıktan sonra tetiklenmez.
