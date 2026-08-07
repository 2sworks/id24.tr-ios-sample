# Identify SDK Sample App
Proje ile ilgili dökümantasyona ve SDK download linkine https://docs.identify.com.tr/docs/ios/first-setup/ adresinden ulaşabilirsiniz.

# Son Güncellemeler

### SDK 2.5.9:
- **Bağlantı canlılığı ölçüme dayalı hale getirildi:** sunucunun PING aralığı çalışma anında ölçülüp tolerans buna göre hesaplanıyor. `pingMissTolerance` (varsayılan 4) ve `connectionSilenceTimeout` (varsayılan 120 sn) ile ayarlanabilir.
- **ICE toparlanma penceresi eklendi:** kısa medya kesintilerinde görüşme sonlandırılmadan önce toparlanma bekleniyor — `iceDisconnectGraceSeconds` (8 sn), `iceFailedGraceSeconds` (12 sn).
- **Görüşme sağlık raporu eklendi:** her görüşme sonunda süre, socket kopma sayısı, ICE kesinti/toparlanma, ağ değişimi ve en uzun sunucu sessizliği tek log olarak sunucuya gönderiliyor. Host aynı veriye `manager.lastCallHealthReport` (`SDKCallHealthReport`) ile erişebilir.
- **Gelen aramada zil sesi ve titreşim eklendi:** sessiz moddayken haptik titreşimle sürüyor. `incomingCallRingtoneEnabled`, `incomingCallVibrationEnabled`, `incomingCallRingtoneInterval` (2.5 sn) ile yönetilir.
- **Çalma penceresi zaman aşımı eklendi:** `ringingTimeout` (varsayılan 300 sn) — yanıtlanmayan çağrı `4108 ringingTimeout` ile kapatılır.
- `disconnectSocket(reason:)` public fonksiyonu eklendi — socket'i kapatmak için **tek** giriş noktası.
- ⚠️ **Entegrasyon notu:** `manager.socket.disconnect()` doğrudan çağrılmamalı; Starscream RFC 6455 `1000 (normal)` yazdığı için sunucu logunda kapanışın gerçek sebebi kayboluyor. Bunun yerine:
  ```swift
  manager.disconnectSocket(reason: .callCompleted)   // 4106 — görüşme tamamlandı
  manager.disconnectSocket(reason: .reconnectCycle)  // 4104 — yeniden bağlanma öncesi
  manager.disconnectSocket(reason: .pingTimeout)     // 4107 — PING zaman aşımı
  ```
  `reason` 4100–4109 aralığında olmalı; dışında bir kod verilirse SDK uyarıp `4104` ile kapatır.
- Yeni kapanış kodları: `4106 callCompleted`, `4107 pingTimeout`, `4108 ringingTimeout`, `4119 authRejected`, `4133 connectTimeout`. Son kapanış `manager.lastSocketCloseCode` ile okunabilir (`rawValue`, `logDescription`, `category`, `isDeliberate`).
- Sinyal hattı koptuğunda WebRTC oturumu tamamen kapatılıp medya susturuluyor; yeniden bağlanma temiz bir oturumla başlıyor.
- Yeniden bağlanma süresi `reconnectTimeoutSeconds` (varsayılan 10 sn) ile ayarlanabilir; sonuçsuz kalan deneme host'a bildiriliyor.
- `subscribe` yanıtsız kalırsa 4 sn arayla 3 kez tekrarlanıyor; sınır aşılırsa host'a "başka oturum açık" bilgisi iletiliyor.
- Yeni read-only property'ler: `isCallActive`, `isRinging`, `lastStatusSummary`.
- `sendStep()` aynı içeriği 3 sn içinde tekrar göndermiyor; `sendStep(force: true)` ile zorlanabilir.
- Minimum dağıtım hedefi iOS 15'e yükseltildi.

