# Sürüm Geçmişi

Bu dosya, **IdentifySDK** ve **Sample App** sürüm notlarını içerir.
Güncel kurulum ve dökümantasyon için [README](README.md)'ye dönebilirsiniz.

---

## IdentifySDK

### 2.5.4
- `iceTransportPolicy` relay'den `.all`'a çekildi.
- `sdkLogApiUrl` hatası giderildi.
- NFC iyileştirmesi yapıldı; algılama seviyeleri değiştirilip stabilizasyon sağlandı.
- `SendIdentStatusInfo` ile görüntülü görüşme kopması esnasında sunucudan gönderilen verinin tanımlanması sağlandı.
- `uploadAddressInfo`'da sıkıştırma ayarları güncellendi.
- `socket_auth` ile token'lı bağlantı sürece dahil edildi; artık müşteri ile agent arasında token ile görüntülü görüşme sağlanabiliyor.
- `liveStreamModuleController` ismi `callWaitModuleController` olarak değiştirildi.
- Socket mesajında gönderilen "Live Stream" ismi "Call Wait Screen" ile değiştirildi.

### 2.5.3
- SDK log API URL eklendi.

### 2.5.2
- Kimlik OCR — Ad Soyad alanında özel karakterlerin algılanması engellendi.

### 2.5.1
- TURN şifrelemeyi destekleme bilgisi backend'e gönderildi.
- `enableDebugPrint` ile print loglarını açıp kapatabilme opsiyonu eklendi.

### 2.5.0
- OCR kimlik ön yüz ve arka yüz iyileştirmeleri yapıldı.
- TURN için `encryptedTurnCredential` ve `shortTermUsage` parametreleri eklendi.
- `terminateCall` fonksiyonuna `terminateReason` ve `statusSummaryType` eklendi.
- Response messages düzenlemeleri yapıldı.
- SDK online log iyileştirmeleri yapıldı.

### 2.3.15
- Selfie modülünde sadece tek yüz algılandığında ilerlenmesi sağlandı.

### 2.3.14
- `disableEndCallButton` socket aksiyonu eklendi.
- `enableAutoRotateOCR` SDK parametresi eklendi.
- `active_comparison_result_skip_module` eklendi.

### 2.3.9
- `appVersion`, `appBuild`, `sdkVersion` bilgilerinin gönderilmesi sağlandı.
- `agentViewScale` desteği eklendi.
- `ident_id` trim eklendi.
- `doc_type` desteği eklendi.

### 2.3.1
- Sunucudan maksimum dosya yükleme boyutunu alma eklendi.

### 2.3.0
- Adres modülüne PDF yükleme seçeneği eklendi.
- Canlılık modülüne ekran kaydı desteği eklendi.

### 2.2.0
- `IdentifyTrackingListener` tarafına `HTTP_RESPONSE_TRACKING_EVENT` ve `HTTP_REQUEST_TRACKING_EVENT` eklendi.
- TURN sunucu için short-term auth servisi eklendi.

### 2.1.0
- SDK tarafına yeni bir `IdentifyTrackingListener` eklendi; örnek kullanım için `SDKBaseViewController` dosyasını inceleyebilirsiniz.

### 2.0.6
- Network sınıfında SSL pinning için ekstra log eklendi.

### 2.0.5
- Yeni dil desteği eklendi.

### 2.0.4
- `closeSDK` metodu güncellendi.
- `endReconnectSubscribe` eklendi.

### 2.0.3
> Xcode 15.3 sürümü ayrıca eklenmiştir, dökümantasyonu mutlaka kontrol edin.
- Network sınıfı güncellendi.
- SSL pinning desteği eklendi.

### 2.0.2
- WS credential web servisten gelecek hale getirildi, dökümanlar güncellendi.

### 2.0.1
- Active result desteği eklendi.
- OCR alanında güncellemeler yapıldı.

### 1.9.8
- Bağlantı hızına bağlı olarak kamera güncellemesi düzenlendi.
- Prepare modülünün panele attığı istek eklendi.

### 1.9.7
- Prepare modülü eklendi.
- `forceQuitSDK` eklendi.
- Socket disconnect olunca socket listener için metot eklendi (`.connectionErr`).
- OCR tarafında güncelleme yapıldı.

