# Loglama — SDKLog Mantığı

SDK'nın tek log giriş noktası `SDKLog` facade'idir. Bu rehber log seviyelerini (nereye yazılır),
severity/kategori etiketlerini, online log akışını ve hassas veri redaksiyonunu anlatır.

← [README'ye dön](../../README.md) · İlgili: [Event Sistemi](events.md) · [Sunucu & API](server-api.md)

---

## İki Kanal: Konsol ve Online

Her log satırı iki kanaldan birine ya da ikisine gidebilir:

- **Konsol** — Xcode çıktısı; geliştirme sırasında okursunuz.
- **Online kuyruk** — loglar toplanıp `RoomResponse.sdk_log_api_url` adresine gönderilir;
  sahadaki bir sorunu müşteri cihazına dokunmadan incelemenizi sağlar.

Hangi kanalın açık olduğunu `setupSDK(logLevel:)` belirler:

| `SDKLogLevel` | Konsol | Online | Ne zaman kullanın |
|---|---|---|---|
| `.all` (varsayılan) | ✅ | ❌ | Geliştirme |
| `.online` | ✅ | ✅ | Debug + canlı izleme |
| `.onlineSilent` | ❌ | ✅ | **Prod** — kullanıcı cihazında gürültüsüz, siz yine görürsünüz |
| `.noLog` | ❌ | ❌ | Log istemiyorum |

Online gönderim için `logOnlineSecretKey` parametresini de vermeniz gerekir.

```swift
IdentifyManager.shared.setupSDK(
    ...,
    logLevel: .onlineSilent,
    logOnlineSecretKey: "LOG-ANAHTARINIZ",
    ...
)
```

---

## Severity ve Kategori

Her log satırı bir **önem derecesi** ve bir **kategori** taşır:

```swift
SDKLog.debug("frame alındı", .liveness)
SDKLog.info("oda kuruldu", .general)
SDKLog.warning("token süresi doldu, yenileniyor", .socket)
SDKLog.error("çip okunamadı", .nfc)
```

| Severity | Etiket | Konsol işareti |
|---|---|---|
| `.debug` | DEBUG | 🔍 |
| `.info` | INFO | ℹ️ |
| `.warning` | WARN | ⚠️ |
| `.error` | ERROR | 🔴 |

> Severity yalnızca **etikettir** — online gönderimi etkilemez. Filtreleme kanal bazındadır
> (`SDKLogLevel`), satır bazında değildir.

Kategoriler, online payload'daki `type` alanına yazılır; panelde buna göre filtrelersiniz:

`general` · `socket` · `nfc` · `ocr` · `webrtc` · `network` · `liveness` · `offer` · `lifecycle`

(`lifecycle`, uygulamanın ön/arka plan geçişlerini izler — "kullanıcı NFC sırasında uygulamayı
arka plana attı" gibi durumları yakalamak için birebirdir.)

---

## Silent Bayrağı — 🔕

Bazı loglar konsolu kirletmesin ama online'a yine de gitsin istersiniz (ör. saniyede
birkaç kez üretilen ölçümler). Bunun için satır bazında `silent`:

```swift
SDKLog.debug("liveness skoru: \(score)", .liveness, silent: true)
```

`silent: true` satırı konsola basılmaz; online kanal davranışı değişmez.

---

## Hassas Veri Redaksiyonu

Log altyapısı, mesaj içindeki **uzun Base64 blokları** (görsel/video payload'ları) otomatik
kısaltır. Böylece online loglarda müşteri kimlik fotoğrafı ya da selfie verisi taşınmaz;
sadece payload'ın var olduğu ve boyutu izlenebilir kalır.

---

## Soket Trafiği Logları

Gelen/giden her soket mesajı `socket` kategorisiyle loglanır (`incoming` / `outgoing` yönü
işaretlenir). Bir akış sorununu incelerken genellikle en bilgilendirici kayıtlar bunlardır:
agent'ın ne gönderdiğini ve SDK'nın ne cevap verdiğini kronolojik görürsünüz.

---

## Log mu Event mi?

- **Log** = serbest metin, geliştirici için; sorun ayıklarken okunur.
- **Event** = yapılandırılmış olay (`SDKEvent`), analitik/izleme için; koda değil veriye bakılır.

"Kullanıcı selfie adımını kaç kere başarısız yaptı?" sorusunun cevabı loglarda değil,
[Event Sistemi](events.md)'ndedir.
