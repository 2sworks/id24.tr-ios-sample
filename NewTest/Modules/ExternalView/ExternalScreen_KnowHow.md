# ExternalScreen Know-How
> SDK modülleri arasına özel ekran ekleme rehberi

---

## Nasıl Çalışır?

SDK bir `moduleStepOrder` sayacıyla hangi modülün sırada olduğunu takip eder.  
ExternalView push edilirken bu sayaç **değişmez** — sadece `advanceToNextModule()` çağrısı artırır.

```
showExternalScreen()     →  push(.externalScreen)   [sayaç: 1, değişmez]
ExternalView "Devam Et"  →  advanceToNextModule()   [sayaç: 1 → 2, push(.selfie)]
```

UIKit karşılığı: `isExternalScreen = true` → `didMove(toParent:)` sayacı değiştirmez.  
SwiftUI'da `didMove` hiç çalışmaz, mekanizma zaten implicit.

---

## Kullanım

### 1. Herhangi bir modülden tetikle
```swift
// advanceToNextModule() yerine:
appState.showExternalScreen(
    title: "Onay Gerekli",
    subtitle: "Devam etmek için formu onaylayın.",
    icon: "doc.text.fill"
)
```

### 2. ExternalView "Devam Et" sıradaki SDK modülüne geçer
```swift
// ExternalViewModel.proceed() — zaten hazır
appState.advanceToNextModule()
```

---

## Yapılmaması Gerekenler

**`advanceToNextModule()` / `getNextModule()` ExternalView push edilmeden önce çağırma.**
Sayaç artar, bir modül atlanır.

**Aynı butona iki kez basmayı önlememe.**
Butonu tıklandıktan sonra disable etmezsen `advanceToNextModule()` iki kez tetiklenir, yine modül atlanır.

**UIKit'te `isExternalScreen = true` unutma.**
Bu olmadan geri tuşu bile sayacı bozar.

**ExternalView'ı `modulesControllersArray`'e eklemeye çalışma.**
Bu array yalnızca SDK'nın kendi modüllerine ayrılmıştır.

**Socket bağlantısı kopmadan devam ettirme.**
"Devam Et" öncesinde bağlantı kontrolü yapılmazsa sonraki modül sessizce hata verir.
`manager.socket.isConnected` kontrolü yeterli.

---

## Modül Sırası Nereden Gelir?

Backend `FirstRoom.modules` alanından → `["prepare", "idCard", "selfie", "nfc"]`  
`setupSDK(selectedModules:)` ile de override edilebilir.

---

## Nasıl Çalışır?

SDK bir `moduleStepOrder` sayacıyla hangi modülün sırada olduğunu takip eder.
ExternalView push edilirken bu sayaç **değişmez** — sadece `advanceToNextModule()` artırır.

```
showExternalScreen()     →  push(.externalScreen)   [sayaç: 1, değişmez]
ExternalView "Devam Et"  →  advanceToNextModule()   [sayaç: 1→2, push(.selfie)]
```

UIKit karşılığı: `isExternalScreen = true` → `didMove(toParent:)` sayacı değiştirmez.
SwiftUI'da `didMove` hiç çalışmaz, mekanizma zaten implicit.

---

## Kullanım

```swift
// Herhangi bir modülden
appState.showExternalScreen(
    title: "Onay Gerekli",
    subtitle: "Devam etmek için formu onaylayın.",
    icon: "doc.text.fill"
)
```

---

## Olası Sorunlar ve Çözümleri

### 1. Socket kopması (en kritik)

**Ne olur?**
Kullanıcı ExternalView'da beklerken WebSocket bağlantısı koparsa, "Devam Et"e basıldığında
`advanceToNextModule()` lokal array'den modülü okur ve push eder — görünürde bir sorun yok.
Ama sonraki modülde fotoğraf upload, panel mesajı gibi socket gerektiren işlemler **sessizce başarısız olur**.

---

### 2. Çift tıklama (double tap)

**Ne olur?**
Kullanıcı "Devam Et"e hızlıca iki kez basarsa `advanceToNextModule()` iki kez çağrılır.
`moduleStepOrder` iki artarsa bir modül **atlanır**.

---

### 3. Geri tuşu

**SwiftUI:** coordinator path'ten `.externalScreen` çıkar, önceki view'a döner, sayaç değişmez. Güvenli.

---

### 4. App arka plana alınma

**Ne olur?**
App arka plana gidince SDK socket'i belirli süre sonra kapatır (iOS'un background kısıtlamaları).
Ön plana dönüldüğünde `manager.socket.isConnected` false olabilir.

---

### 5. Session timeout (uzun bekleme)

**Ne olur?**
Kullanıcı ExternalView'da çok uzun beklerse backend session'ı kapatabilir.
"Devam Et"e basınca socket mesajları backend tarafından reddedilebilir.

**Belirti:** `wrongSocketActionErr` veya hiç yanıt gelmemesi.

**Çözüm:** `AppStateViewModel.sdkError` yayınlandığında kullanıcıya akışı baştan başlatma seçeneği sun.
Mevcut `resetFlow()` metodu tam olarak bunun için var.

---

## Yeni Özel Ekran Eklemek İstersen

1. `IdentifyNavigationFlow`'a yeni case ekle
2. `AppNavigationCoordinator.screenFor()`'a view'ı bağla
3. `AppStateViewModel`'e helper metod ekle
4. İstediğin modülden çağır
