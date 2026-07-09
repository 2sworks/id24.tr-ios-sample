# Özelleştirme — SDK Ekranlarını Kendi Tasarımınızla Çalıştırmak

SDK'nın her modül ekranı **drop-in**'dir: hiçbir şey yazmadan hazır akış çalışır. Ama hiçbir
banka aynı görünmek istemez. Bu rehber, üç özelleştirme yöntemini derinlemesine anlatır ve
hepsinin üstündeki tek altın kuralı açıklar: **"bypass yok."**

← [README'ye dön](../../README.md) · İlgili: [Mimari](architecture.md) · [Tema](theming.md)

---

## Önce Kendinize Sorun: Hangi Seviye?

| İhtiyaç | Çözüm | Efor |
|---|---|---|
| "Renkler/font/logo bizim olsun" | [Tema](theming.md) — ekran yazmadan | ⭐ |
| "Şu ekranın tasarımı tamamen bizim olsun" | **A) Override** (bu rehber) | ⭐⭐ |
| "Akışın arasına kendi ekranımı sokayım" | **B) Custom ekran ekleme** | ⭐⭐ |
| "SDK ekranı kalsın ama olup biteni izleyeyim" | **C) Host VM composition** | ⭐ |

Yöntemler birbirini dışlamaz — aynı projede üçünü birden kullanabilirsiniz.

---

## A) Tam Ekran Override

Bir SDK ekranını kendi SwiftUI view'ınızla değiştirirsiniz:

```swift
registry.override(.selfie) { MyCustomSelfieView() }
```

Artık `SDKFlowHostView`, selfie rotası geldiğinde sizin ekranınızı çizer. Kritik nokta:
**UI sizin, iş mantığı SDK'nın.** Ekranınız SDK ViewModel'ini kullanmaya devam eder:

```swift
struct MyCustomSelfieView: View {
    @EnvironmentObject var coordinator: SDKFlowCoordinator
    @StateObject private var vm = SDKSelfieViewModel()

    var body: some View {
        VStack {
            MyBrandedCameraView { captured in
                vm.processSelfie(image: captured)    // ✅ yüz tespiti + upload SDK'da
            }
            if let err = vm.errorMessage { Text(err) }
            Button("Devam") { coordinator.advanceToNextModule() }  // ✅ adım sinyali SDK'da
                .disabled(!vm.canContinue)
        }
        .onAppear { vm.onSkipRequested = { coordinator.skipCurrentModule() } }
    }
}
```

