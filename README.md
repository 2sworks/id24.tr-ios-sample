# Identify SDK Sample App
Proje ile ilgili dökümantasyona ve SDK download linkine https://docs.identify.com.tr/docs/ios/first-setup/ adresinden ulaşabilirsiniz.

# Son Güncellemeler

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