### Build 220:
- Gelen arama çalma ekranı yaşam döngüsü SDK zil sesi/titreşim akışıyla eşitlendi.
- Görüntülü görüşme ekranına canlılık kaydı bilgilendirme popup'ı eklendi.
- Bağlantı koptuğunda yeniden bağlanma ekranı her kopmada açılıyor; ARKit oturumu sürüyor ve "Tekrar Bağlan" butonu kilitlenmiyor.
- Uygulama tarafındaki tüm socket kapanışları 4xxx birleşik kodlarla gönderiliyor.
- `selfieWithLiveness`: modül geçişinde tam reset (AR `resetTracking` + deneme sayacı sıfırlama), iki fazlı oval (küçük→büyük), çekim anı flaşı ve mesh gizleme eklendi; oval dışı karartma 0.80'e çıkarıldı.
- SampleApp minimum hedefi iOS 15'e yükseltildi.

### SDK 2.5.6:
- `selfieWithLiveness` modülü eklendi,
- `uploadIdPhoto` fonksiyonuna `withLiveness: Bool = false` parametresi eklendi; `true` gönderildiğinde socket mesajı `uploadSelfieWithLiveness` olarak iletiliyor.
- `sendLivenessReport(metrics:detectedActions:)` yeni public fonksiyon — canlılık ölçümlerini socket üzerinden `liveness_report` action'ıyla gönderiyor.
- Backend'den `liveness_report` ve `liveness_report_interval` alanları okunarak `livenessReportEnabled` ve `livenessReportInterval` property'leri set ediliyor.
- `selfieWithLiveness` modülünde,`selfieComparisonCount` bazlı retry/exit akışı: karşılaştırma başarısız olduğunda sayaca göre yeniden deneme veya çıkış tetikleniyor.
- `WebRTCClient` — liveness için kamera alan/space yönetimi güncellendi, crash fix uygulandı.

### Build 200:
- `SDKSelfieWithLivenessViewController` yeni modül ekranı eklendi (modül akışına dahil, `.xib` destekli).
- `SDKModuleListViewController` — modül listesine `.selfieWithLiveness` eklendi.
- `SDKCallScreenViewController` — görüntülü görüşme başladığında `setupLiveness` / `startLiveness`, bitişte ve bağlantı koptuğunda `stopLiveness` eklendi.

### SDK 2.5.5:
- NFC okuma anahtarları (seri no, doğum tarihi, geçerlilik tarihi) backend'e AES-256-CBC ile şifreli olarak gönderilebilir hale getirildi (`updateReadNFCKeys`).
- OCR'da TCKN doğruluğu artırıldı: harf/rakam karışmaları (örn. O→0, I→1) düzeltilerek Luhn algoritmasıyla kontrol eklendi.
- OCR tarih ayrıştırmasında slash (`/`) ve tire (`-`) karakterleri de nokta olarak normalize edilir hale getirildi.
- OCR sonuçlarına `lowConfidenceFields` ve `rejectedFields` alanları eklendi.
- NFC "Tag response error / no response" hatası için 400ms bekleme + 4 deneme hakkı eklendi.
- BAC anahtarı hesaplandığında doğum tarihi, belge no ve geçerlilik tarihi loga yazılıyor.
- WebSocket bağlantısında 15 saniye timeout eklendi, süre aşımında bağlanamadı logu basılıyor.
- SDK log URL yapılandırmasında çift slash ve hatalı path formatları otomatik temizleniyor.

### Build 180:
- NFC ekranında okuma anahtarları NFC başlatılmadan önce backend'e gönderilerek doğrulanıyor.
- 3 ardışık NFC anahtar hatası sonrasında modül atlanıyor.
- Tarih formatı dönüştürme (`toNFCReadDate`) eklendi.

