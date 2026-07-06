# Event Sistemi — Akışı Veriyle İzlemek

Kullanıcı hangi adımda? Selfie kaç kez başarısız oldu? Görüşme kuruldu mu? Bu soruların cevabı
SDK'nın **olay (event) akışındadır**. Host uygulama bu akışa abone olup kendi analitik
altyapısına (Firebase, Adjust, kendi paneliniz...) besleyebilir.

← [README'ye dön](../../README.md) · İlgili: [Loglama](logging.md)

---

## İki API, Tek Akış

Tarihsel olarak iki dinleyici vardır; ikisi de çalışır, **yenisini öneririz**:

| API | Model | Durum |
|---|---|---|
| `SDKEventListener` (yeni) | Zengin `SDKEvent` nesnesi | ✅ Önerilen |
| `IdentifyTrackingListener` (eski) | `TrackingEventType` enum'ı | Korunuyor (geriye uyum) |

Eski `TrackingEventType` olayları, SDK içinde otomatik olarak yeni `SDKEvent` modeline
köprülenir — yani yeni API'ye abone olduğunuzda **eski enstrümantasyonun tamamını** da alırsınız.

---

## Hızlı Başlangıç

```swift
final class MyAnalytics: SDKEventListener {
    func onSDKEvent(_ event: SDKEvent) {
        // Örnek: Firebase'e ilet
        Analytics.logEvent(event.name, parameters: event.toDictionary())
    }
}

let analytics = MyAnalytics()
IdentifyManager.shared.eventDelegate = analytics   // weak tutulur — referansı siz saklayın
```

> `eventDelegate` **weak**'tir; dinleyicinizi kendi tarafınızda güçlü referansla yaşatın,
> yoksa sessizce serbest bırakılır ve olay gelmez.

---

## SDKEvent — Olayın Anatomisi

| Alan          | Tip                | Anlamı                                                                                           |
| ------------- | ------------------ | ------------------------------------------------------------------------------------------------ |
| `name`        | `String`           | Olay adı (ör. `selfie_module_completed`)                                                         |
| `category`    | `SDKEventCategory` | `session` · `module` · `call` · `network` · `error` · `navigation`                               |
| `status`      | `SDKEventStatus`   | `info` · `presented` · `completed` · `failed` · `skipped` · `success` · `abandoned` · `notFound` |
| `module`      | `String?`          | İlgili modül                                                                                     |
| `screen`      | `String?`          | İlgili ekran                                                                                     |
| `sessionId`   | `String`           | Oturum kimliği — tüm olayları tek oturumda gruplamak için                                        |
| `timestampMs` | `Int64`            | Olay zamanı (ms)                                                                                 |
| `message`     | `String?`          | Açıklama                                                                                         |
| `metadata`    | `[String: String]` | Ek bağlam                                                                                        |

### Tipik Olay Örüntüsü — Modül Yaşam Döngüsü

Her modül dört temel durumdan geçer; funnel analizi doğrudan bunlarla kurulur:

```
presented ──► completed        (Happy path)
          ├─► failed           (deneme başarısız — tekrar deneyebilir)
          └─► skipped          (hak tükendi / modül atlandı)
```

NFC için ek bir durum vardır: `notFound` (çipsiz belge).
Oturum düzeyinde ise `success` (akış bitti) ve `abandoned` (yarıda bırakıldı) görürsünüz.

### Bağlantı & Yaşam Döngüsü Olayları

Soket/TURN kapanmaları ve ön/arka plan geçişleri de olay üretir:

| Olay | Kategori | Ne zaman | Önemli metadata |
|---|---|---|---|
| `socket.closed` | `network` | Her soket kapanışında (bilinçli ya da kopma) | `code` (4100+), `case`, `category`, `deliberate`, `reason` |
| `turn.dropped` | `call` | TURN/ICE düşmesinde (4140–4142) | aynı alanlar |
| `session.background` | `session` | Uygulama arka plana geçtiğinde | `timeoutSeconds`, `socketConnected` |
| `session.foreground` | `session` | Ön plana dönüşte | `elapsedSeconds`, `socketConnected` |
| `app.background` | `navigation` | (DefaultUI) arka plana geçiş — modül bilgisiyle | `state` |

`status` alanı bilinçli kapanışlarda `info`, kopmalarda `failed` gelir. Kod
tablosunun tamamı: [WebSocket rehberi → Birleşik Kapanma Kodları](websocket.md#birleşik-kapanma-kodları--sdksocketclosecode-4100).

---

## Eski API — IdentifyTrackingListener

Mevcut entegrasyonunuz varsa dokunmanıza gerek yok:

```swift
IdentifyManager.shared.trackingDelegate = self   // IdentifyTrackingListener

func eventReceived(event: TrackingEvent) { ... }
```

`TrackingEventType`, modül başına `...ModulePresented / Failed / Completed / Skipped`
case'leri ile HTTP izleme olaylarını (`HTTP_REQUEST_TRACKING_EVENT`,
`HTTP_RESPONSE_TRACKING_EVENT`) içerir. Yeni projede bunun yerine `SDKEventListener` kullanabilirisiniz.

---

## Canlı Görmek İçin: Sample App Showcase

Sample App'teki **Event Journey** ekranı (`Showcase/EventJourney/`), akış boyunca üretilen
tüm olayları kronolojik bir zaman çizelgesinde gösterir. SDK'yı ilk kez tanıyorsanız bir
oturumu baştan sona koşturup bu ekranı izlemek, olay modelini öğrenmenin en hızlı yoludur.
`SDKEventRecorder`, `SDKEventListener`'ın örnek bir implementasyonudur — kopyalayıp
kendi analitik köprünüze dönüştürebilirsiniz.

---

## Event mi Log mu?

- Ürün/analitik sorusu ("kaç kullanıcı NFC'de takıldı?") → **Event**
- Teknik sorun ("NFC neden takıldı?") → **[Log](logging.md)** (`nfc` kategorisi)
