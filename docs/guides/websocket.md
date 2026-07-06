# WebSocket — Canlı Sinyal Kanalı

SDK, oturum boyunca backend ile açık bir WebSocket bağlantısı tutar. Gelen çağrı, SMS onayı,
agent komutları, adım bildirimleri — hepsi bu kanaldan akar. Bu rehber bağlantının nasıl
kurulduğunu, token güvenliğini (`socket_auth`), aksiyon kataloğunu ve **bağlantı koptuğunda
ne olduğunu** anlatır.

← [README'ye dön](../../README.md) · İlgili: [Sunucu & API](server-api.md) · [TURN & WebRTC](turn-webrtc.md)

---

## Bağlantının Kurulması

Soket adresi (`ws_url`) sizin verdiğiniz bir şey değildir; `connectToRoom` cevabından gelir.
İstemci [Starscream](https://github.com/daltoniam/Starscream) WebSocket'idir.

```
RoomResponse.ws_url ──► WebSocket(url:)
                          │  socket_auth == "1" ise: ws_url + "?token=<HMAC token>"
                          ▼
                        connect() ──► sendFirstSubscribe()   (odaya kayıt)
```

Bağlantı denemesi ~30 saniye içinde başarısız olursa `setupSDK` callback'ine hata döner.

### `socket_auth` — Token'lı Bağlantı

Backend `socket_auth = "1"` gönderiyorsa, SDK soket URL'ine kısa ömürlü bir imzalı token ekler.
Bunun çalışması için `setupSDK`'ya **`wsSecretKey`** vermeniz zorunludur.

Token şu şekilde üretilir (bilgi amaçlı — hepsi SDK içinde otomatiktir):

```
payload   = "<form_uid>:<şimdi + 60sn unix zaman>:<4 bayt rastgele hex>"
imza      = HMAC-SHA256(payload, wsSecretKey)     → hex
token     = base64("payload.imza")
soket URL = ws_url + "?token=" + token
```

Token 60 saniye geçerlidir; **her reconnect'te otomatik olarak yenisi üretilir.**
`wsSecretKey` yanlışsa soket hiç bağlanmaz — Login aşamasında "WS key hatası" görürsünüz.

---

## Aksiyon Kataloğu — `SDKCallActions`

Soketten gelen mesajlar `SDKCallActions` enum'ına çevrilir ve dinleyicilere iletilir.
DefaultUI kullanıyorsanız bunların hepsi zaten hazır ekranlarca işlenir; kendi ekranınızı
yazıyorsanız ilgilendiğiniz aksiyonları dinlersiniz.

| Aksiyon | Anlamı |
|---|---|
| `incomingCall` | Agent arıyor — çağrı ekranı açılmalı |
| `endCall` | Agent görüşmeyi bitirdi |
| `missedCall` | Çağrı cevapsız kaldı |
| `terminateCall(reason, statusSummary)` | Görüşme sebep/durum bilgisiyle sonlandırıldı |
| `comingSms` / `approveSms(Bool)` | SMS doğrulama akışı |
| `openWarningCircle` / `closeWarningCircle` | Agent, müşteri ekranında uyarı çemberi açtı/kapadı |
| `openCardCircle` / `closeCardCircle` | Kimlik gösterme çemberi açıldı/kapandı |
| `photoTaken(String)` | Agent görüşme sırasında fotoğraf aldı |
| `updateQueue(sıra, toplam)` | Bekleme odasında sıra bilgisi güncellendi |
| `subscribed` | Odaya kayıt tamam |
| `subrejectedDismiss(String)` | Kayıt reddedildi (ör. süresi geçmiş ident) |
| `openNfcRemote(...)` | Agent, uzaktan NFC adımı başlattı |
| `editNfcProcess` | Agent, NFC verisinde düzeltme istedi |
| `startTransfer` | Görüşme başka agent'a aktarılıyor |
| `networkQuality(String)` | Bağlantı kalite bildirimi |
| `disableEndCallButton` | Müşterinin "görüşmeyi bitir" butonu kilitlendi |
| `imOffline` | Karşı taraf çevrimdışı |
| `connectionErr` | **Bağlantı koptu** (aşağıya bakın) |
| `wrongSocketActionErr(String)` | Tanınmayan soket mesajı |

### Dinleme

```swift
// Soket aksiyonlarını dinlemek (host tarafı)
IdentifyManager.shared.socketMessageListener = self   // SDKSocketListener

extension MyController: SDKSocketListener {
    func listenSocketMessage(message: SDKCallActions) {
        if case .connectionErr = message { /* ... */ }
    }
}
```

> DefaultUI'da `SDKFlowCoordinator` bu dinleyiciyi zaten yönetir; CallScreen gibi
> dinleyiciyi devralan ekranlar ayrılırken `coordinator.restoreSocketListener()` çağırır.

---

## Modül → Sunucu Sinyalleri

Soket yalnızca sunucudan komut almak için değildir; SDK her modül geçişinde durum bildirir:

| Sinyal | Ne zaman gider |
|---|---|
| `sendStep()` | Modül adımı tamamlandı / konum değişti |
| `sendPreparetatus(isCompleted:)` | Hazırlık modülü sonucu |
| `sendSpeechStatus(isCompleted:)` | Konuşma modülü sonucu |
| `modulePresented` (adım bildirimi) | `advanceToNextModule()` içinde |

**Bu yüzden custom ekranlar SDK VM metotlarını atlayamaz** — kendi navigasyonunuzu kurarsanız
bu sinyaller gitmez ve agent panelinde akış "takılı" görünür.
Ayrıntı: [Özelleştirme → bypass yok kuralı](customization.md#bypass-yok-kuralı).

---

## Bağlantı Kopması ve Toparlanma

SDK, kopmayı **iki bağımsız kaynaktan** tespit eder:

1. **Reachability izleyicisi** — oturum başlarken açılır; internet `.notReachable`
   olursa (ve KYC bitmemişse) devreye girer.
2. **Soket kopması** — Starscream disconnect bildirimi.

İki kaynak da aynı kapıya çıkar: `.connectionErr` **yalnızca bir kez** yayınlanır
(tekrarlar bastırılır), başarılı yeniden bağlantıda bayrak sıfırlanır.

```
internet gitti ──┐
                 ├──► emitConnectionLost() ──► .connectionErr ──► LostConnection overlay
soket koptu   ───┘         (tek sefer)
                                                    │ kullanıcı "Tekrar Bağlan"
                                                    ▼
                                          reconnectToSocket()
                                            ├─ socket_auth ise yeni token üret
                                            ├─ sendImOnline + sendReconnectSubscribe
                                            ├─ (görüşme ekranındaysa) WebRTC yeniden kur + sendStep
                                            └─ kaldığı modülden devam
```

`reconnectToSocket` eşzamanlı çift çağrıya karşı korumalıdır (`isReconnecting` guard'ı).
Kullanıcı deneyimi tarafı için: [LostConnection rehberi](../../NewTest/Modules/LostConnection/LostConnection.md).

---

## Birleşik Kapanma Kodları — `SDKSocketCloseCode` (4100+)

Soket ve TURN kapanmalarının **tamamı** SDK'ya özel tek bir kod uzayında toplanır
(RFC 6455'in "private use" 4000–4999 aralığı). Son kapanışı okumak için:

```swift
IdentifyManager.shared.lastSocketCloseCode          // SDKSocketCloseCode?
IdentifyManager.shared.lastSocketCloseCode?.rawValue // örn. 4105
```

Ayrıca her kapanışta `socket.closed` (TURN için `turn.dropped`) SDKEvent'i yayınlanır —
metadata'da `code`, `case`, `category`, `deliberate` ve varsa `reason` bulunur.
Detay: [Event Sistemi](events.md).

### 4100–4109 · Bilinçli kapanışlar
SDK'nın kendisi kapatır; kod **close frame ile sunucuya da gider**.

| Kod | Case | Ne zaman |
|---|---|---|
| 4100 | `flowCompleted` | Son modül tamamlandı, teşekkür ekranına geçiliyor |
| 4101 | `hostQuit` | `quitSDK()` |
| 4102 | `hostExit` | `exitSDK()` |
| 4103 | `forceQuit` | `forceQuitSDK()` |
| 4104 | `reconnectCycle` | Reconnect öncesi eski bağlantının kapatılması |
| 4105 | `backgroundTimeout` | Uygulama arka planda limit süreyi aştı (aşağıya bakın) |

### 4110–4118 · Sunucu/protokol kaynaklı (gelen standart kodun etiketi)

| Kod | Case | Kaynak | Davranış |
|---|---|---|---|
| 4110 | `serverNormal` | 1000 | sadece log |
| 4111 | `serverGoingAway` | 1001 | sadece log |
| 4112 | `noStatusReceived` | 1005 | sadece log |
| 4113 | `protocolError` | 1002 | listener'a `.wrongSocketActionErr` |
| 4114 | `unsupportedFrame` | 1003 | listener'a `.wrongSocketActionErr` |
| 4115 | `encodingError` | 1007 | listener'a `.wrongSocketActionErr` |
| 4116 | `policyViolated` | 1008 | listener'a `.wrongSocketActionErr` |
| 4117 | `messageTooBig` | 1009 | listener'a `.wrongSocketActionErr` |
| 4118 | `unknownWsError` | diğer | listener'a `.wrongSocketActionErr` (tip detayı reason'da) |

### 4130–4132 · Ağ kaynaklı — hepsi LostConnection overlay'ini tetikler

| Kod | Case | Kaynak |
|---|---|---|
| 4130 | `networkUnreachable` | Reachability: internet erişimi yok |
| 4131 | `transportError` | SSL / proxy / firewall hatası |
| 4132 | `unexpectedDrop` | Hatasız kopma — sunucu sessiz kapattı |

### 4140–4142 · TURN / ICE (WebRTC)

| Kod | Case | Kaynak | Davranış |
|---|---|---|---|
| 4140 | `turnDisconnected` | ICE `.disconnected` | `terminateCall("TURN_DISCONNECTED")` → LostConnection |
| 4141 | `turnFailed` | ICE `.failed` | `terminateCall("TURN_DISCONNECTED")` → LostConnection |
| 4142 | `turnClosed` | ICE `.closed` | log + event |

### Arka Plan Zaman Aşımı (4105)

Aktif oturum sırasında uygulama arka plana geçerse SDK süre sayar; limit aşılırsa
soket **4105** ile kapatılır ve kullanıcı döndüğünde LostConnection/reconnect ekranı
hazırdır. Sistem uygulamayı erken dondurursa süre, ön plana dönüşte telafi edilir.

```swift
IdentifyManager.shared.backgroundTimeoutSeconds = 30   // varsayılan 30 sn
IdentifyManager.shared.isBackgroundTimeoutEnabled = true // kapatmak için false
```

Geçişlerin kendisi de olay üretir: `session.background` (limit + soket durumu) ve
`session.foreground` (arka planda geçen süre).

---

## Soket Trafiğini İzleme

Gelen/giden tüm soket mesajları log altyapısına `socket` kategorisiyle düşer
(`SocketLog`: `incoming`/`outgoing`). Konsolda görmek için `logLevel: .all` yeterlidir;
online'a da göndermek için `.online`. Ayrıntı: [Loglama](logging.md).
