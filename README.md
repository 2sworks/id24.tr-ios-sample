# Identify SDK Sample App
Proje ile ilgili dökümantasyona ve SDK download linkine https://docs.identify.com.tr/docs/ios/first-setup/ adresinden ulaşabilirsiniz.

### Sample App 

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



### SDK Son Güncelleme:

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