### SDK 2.5.4:
- iceTransportPolicy relay den .all’a çekildi.
- ⁠Nfc iyileştirmesi yapıldı algılama seviyeleri değiştirildi.
- ⁠SendIdentStatusInfo ile görüntülü görüşme kopması sonrasında durum seçilmemesi halinde bekleme odasına dönmesi eklendi.
- ⁠uploadAddressInfo’da sıkıştırma ayarları güncellendi.
- ⁠socket_auth ile token ile bağlantı sürece dahil edildi artık müşterile ile agent arasında token ile görüntülü görüşme sağlanabiliyor.
- liveStreamModuleController ismi -> callWaitModuleController ismi ile değiştirildi.
- ⁠Socket mesajında gönderilen Live Stream ismi Call Wait Screen ile değiştirildi.

### Build 178:
- ⁠NFC de iyileştirmeler yapıldı.
- ⁠Adress modülünde ki görselinin sunucuya gönderilirken kalitesinin düşmesindeki ayarlar yükseltildi.
- ⁠Bağlantı koptuğunda eğer durum seçilmediyse bekleme odasına yönlendirme geliştirmesi yapıldı via “-3” durum kodu.
-  ⁠liveStreamModuleController ismi -> callWaitModuleController ismi ile değiştirildi.
- ⁠Websocket secret key geliştirilmesi yapıldı isteğe göre artık görüntülü görüşme token ile peer to peer güvenlik seviyesine çıkarıldı.
-  ws token generate token hatası giderildi.


### SDK 2.5.3:
- Sdk log api url eklendi.

### Build 166:
- OVD modülünde iyileştirmeler yapıldı.

### SDK 2.5.2
- Kimlik OCR - Ad Soyad alanında özel karakterlerin algılanması engellendi.

***

## Sample App 

## Build 166:
- OVD modülünde iyileştirmeler yapıldı.

## Build 165:
- Adres fotoğraflarının daha kaliteli gönderilmesi sağlandı.

## Build 162:
- enableDebugPrint eklendi.

## Build 160:
- TURN için şifreli kullanım opsiyonu eklendi.
- Görüntülü görüşme sonlandırma senaryoları için sebep ve durum bilgileri eklendi
- Sunucudan gelen hata mesajlarının gösteriminde düzenlemeler yapıldı
- Kimlik çekim ekranındaki flaş çalışmama hatası düzenlendi
- OVD (beta) ekranı eklendi

## Build 141:
- Kimlik çekimlerinde otomatik yön düzeltme seçeneği eklendi
- Aktif karşılaştırmada modül atlama kontrolü eklendi
- Agent durum seçtiğinde arama butonunun devre dışı bırakılması sağlandı
- OCR, NFC ve Selfie adımlarında tekrar deneme sayısı kontrolleri eklendi

## Build 126:
- Kimlik çekimlerinde yeni cihazlardaki yakınlaştırma modu uyumu sağlandı
- İşaret dili seçimi ekranında görüntülü görüşme kuyruğuna düşmemesi sağlandı
- Agent görüntüsünün dikey ölçüde gösterilebilmesi sağlandı
- Süresi geçmiş ident için hata mesajı gösterimi eklendi
- İlgili ekranlara kamera, mikrofon ve konuşma izni kontrolleri eklendi
- Tekrar Bağlan butonuna internet bağlantısı kontrolü eklendi

## Build 107:
- SDK'i işlemler tamamlanmadan kapatabilme özelliği eklendi
- Müşterinin çağrıyı sonlandırabilmesi eklendi

## Build 106:
- Sunucudan maksimum dosya yükleme boyutunu al

## Build 103:
- Canlılık modülünü kaydetme seçeneği eklendi

## Build 101:
- Adres modülüne PDF yükleme seçeneği eklendi

## Build 100:
- IdentifyTrackingListener kullanımı eklendi (Yalnızca 2.1.0 ve üstü sürümler için geçerli)

## Build 97:
- yeni dil desteği eklendi

## Build 89:
- yeni canlılık testi kodları eklendi
- ssl pinning örnek sertifika eklendi
- privacy info dosyası eklendi

