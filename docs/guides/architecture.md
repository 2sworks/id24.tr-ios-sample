# Mimari — SDK'nın Büyük Resmi

Bu rehber, IdentifySDK'nın nasıl kurgulandığını anlatır: hangi parça neyi yönetir,
bir modül ekranı nasıl açılır, soket ve görüntülü görüşme neden ekranlardan bağımsız yaşar.

← [README'ye dön](../../README.md)

---

## Katmanlar

```
┌─────────────────────────────────────────────────────────┐
│  Host Uygulama (sizin kodunuz)                          │
│  RootView · LoginView · (isteğe bağlı) custom ekranlar  │
├─────────────────────────────────────────────────────────┤
│  DefaultUI (SDK içinde, SwiftUI)                        │
│  SDKFlowHostView · SDKFlowCoordinator · SDKViewRegistry │
│  Modül ekranları (SDKSelfieView...) + ViewModel'leri    │
├─────────────────────────────────────────────────────────┤
│  Çekirdek — IdentifyManager.shared (singleton)          │
│  Modül hattı · oturum durumu · iş mantığı (OCR, NFC...) │
├──────────────┬──────────────────┬───────────────────────┤
│  SDKNetwork  │  WebSocket       │  WebRTCClient         │
│  (HTTP)      │  (Starscream)    │  (görüntülü görüşme)  │
└──────────────┴──────────────────┴───────────────────────┘
                        │
                 Identify Backend
```

En önemli tasarım kararı: **soket ve WebRTC, `IdentifyManager` singleton'ında yaşar.**
Ekranlar (View'lar) gelip geçer; bağlantılar onlardan etkilenmez. Bu yüzden akışın
ortasına kendi ekranınızı sokmak bağlantıyı bozmaz.

---

## Oturumun Yaşam Döngüsü

Bir KYC oturumu şu adımlardan geçer:

1. **`coordinator.prepareForSetup()`** — DefaultUI, SDK'nın beklediği placeholder
   controller'ları kaydeder. *Bu çağrı `setupSDK`'dan önce yapılmazsa modüller hiç başlamaz.*
2. **`setupSDK(identId:...)`** — SDK, `baseApiUrl` üzerinden odaya bağlanır (`connectToRoom`).
3. **Backend cevabı: `RoomResponse`** — içinde bu oturum için gereken her şey vardır:
   `modules` (hangi adımlar, hangi sırayla), `ws_url` (soket adresi), karşılaştırma hakları,
   TURN/soket güvenlik bayrakları... Ayrıntı: [Sunucu & API](server-api.md).
4. **Modül hattı kurulur** — SDK, `modules` listesinden `modulesControllersArray` ve
   `identifyModules` dizilerini oluşturur (`addWebModules` → `addModules`).
5. **Soket bağlanır** — gerekiyorsa token'lı (`socket_auth`). Ayrıntı: [WebSocket](websocket.md).
6. **`coordinator.start()`** — ilk modülün rotası `path`'e push edilir, ekran görünür.
7. **Modüller sırayla akar** — her modül işini bitirince `advanceToNextModule()` çağrılır;
   SDK backend'e adım sinyali gönderir ve sıradaki rota açılır.
8. **Terminal: ThankYou** — akış sonucu (başarılı / reddedildi / beklemede) gösterilir.

---

## DefaultUI Üçlüsü

SwiftUI tarafındaki her şey üç yapı üzerinde döner:

| Yapı | Tip | Görev |
|---|---|---|
| `SDKFlowCoordinator` | `ObservableObject` | Akışın beyni: modül geçişleri (ileri/atla/geri), navigasyon `path`'i, ilerleme sayacı, `IdentifyManager` köprüsü |
| `SDKViewRegistry` | sınıf | Ekran çözümleme defteri: rota → view eşlemesi; override ve custom ekran kayıtları |
| `SDKFlowHostView` | `View` | Kök view: `coordinator.path`'teki rotayı çizer; önce registry'ye bakar, kayıt yoksa SDK'nın hazır ekranına düşer |

Ekran çözümleme sırası her rota için aynıdır:

```
rota geldi → registry.override(...) kaydı var mı? ─ evet → sizin ekranınız
                                                  └ hayır → SDK'nın drop-in ekranı
```

### Modül ViewModel'leri

Her modülün bir `SDKXxxViewModel`'i vardır; hepsi şu tabandan türer:

```swift
@MainActor open class SDKBaseModuleViewModel: ObservableObject {
    @Published public var isLoading: Bool
    @Published public var errorMessage: String?
    let manager = IdentifyManager.shared
}
```

VM'ler `public final`'dır: davranışları **ezilemez**, yalnızca **sarılır** (composition).
Kendi ekranınızı yapsanız bile iş mantığını (tarama, yükleme, adım sinyali) yine bu VM'ler
yürütür — buna ["bypass yok" kuralı](customization.md#bypass-yok-kuralı) denir.

### Coordinator API — sık kullanılanlar

| Üye | Görev |
|---|---|
| `prepareForSetup()` | `setupSDK`'dan **önce**; placeholder controller kaydı |
| `start()` | İlk modüle geçiş |
| `advanceToNextModule()` | Sıradaki modül (varsa araya eklenmiş custom ekranlar önce) |
| `skipCurrentModule()` | Modülü atla (`manager.skipModule()` + ilerle) |
| `insert(_:before:)` / `insert(_:after:)` | Bir rotanın önüne/arkasına custom ekran zincirle |
| `showExternalScreen(_:)` / `advanceExternal()` | Anlık custom ekran göster / custom ekrandan devam et |
| `popBack()` | Geri; kökteyse `exitSDK()` |
| `pushThankYouDirectly(status:)` | Görüşme sonucuyla doğrudan sonuç ekranına |
| `resetFlow()` | Her şeyi sıfırla |

Yayınlanan durumlar: `path`, `activeModule`, `progressStep`, `progressTotal`, `sdkError`,
`subRejected`, `pendingThankYouStatus` — host UI (ör. ilerleme çubuğu) bunlara bağlanabilir.

---

## Modüllerin Dış Dünya Bağımlılıkları

Her modül aynı altyapıyı kullanmaz; kimisi tamamen cihaz üzerinde çalışır:

| Bağımlılık | Modüller |
|---|---|
| Yalnızca cihaz üzerinde (soket yok) | IdCard (OCR), IdCardOVD, Selfie, Liveness (kare analizi), Prepare (izinler) |
| HTTP upload (sonuç sunucuya gider) | IdCard, IdCardOVD, NFC, Selfie, Liveness, Signature, VideoRecorder, AddressConfirm |
| Soket sinyali (adım/durum bildirimi) | Prepare, SignLang, Speech, CallScreen |
| WebRTC (canlı görüntü + data channel) | CallScreen |

Pasif ekranlar (ThankYou ve sizin tanıtım/başarı ekranlarınız) hiçbir sinyal göndermez;
akışın arasına eklenmeleri her zaman güvenlidir.

---

## Kesişen Sistemler

Modüllerin hepsine dokunan yatay katmanlar ayrı rehberlerde anlatılır:

- [WebSocket yapısı ve reconnect](websocket.md) — bağlantı kopması dahil
- [TURN & WebRTC](turn-webrtc.md) — görüşme altyapısı
- [Loglama](logging.md) · [Event sistemi](events.md) — izleme
- [Tema](theming.md) · [Lokalizasyon](localization.md) — görünüm ve dil
- Sesli okuma (Read-Aloud) — [ReadAloud rehberi](../../NewTest/Modules/ReadAloud.md)
