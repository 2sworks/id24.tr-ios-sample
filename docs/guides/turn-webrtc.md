# TURN & WebRTC — Görüntülü Görüşme Altyapısı

Görüntülü görüşme modülü ([CallScreen](../../NewTest/Modules/CallScreen/CallScreen.md)) altta
[stasel/WebRTC](https://github.com/stasel/WebRTC) kullanır. Bu rehber, görüşmenin kurulum
zincirini ve TURN kimlik (credential) modlarını anlatır — `turnKey` parametresinin ne işe
yaradığı burada netleşir.

← [README'ye dön](../../README.md) · İlgili: [WebSocket](websocket.md) · [Sunucu & API](server-api.md)

---

## Parçalar

| Parça | Görev |
|---|---|
| `WebRTCClient` | Peer connection, yerel/uzak video track'leri, data channel, ICE adayları |
| STUN/TURN sunucuları | NAT arkasından medya akışını mümkün kılar; adresleri backend'den gelir |
| WebSocket | Sinyalleşme kanalı: SDP offer/answer ve ICE adayları buradan taşınır |

`WebRTCClient`'ın sahibi `IdentifyManager`'dır; ekranlardan bağımsız yaşar.
`iceTransportPolicy = .all`'dır (hem doğrudan hem TURN üzerinden bağlantı denenir).

---

## TURN Kimlikleri — Üç Mod

STUN/TURN adresleri ve kimlikleri, soket kurulumundan hemen önce `getWSCredential`
servisiyle alınır (anahtarı `RoomResponse.ws_secret_key`'dir). Kimliklerin nasıl
yorumlanacağını backend'in iki bayrağı belirler:

### 1. Düz kimlik (varsayılan)
`encrypted_turn_credential ≠ "1"` ise servis cevabındaki `username`/`credential`
olduğu gibi kullanılır. `turnKey` bu modda devreye girmez.

### 2. Şifreli kimlik — `encrypted_turn_credential == "1"`
Servis, kimlikleri **AES-256-CBC şifreli** gönderir; SDK bunları sizin `turnKey`'inizle çözer.

> ⚠️ Bu mod aktifken `turnKey` boşsa görüşme kurulamaz; konsolda `⚠️ turn key gerekli` görürsünüz.

### 3. Kısa ömürlü kimlik — `short_term_usage == "1"`
Çağrı **cevaplanırken** (`acceptCall`) SDK, kimliği yerel olarak üretir:

```
username = "<şimdi + 15 dk unix zaman>:<identId>"
password = base64( HMAC-SHA1(username, turnKey) )
```

Her çağrıda taze kimlik üretildiği için sızan bir kimlik 15 dakika sonra işe yaramaz olur.

---

## Görüşme Akışı — Uçtan Uca

```
Müşteri CallScreen'e girer
  └─ bekleme odası: updateQueue(sıra, toplam) soketten akar
Agent aramayı başlatır
  └─ soket: incomingCall ──► çağrı ekranı
Müşteri kabul eder → acceptCall()
  ├─ (short_term_usage) taze TURN kimliği üret
  ├─ WebRTCClient.connect() → SDP offer oluştur
  ├─ soket: "startCall" + SDP offer gönder
  ├─ karşı taraf answer + ICE adayları ──► medya akışı başlar
  └─ data channel açılır (agent komutları: fotoğraf çek, çember aç...)
Görüşme biter
  ├─ agent bitirirse: endCall / terminateCall(reason, statusSummary)
  ├─ müşteri bitirebilir (disableEndCallButton ile kilitlenebilir)
  └─ sonuç → ThankYou ekranı (pushThankYouDirectly)
```

Görüşme sırasında agent'ın gönderebildiği tüm komutlar için
[WebSocket → Aksiyon Kataloğu](websocket.md#aksiyon-kataloğu--sdkcallactions)'na bakın.

---

## Görüşme Deneyimini Etkileyen Ayarlar

| Ayar | Kaynak | Etki |
|---|---|---|
| `bigCustomerCam` | `setupSDK` parametresi | Müşteri kamerası büyük pencerede |
| `agent_view_scale` | `RoomResponse` | Agent görüntüsünün ölçeği (dikey gösterim dahil) |
| `hide_call_answer_screen` | `RoomResponse` | Çağrı cevaplama ekranını atla |
| `signLangSupport` | `setupSDK` parametresi | Görüşme öncesi işaret dili tercihi ([SignLang](../../NewTest/Modules/SignLang/SignLang.md)) |

---

## Kopma Durumunda WebRTC

Görüşme sırasında ICE bağlantısı `.disconnected` **veya** `.failed` duruma düşerse SDK
`terminateCall("TURN_DISCONNECTED")` yayınlar ve LostConnection/reconnect akışı devreye
girer; `.closed` ise yalnızca loglanır. Üç durum da birleşik kapanma kodlarıyla
etiketlenir: 4140 `turnDisconnected` · 4141 `turnFailed` · 4142 `turnClosed`
([WebSocket → Birleşik Kapanma Kodları](websocket.md#birleşik-kapanma-kodları--sdksocketclosecode-4100)).

Bağlantı kopup kullanıcı yeniden bağlandığında (`reconnectToSocket`), WebRTC oturumu
**yalnızca kullanıcı görüşme ekranındaysa** yeniden kurulur (video+audio+data channel) ve
`sendStep()` ile konum bildirilir. Diğer modüllerdeyken kopma, WebRTC'yi hiç ilgilendirmez.
Ayrıntı: [WebSocket → Bağlantı Kopması](websocket.md#bağlantı-kopması-ve-toparlanma).

---

## Sorun Giderme

- **Görüşme hiç kurulmuyor** → `turnKey` doğru mu? `encrypted_turn_credential` modunda boş
  `turnKey` sessizce medyasız bırakmaz, loglara `turn key gerekli` düşer ([Loglama](logging.md)).
- **Tek yönlü ses/görüntü** → Genellikle TURN kimliği geçersizdir (mod uyuşmazlığı);
  `webrtc` kategorisindeki logları inceleyin.
- **Simülatörde test** → Kamera olmadığı için görüşme ancak gerçek cihazda uçtan uca test edilir.