---

## Sample App

### Build 178
- NFC'de iyileştirmeler yapıldı.
- Adres modülündeki görselin sunucuya gönderilirken kalitesinin düşmesine sebep olan ayarlar yükseltildi.
- Bağlantı koptuğunda durum seçilmediyse bekleme odasına yönlendirme geliştirmesi yapıldı ("-3" durum kodu ile).
- `liveStreamModuleController` ismi `callWaitModuleController` olarak değiştirildi.
- WebSocket secret key geliştirmesi yapıldı; isteğe göre görüntülü görüşme token ile peer-to-peer güvenlik seviyesine çıkarıldı.
- WS token generate hatası giderildi.

### Build 166
- OVD modülünde iyileştirmeler yapıldı.

### Build 165
- Adres fotoğraflarının daha kaliteli gönderilmesi sağlandı.

### Build 162
- `enableDebugPrint` eklendi.

### Build 160
- TURN için şifreli kullanım opsiyonu eklendi.
- Görüntülü görüşme sonlandırma senaryoları için sebep ve durum bilgileri eklendi.
- Sunucudan gelen hata mesajlarının gösteriminde düzenlemeler yapıldı.
- Kimlik çekim ekranındaki flaş çalışmama hatası düzeltildi.
- OVD (beta) ekranı eklendi.

### Build 141
- Kimlik çekimlerinde otomatik yön düzeltme seçeneği eklendi.
- Aktif karşılaştırmada modül atlama kontrolü eklendi.
- Agent durum seçtiğinde arama butonunun devre dışı bırakılması sağlandı.
- OCR, NFC ve Selfie adımlarında tekrar deneme sayısı kontrolleri eklendi.

### Build 126
- Kimlik çekimlerinde yeni cihazlardaki yakınlaştırma modu uyumu sağlandı.
- İşaret dili seçimi ekranında görüntülü görüşme kuyruğuna düşmemesi sağlandı.
- Agent görüntüsünün dikey ölçüde gösterilebilmesi sağlandı.
- Süresi geçmiş ident için hata mesajı gösterimi eklendi.
- İlgili ekranlara kamera, mikrofon ve konuşma izni kontrolleri eklendi.
- "Tekrar Bağlan" butonuna internet bağlantısı kontrolü eklendi.

### Build 107
- SDK'yı işlemler tamamlanmadan kapatabilme özelliği eklendi.
- Müşterinin çağrıyı sonlandırabilmesi eklendi.

### Build 106
- Sunucudan maksimum dosya yükleme boyutunu alma eklendi.

### Build 103
- Canlılık modülünü kaydetme seçeneği eklendi.

### Build 101
- Adres modülüne PDF yükleme seçeneği eklendi.

### Build 100
- `IdentifyTrackingListener` kullanımı eklendi (yalnızca 2.1.0 ve üstü sürümler için geçerli).

### Build 97
- Yeni dil desteği eklendi.

### Build 89
- Yeni canlılık testi kodları eklendi.
- SSL pinning örnek sertifikası eklendi.
- Privacy info dosyası eklendi.

### Build 84
- Scanner ekranında kimliğin yatay olma zorunluluğu iptal edildi.
- Login ekranı yeni SDK kurulumuna göre düzenlendi.
- Login ekranında socket hata vermesi durumunda ekstra durum bildirimi eklendi.

### Build 80
- Scanner ekranında daha hızlı fotoğraf çekimi sağlandı.
- Active result için `NfcViewController`, `CardreaderViewController` ve `ThankYouViewController` güncellendi.
- Scanner için yatay fotoğraf çekilmesi zorunluluğu eklendi.
- Dil dosyaları güncellendi.

### Build 75
- Scanner ve onu çağıran ekranlar güncellendi.
- Prepare modülü için örnek ekran eklendi.
- Missed Call için yeni status eklendi.
- Teşekkür ekranı güncellendi.

### Build 73
- Prepare modülünün örnek tasarımı eklendi.
- `socketListener` tarafına `connectionErr` eklendi.
- Buton tiplerine loader eklendi.
- Socket bağlantısı kopması durumunda çıkan ekran güncellendi.