Her modülün VM API'si (state / metotlar / closure'lar) kendi rehberinde tablo halinde
verilir — [Modül Kataloğu](../../README.md#modül-kataloğu)ndan ilgili modüle gidin.

---

## B) Araya Custom Ekran Ekleme

Akışa kendi ekranlarınızı sokarsınız — hoş geldin, sözleşme onayı, ara başarı ekranı...

```swift
// 1) Ekranı tanımla
registry.custom("welcome") { MyIntroView() }

// 2) Nereye geleceğini söyle
coordinator.insert(["welcome"], before: .selfie)     // Selfie'den önce
coordinator.insert(["success1"], after: .idCard)     // Kimlikten sonra

// 3) Custom ekranın "Devam" butonu:
Button("Devam") { coordinator.advanceExternal() }
```

Anlık gösterim de mümkündür (akış sırasını değiştirmeden):

```swift
coordinator.showExternalScreen("kvkk")   // dönüşte yine advanceExternal()
```

Bu ekranlar **pasiftir**: backend'in modül sayacını (`moduleStepOrder`) etkilemez, soketle
konuşmaz. Bu yüzden istediğiniz kadar ekleyebilirsiniz — soket ve WebRTC
`IdentifyManager` singleton'ında yaşadığı için araya giren ekranlar bağlantıyı etkilemez.

Birden fazla ekranı aynı noktaya zincirleyebilirsiniz — dizi sırası gösterim sırasıdır,
aynı rotaya ikinci `insert` çağrısı kuyruğun sonuna ekler (ezmez):

```swift
coordinator.insert(["intro1", "intro2"], before: .nfc)   // intro1 → intro2 → NFC
```

**Ekran değil MODÜL eklemek istiyorsanız** (dallanan senaryolar — bir adımın sonucuna
göre akışın uzaması), `appendModules` kullanın; eklenenler kalan modüllerin sonuna gider
ve ilerleme şeridi (`progressTotal`) otomatik güncellenir:

```swift
coordinator.appendModules([.idCard, .waitScreen])
coordinator.advanceToNextModule()
```

---

## C) Host VM Composition — Gözlemleyerek Zenginleştirme

SDK ekranını değiştirmek istemiyorsanız ama olup biteni izlemek (log, analitik, kendi
state'iniz) istiyorsanız, SDK VM'ini kendi VM'inizle **sarın**:

```swift
@MainActor
final class SelfieHostViewModel: HostModuleViewModel {
    let sdk = SDKSelfieViewModel()

    override init() {
        super.init()
        bridge(sdk)                                    // child'ın objectWillChange'ini yukarı ilet
        sdk.onSkipRequested = { [weak self] in self?.log("selfie_skip") }
    }

    var canContinue: Bool { sdk.canContinue }          // state'i dışarı aç

    func process(_ img: UIImage) {
        log("selfie_scan")                             // sizin tarafınız
        sdk.processSelfie(image: img)                  // işi SDK yapar
    }
}
```

> **Tasarım kararı:** Modül VM'leri `public final`'dır — subclass'lanamaz. Davranış ezmek
> yerine sarmalayıp gözlemlersiniz. Bu bilinçli bir tercihtir: dış geliştiricinin iş mantığını
> değiştirmesi, sunucu tarafı akışla uyumsuzluk yaratır.

Sample App'te her modülün `XxxHostViewModel`'i bu desenin çalışan örneğidir.

---

## "Bypass Yok" Kuralı

Custom ekran yazarken her adım eylemini — **tara, yükle, sonraki modüle geç** —
**SDK VM metoduna indirmelisiniz.** Nedeni basit: her VM metodu, işin yanında backend'e
ilerleme sinyali de gönderir (`sendStep`, `modulePresented`). Kendi HTTP isteğinizi atar,
kendi navigasyonunuzu kurarsanız görüntü aynı olur ama **sunucu akışı ilerlemez** —
agent panelinde müşteri "takılı" görünür.

| ✅ Doğru | ❌ Bypass |
|---|---|
| `vm.scanFront(image:)` → OCR + upload + adım sinyali | Kendi OCR'ınız + kendi `POST`'unuz |
| `coordinator.advanceToNextModule()` | `path.append(...)` ile kendi geçişiniz |
| `vm.uploadSignature(image:)` | Görseli kendiniz yüklemek |
| `coordinator.skipCurrentModule()` | Modülü sessizce atlamak |

Pasif ekranlar (B yöntemi) bu kuralın dışındadır — zaten hiçbir VM metodu çağırmazlar.

---

## Kontrol Listesi — Custom Ekran Yayına Çıkmadan Önce

- [ ] Ekran, iş eylemlerinde yalnızca SDK VM metotlarını çağırıyor
- [ ] Geçişler `coordinator` üzerinden (`advanceToNextModule` / `advanceExternal` / `skipCurrentModule`)
- [ ] `vm.errorMessage` ve `vm.isLoading` kullanıcıya yansıtılıyor
- [ ] Modülün closure'ları bağlandı (`onSkipRequested` vb. — modül rehberine bakın)
- [ ] Deneme hakkı tükenme senaryosu test edildi (comparison count'lar sunucudan gelir)
- [ ] Gerçek cihazda uçtan uca akış koşturuldu (NFC/görüşme simülatörde çalışmaz)