## Build 84:
- scanner ekranında kimliğin yatay olma zorunluluğu iptal edildi
- login ekranı yeni SDK kurulumuna göre düzenlendi
- login ekranında socket hata vermesi durumunda ekstra durum bildirimi eklendi

## Build 80:
- scanner ekranında daha hızlı fotoğraf çekimi sağlandı 
- active result için NfcViewController, CardreaderViewController ve ThankYouViewController buna bağlı olarak güncellendi
- scanner için yatay fotoğraf çekilmesi zorunluluğu eklendi
- dil dosyaları güncellendi

## Build 75:
- Scanner ve onu çağıran ekranlar güncellendi
- Prepare modülü için örnek ekran eklendi
- Missed Call için yeni status eklendi
- Teşekkür ekranı güncellendi

## Build 73:
- prepare modülünün örnek tasarımı eklendi
- socketListener tarafına connectionErr eklendi
- button tiplerine loader eklendi
- socket bağlantısı kopması durumunda çıkan ekran güncellendi



## SDK

## 2.5.2
- Kimlik OCR - Ad Soyad alanında özel karakterlerin algılanması engellendi.

## 2.5.1
- Turn şifrelemeyi destekleme bilgisi backende gönderildi
- enableDebugPrint ile print loglarını açıp kapatabilme opsiyonu eklendi

## 2.5.0
- OCR kimlik ön yüz ve arka yüz iyileştirmeleri yapıldı
- TURN için encryptedTurnCredential ve shortTermUsage parametreleri eklendi
- terminateCall fonksiyonuna terminateReason ve statusSummaryType eklendi
- response messages düzenlemeleri yapıldı
- SDK online log iyileştirmeleri yapıldı

## 2.3.15
- Selfie modülünde sadece tek yüz algılandığında ilerlenmesi sağlandı

## 2.3.14
- disableEndCallButton socket aksiyonu eklendi
- enableAutoRotateOCR sdk parametresi eklendi
- active_comparison_result_skip_module eklendi

## 2.3.9
- appVersion, appBuild, sdkVersion bilgilerinin gönderilmesi sağlandı
- agentViewScale desteği eklendi
- ident_id trim eklendi
- doc_type desteği eklendi

## 2.3.1
- Sunucudan maksimum dosya yükleme boyutunu al

## 2.3.0
- Adres modülüne PDF yükleme seçeneği eklendi
- Canlılık modülüne ekran kaydı desteği eklendiw

## 2.2.0
- IdentifyTrackingListener tarafına HTTP_RESPONSE_TRACKING_EVENT ve HTTP_REQUEST_TRACKING_EVENT eklendi
- Turn sunucu için Short term auth servisi eklendi

## 2.1.0
- SDK tarafında yeni bir IdentifyTrackingListener eklendi, örnek kullanım için SDKBaseViewController dosyasını inceleyebilirsiniz.

## 2.0.6
- Network sınıfında ssl pinning için ekstra log eklendi

## 2.0.5
- yeni dil desteği eklendi

## 2.0.4
- close sdk methodu güncellendi
- endReconnectSubscribe eklendi

## 2.0.3 (Xcode 15.3 sürümü ayrıca eklenmiştir, dökümantasyonu mutlaka kontrol edin)
- network sınıfı güncellendi
- ssl pinning desteği eklendi

## 2.0.2
- ws credential webservisten gelecek hale getirildi, docs güncellendi

## 2.0.1
- active result desteği eklendi
- ocr alanında güncellemeler yapıldı

## 1.9.8
- bağlantı hızına bağlı olarak kamera güncellemesi düzenlendi
- prepare modülünün panele attığı istek eklendi

## 1.9.7
- prepare modülü eklendi
- forceQuitSDK eklendi
- socket disconnect olunca socket listener için method eklendi (.connectionErr)
- ocr tarafında güncelleme yapıldı
