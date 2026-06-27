# LostConnection — Bağlantı koptu (kurtarma overlay'i)

Soket/ağ bağlantısı koptuğunda gösterilen kurtarma ekranı. Bağımsız bir akış modülü
değildir; genelde CallScreen tarafından `showLostConnection` ile bir overlay olarak
sunulur. Kullanıcı yeniden bağlanmayı dener (`reconnectToSocket`); başarıda görüşme/akış
kaldığı yerden devam eder.

| | |
|---|---|
| Backend key | — (overlay; ayrı rota yok) |
| Tetikleyici | `SDKCallScreenViewModel.showLostConnection` (veya ağ kopması) |
| Drop-in view | `SDKLostConnectionView` |
| ViewModel | `SDKLostConnectionViewModel` |
| Bağımlılık | **soket** reconnect (`manager.reconnectToSocket`) |

---

## VM API — `SDKLostConnectionViewModel`

### State (`@Published`, salt-okunur)
| Üye | Tip | Anlam |
|---|---|---|
| `isReconnecting` | `Bool` | Yeniden bağlanma sürüyor mu |
| `isNetworkAvailable` | `Bool` | Ağ erişimi var mı (cihaz seviyesi) |

### Hesaplanan
| Üye | Anlam |
|---|---|
| `canReconnect: Bool` | Yeniden bağlanma denenebilir mi (ağ var & sürmüyor) |

### Girdi (metot)
| Metot | Etki |
|---|---|
| `reconnect()` | Soketi yeniden bağlar (`manager.reconnectToSocket`) |

### Çıktı (closure)
| Üye | Ne zaman |
|---|---|
| `onReconnectCompleted: (() -> Void)?` | Yeniden bağlanma başarılı (statüsüz) |
| `onReconnectCompletedWithStatus: ((Bool, String?) -> Void)?` | Sonuç + opsiyonel statü ile (görüşme sonucu döndüyse) |

---

## Sinyal zinciri

```
(bağlantı koptu) → isNetworkAvailable izlenir
reconnect()  → manager.reconnectToSocket [SOKET]
   ├─ başarılı (statüsüz)       → onReconnectCompleted?()
   └─ başarılı (sonuç statülü)  → onReconnectCompletedWithStatus?(success, status)
host/CallScreen: overlay kapanır, akış devam eder
```

CallScreen tarafında bağlama:
```swift
// SDKCallScreenViewModel bu closure'ları kendi handle metotlarına bağlar:
//   handleReconnectCompleted()
//   handleReconnectCompletedWithStatus(...)
```

---

## Drop-in / Custom

```swift
// Drop-in (overlay olarak)
if vm.showLostConnection {
    SDKLostConnectionView()
}

// Custom
struct MyLostConnectionView: View {
    @StateObject private var vm = SDKLostConnectionViewModel()
    var body: some View {
        VStack {
            Text(vm.isNetworkAvailable ? "Bağlantı koptu" : "Ağ yok")
            if vm.isReconnecting { ProgressView() }
            Button("Yeniden bağlan") { vm.reconnect() }       // ✅ reconnectToSocket
                .disabled(!vm.canReconnect)
                .onAppear {
                    vm.onReconnectCompleted = { /* overlay'i kapat */ }
                    vm.onReconnectCompletedWithStatus = { ok, status in /* ... */ }
                }
        }
    }
}
```

## Notlar
- Ağ tamamen yoksa (`isNetworkAvailable == false`) `canReconnect` false olur — kullanıcıyı
  bağlantısını kontrol etmeye yönlendirin; cihaz ağa dönünce tekrar denenebilir.
- Reconnect başarısızsa coordinator `LostConnectionVM.reconnect()` üzerinden `disconnect()`
  yoluna gidebilir; bu durumda akış sonlanır.
- Bu ekran kalıcı bağlantıyı (soket) kurtarmaya çalışır; WebRTC peer connection CallScreen
  tarafından yeniden kurulur.
</content>
