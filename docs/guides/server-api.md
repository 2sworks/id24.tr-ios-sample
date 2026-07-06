# Sunucu & API — setupSDK ve Oda Yapısı

Bu rehber, SDK'nın backend ile nasıl konuştuğunu anlatır: `setupSDK`'nın tüm parametreleri,
odaya bağlanınca dönen `RoomResponse`'un akışı nasıl şekillendirdiği ve ağ seçenekleri
(timeout, SSL pinning).

← [README'ye dön](../../README.md) · İlgili: [Mimari](architecture.md) · [WebSocket](websocket.md)

---

## Büyük Resim

Tüm HTTP trafiği SDK içindeki `SDKNetwork` katmanından geçer (vendored Alamofire).
Oturum tek bir çağrıyla başlar:

```
setupSDK(identId, baseApiUrl, ...) ──► POST connectToRoom(identId)
                                          │
                            RoomResponse ◄┘
                            ├─ modules[]        → hangi adımlar, hangi sırada
                            ├─ ws_url           → WebSocket adresi
                            ├─ socket_auth      → soket token zorunlu mu
                            ├─ *_comparison_count → deneme hakları
                            ├─ encrypted_turn_credential / short_term_usage → TURN modu
                            └─ sdk_log_api_url  → online log hedefi
```

**Modül sırasına siz karar vermezsiniz** — backend `modules` dizisinde ne gönderirse akış odur.
`selectedModules` parametresiyle alt küme seçebilirsiniz; boş bırakmak "backend'in sırası" demektir.

---

## setupSDK — Tam Parametre Referansı

```swift
IdentifyManager.shared.setupSDK(
    identId: "...",
    baseApiUrl: "https://v2api.identify.com.tr/",
    networkOptions: SDKNetworkOptions(useSslPinning: false),
    kpsData: nil,
    signLangSupport: false,
    nfcMaxErrorCount: 3,
    selectedModules: [],
    turnKey: "...",
    wsSecretKey: "...",
    showThankYouPage: true
) { socket, roomResponse, error in ... }
```

| Parametre | Tip | Varsayılan | Ne işe yarar |
|---|---|---|---|
| `identId` | `String` | — | Müşteri işlem numarası; boşluklar otomatik temizlenir |
| `baseApiUrl` | `String` | — | Backend kök adresi |
| `networkOptions` | `SDKNetworkOptions` | — | Timeout + SSL pinning (aşağıda) |
| `kpsData` | `SDKKpsData?` | — | NFC/BAC için kimlik verisi; `nil` ise sunucudan şifreli gelir (aşağıda) |
| `identCardType` | `[CardType]?` | `[.idCard, .passport, .oldSchool]` | Kabul edilen belge türleri |
| `signLangSupport` | `Bool` | — | Görüşme öncesi işaret dili kapısı açılsın mı |
| `nfcMaxErrorCount` | `Int` | — | NFC'de kaç hatadan sonra pes edilir |
| `logLevel` | `SDKLogLevel?` | `.all` | Konsol/online log modu → [Loglama](logging.md) |
| `logOnlineSecretKey` | `String?` | `""` | Online log imza anahtarı |
| `bigCustomerCam` | `Bool?` | `false` | Görüşmede müşteri kamerasını büyük göster |
| `selectedModules` | `[SdkModules]` | `[]` | Boş = backend sırası; doluysa yalnız bu modüller |
| `idCardLang` | `IDLang?` | `.TR` | OCR dil ipucu |
| `needCertForNfc` | `Bool?` | `false` | NFC'de sertifika zinciri doğrulaması istensin mi |
| `turnKey` | `String` | — | TURN kimlik üretim anahtarı → [TURN & WebRTC](turn-webrtc.md) |
| `wsSecretKey` | `String?` | `nil` | `socket_auth` aktifse soket token anahtarı → [WebSocket](websocket.md) |
| `showThankYouPage` | `Bool?` | `false` | Akış sonunda SDK'nın sonuç ekranı gösterilsin mi |
| `showNFCNotFoundPage` | `Bool?` | `false` | Çipsiz belge için "NFC yok" ekranı |
| `supportU18` | `Bool?` | `false` | 18 yaş altı desteği |
| `AESKey` | `String?` | `""` | Sunucudan gelen şifreli MRZ alanlarını çözme anahtarı |
| `enableAutoRotateOCR` | `Bool?` | `false` | Yamuk çekilen kimliği otomatik döndür |
| `ttsEnabled` | `Bool?` | `false` | Sesli okuma kısayolu (`defaultMode .off` ise `.native` yapar) |
| `callback` | closure | — | `(WebSocket?, RoomResponse, SDKWebError?)` |

### Callback'te başarı kontrolü

```swift
{ socket, roomResponse, error in
    Task { @MainActor in
        if error == nil, socket?.isConnected == true, roomResponse.result == true {
            coordinator.start()
        } else {
            // error?.message kullanıcıya gösterilebilir metin içerir
        }
    }
}
```

---

## RoomResponse — Akışı Şekillendiren Alanlar

`connectToRoom` cevabındaki önemli alanlar ve etkileri:

| Alan | Etki |
|---|---|
| `modules` | Modül sırası — akışın iskeleti |
| `ws_url` | Soket adresi |
| `ws_secret_key` | STUN/TURN credential servisi için anahtar |
| `socket_auth` | `"1"` ise soket bağlantısına HMAC token eklenir |
| `nfc/selfie/ocr_comparison_count` | Modül başına deneme hakkı; tükenince atlama devreye girebilir |
| `active_comparison_result_skip_module` | Aktif karşılaştırma sonucuna göre modül atlama |
| `encrypted_turn_credential`, `short_term_usage` | TURN kimlik modu → [TURN & WebRTC](turn-webrtc.md) |
| `liveness`, `liveness_recording`, `liveness_report*` | Canlılık adım sırası ve kayıt/rapor ayarları |
| `video_record_speech*`, `speech_expected_sentence`, `video_record_duration` | Kısa videoda sesli okuma doğrulaması (metin + eşik + süre) |
| `agent_view_scale` | Görüşmede agent görüntü oranı |
| `hide_call_answer_screen` | Çağrı cevaplama ekranını gizle |
| `request_max_body_size` | Upload boyut sınırı (sunucudan gelir) |
| `sdk_log_api_url` | Online logların gönderileceği adres |

### Şifreli MRZ verisi (kpsData yerine)

`kpsData: nil` verirseniz backend, NFC için gereken üç MRZ alanını (doğum tarihi,
seri no, son geçerlilik) **AES-256-CBC şifreli** gönderir; SDK bunları `AESKey`
parametresiyle çözer. Yani NFC'yi kendi KPS verinizle de, sunucu verisiyle de besleyebilirsiniz.

---

## SDKNetworkOptions — Ağ Ayarları

```swift
// Basit kullanım
SDKNetworkOptions(useSslPinning: false)

// Tam kontrol
SDKNetworkOptions(
    timeoutIntervalForRequest: 30,      // saniye
    timeoutIntervalForResource: 30,
    useSslPinning: true,
    sslPinningBundles: [Bundle(for: MySDKToken.self)]  // ara katman SDK'ları için
)
```

### SSL Pinning nasıl çalışır

`useSslPinning: true` verildiğinde SDK, `.cer` uzantılı sertifikaları şu sırayla arar:

1. `sslPinningBundles` ile verdiğiniz özel bundle'lar (ör. banka içi ara-SDK)
2. IdentifySDK'nın kendi bundle'ı
3. Uygulamanın main bundle'ı

Sertifikanızı bu konumlardan birine koymanız yeterlidir; örnek sertifika Sample App'te mevcuttur.

---

## Hata Modeli

HTTP hataları `SDKWebError` olarak döner (`message` alanı kullanıcıya gösterilebilir).
Sunucu `result == false` döndürürse mesaj `RoomResponse.messages` listesinden alınır.
Modül içi yüklemelerde VM'ler hatayı `errorMessage`'a yazar — kendi ekranınızda
`@Published errorMessage`'ı dinlemeniz yeterlidir.

---

## İlgili Rehberler

- [WebSocket yapısı](websocket.md) — `ws_url`, `socket_auth`, reconnect
- [TURN & WebRTC](turn-webrtc.md) — credential servisleri
- [Loglama](logging.md) — `sdk_log_api_url` ve online log
