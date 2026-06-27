# IdentifySDK — React Native Entegrasyonu

Bu rehber, `IdentifySDK` (iOS KYC kimlik doğrulama SDK'sı) için bir **React Native köprü
modülü** kurmayı ve SDK'nın **birleşik olay akışını** (SDKEvent) JS tarafında dinlemeyi
anlatır. Köprü iskeleti bu klasördedir; kopyalayıp projenize uyarlayabilirsiniz.

> SDK yalnızca iOS'tur. Bu köprü iOS native tarafını sarar; Android için ayrı bir SDK
> gerekir (bu pakette yoktur).

---

## 1) Kurulum

`IdentifySDK` bir XCFramework olup Swift Package Manager ile dağıtılır.

### Swift Package Manager (önerilen)
React Native projenizin iOS `Podfile`'ı varsa bile SDK'yı SPM ile ekleyebilirsiniz:
Xcode → **File → Add Packages** →

```
https://github.com/2sworks/id24.tr-ios-sdk-spm
```

Bu paket runtime bağımlılıklarını da getirir: OpenSSL, Starscream, WebRTC,
SwiftSignatureView, PermissionsKit.

### CocoaPods (alternatif)
`ios/Podfile` içine binary framework'ü ve bağımlılıklarını ekleyin, ardından:

```bash
cd ios && pod install
```

`Info.plist` izinleri (kamera/NFC/mikrofon) gereklidir:

```xml
<key>NSCameraUsageDescription</key><string>Kimlik doğrulama için kamera</string>
<key>NSMicrophoneUsageDescription</key><string>Görüntülü görüşme için mikrofon</string>
<key>NFCReaderUsageDescription</key><string>Kimlik/pasaport çipi okuma</string>
```
NFC için ayrıca `*.entitlements` dosyasına `com.apple.developer.nfc.readersession.formats`.

---

## 2) Native köprü dosyaları

Bu klasördeki dosyaları `ios/` altına kopyalayın:

| Dosya | Görev |
|---|---|
| `IdentifySdkModule.swift` | `RCTEventEmitter` köprüsü: `setupSDK` + olay yayını |
| `IdentifySdkModule.m`     | Obj-C `RCT_EXTERN_MODULE` köprü kaydı |
| `IdentifySdk.ts`          | JS/TS sarmalayıcı + tip tanımlı `SDKEvent` |

`AppDelegate` köprü başlığına (`<App>-Bridging-Header.h`) ekleyin:

```objc
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
```

---

## 3) Kullanım (JS/TS)

```ts
import { IdentifySdk, SDKEvent } from './IdentifySdk';

// 1) Olay akışına abone ol — SDK'nın "nerede ne yaptığını" tek akıştan al
const sub = IdentifySdk.addEventListener((event: SDKEvent) => {
  console.log(event.name, event.category, event.status, event.screen);

  switch (event.name) {
    case 'session.started':   /* oturum başladı */ break;
    case 'session.completed': /* başarıyla kapandı (event.status === 'success') */ break;
    case 'session.failed':    /* başarısız (event.metadata.reason) */ break;
    case 'session.abandoned': /* kullanıcı terk etti (event.metadata.lastScreen) */ break;
  }
});

// 2) SDK'yı başlat
await IdentifySdk.setupSDK({
  identId: 'XXXX-XXXX',
  baseApiUrl: 'https://api.example.com/',
  turnKey: 'turn-secret',
  signLangSupport: false,
  nfcMaxErrorCount: 3,
  selectedModules: [],          // boş = backend'in döndürdüğü sıra
  showThankYouPage: true,
});

// 3) Temizlik
sub.remove();
```

---

## 4) Olay (SDKEvent) yapısı

Köprü, native `SDKEvent.toDictionary()` çıktısını **olduğu gibi** JS'e iletir:

```ts
interface SDKEvent {
  name: string;        // "session.started", "module.Selfie.completed", "call.ended"
  category: 'session' | 'module' | 'call' | 'network' | 'error' | 'navigation';
  status: 'info' | 'presented' | 'completed' | 'failed'
        | 'skipped' | 'success' | 'abandoned' | 'notFound';
  module?: string;     // "Selfie", "Mrz & Nfc Screen" ...
  screen?: string;     // kullanıcının o anki/son ekranı
  sessionId: string;
  timestampMs: number;
  message?: string;
  metadata: Record<string, string>;  // reason, statusSummary, lastScreen ...
}
```

### SDK nerede ne yapıyor — olay akış tablosu

| Olay adı | Kategori | Ne zaman | Anlam |
|---|---|---|---|
| `session.started` | session | `setupSDK` | Oturum başladı |
| `module.<Modül>.presented` | module | Ekran açıldığında | Kullanıcı o ekranda (lastScreen güncellenir) |
| `module.<Modül>.completed` | module | Modül bitince | Adım başarıyla tamamlandı |
| `module.<Modül>.failed` | module | Modül hata | Adım başarısız |
| `module.<Modül>.skipped` | module | Atlanınca | Adım atlandı |
| `call.connected` | call | Çağrı başlayınca | Temsilciyle görüşme başladı |
| `call.ended` | call | Çağrı bitince | Görüşme bitti (metadata.statusSummary) |
| `session.completed` | session | Onay | Oturum **başarıyla** kapandı (status `success`) |
| `session.failed` | session | Ret | Oturum **başarısız** kapandı |
| `session.abandoned` | session | Terk/kapatma | Kullanıcı yarıda bıraktı (metadata.lastScreen = nerede kaldı) |

> **Geriye uyumluluk:** Bu birleşik akış, SDK'nın mevcut `IdentifyTrackingListener`
> mekanizmasının **yanına** eklenmiştir; mevcut entegrasyonları bozmaz.
