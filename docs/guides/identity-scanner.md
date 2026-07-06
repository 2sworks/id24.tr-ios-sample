# IdentityScanner — Gerçek Zamanlı Belge Tarama Motoru

SDK'nın içindeki kamera tabanlı **belge tarama motoru**. Kimlik ekranında gördüğünüz o akıllı
davranışların hepsi buradan gelir: belge dörtgenini canlı yakalama, alan alan OCR (TCKN,
ad-soyad, doğum tarihi...), MRZ okuma, perspektif düzeltme ve TCKN/MRZ doğrulaması —
**tamamı cihaz üzerinde.**

İki şekilde karşınıza çıkar:

1. **Dolaylı** — [IdCard](../../NewTest/Modules/IdCard/IdCard.md) ve
   [AddressConfirm](../../NewTest/Modules/AddressConfirm/AddressConfirm.md) modüllerinin hazır
   ekranları bu motoru zaten kullanır; hiçbir şey yapmanız gerekmez.
2. **Doğrudan** — `IdentityScannerView`'ı kendi ekranlarınızda **bağımsız bileşen** olarak
   kullanabilirsiniz (KYC akışı dışındaki senaryolar için: form ön-doldurma, belge arşivleme...).

Gereksinim: **iOS 15+**.

← [README'ye dön](../../README.md) · İlgili: [Özelleştirme](customization.md) · [Tema](theming.md)

---

## Kurulum — Tek Satır

Uygulama açılışında profil ve doğrulayıcı kayıtlarını yapın:

```swift
IdentityScanner.setup()   // built-in profiller + TCKN/MRZ doğrulayıcıları kaydedilir
```

## Hızlı Başlangıç

```swift
IdentityScannerView(profile: .turkishIDFront) { result in
    switch result {
    case .success(let doc):
        let tckn = doc.fields["tckn"]?.value          // alan bazlı erişim
        let cropped = doc.croppedImage                 // perspektif düzeltilmiş görsel
        print("Geçerli mi:", doc.isValid)              // TCKN checksum vb. doğrulamalar
    case .failure(let error):
        // ScanningError.cancelled dahil hata durumları
    }
}
```

Kullanıcı belgeyi çerçeveye tutar; motor kareler stabilize olunca **otomatik yakalar**
(gerekirse manuel yakalama butonu belirir), alanları okur, doğrular ve sonucu döndürür.

---

## Hazır Profiller

Profil = "bu belge nasıl taranır" tarifi (strateji + alan bölgeleri + anahtar kelime kapısı):

| Profil | Strateji | Ne yapar |
|---|---|---|
| `.turkishIDFront` | `visionText` | TC kimlik ön yüz: TCKN, soyad, ad, doğum tarihi, belge no — **bölgesel OCR** ile |
| `.turkishIDBack` | `visionText` | TC kimlik arka yüz (MRZ satırları dahil) |
| `.turkishID` | — | Ön/arka birleşik anahtar kelime kümesi |
| `.passport` | `mrzPassport` | Pasaport veri sayfası (TD3 MRZ); dik tutulursa "yana çevirin" yönergesi |
| `.turkishDrivingLicense` | `visionText` | TR ehliyet |
| `.bankCard` | `visionText` | Banka kartı |
| `.a4Document` / `.generic` | `imageOnly` | Serbest belge — alan çıkarmadan düzgün kırpılmış görsel (AddressConfirm bunu kullanır) |

**Anahtar kelime kapısı (keyword gating):** Profildeki `keywordSet`, "TÜRKİYE CUMHURİYETİ /
KİMLİK KARTI" gibi ibareler görünmeden yakalamayı tetiklemez — masadaki rastgele bir dikdörtgen
kimlik sanılmaz.

## Kendi Profiliniz

`DocumentProfile` `Codable`'dır — profili **JSON'dan bile yükleyebilirsiniz** (sunucudan
indirilen profille yeni belge tipi desteği, uygulama güncellemeden):

```swift
let profile = DocumentProfile(
    id: "my.company.badge",
    displayName: "Personel Kartı",
    strategy: .visionText,
    fields: [
        FieldDescriptor(key: "sicilNo",
                        pattern: #"\b[A-Z]{2}\d{6}\b"#,
                        valueType: .number,
                        isRequired: true,
                        regionOfInterest: FieldRegion(x: 0.05, y: 0.60, width: 0.5, height: 0.15))
    ],
    keywordSet: DocumentKeywordSet(keywords: [DocumentKeyword(text: "PERSONEL")])
)
// veya: try DocumentProfile(decoding: jsonData)
```

`FieldRegion` normalize koordinattır (0–1); alan yalnızca belgedeki o bölgede aranır — bu,
hem hızı hem isabeti ciddi artırır.

## Doğrulayıcılar

Kayıtlı doğrulayıcılar sonucu `validationResults`'a işler; `doc.isValid` hepsinin özetidir:

- `TCKNValidator` — TC kimlik numarası checksum kontrolü
- `MRZValidator` — MRZ satır check-digit kontrolü

Kendi kuralınız için `DocumentValidator` protokolünü uygulayın:

```swift
struct AgeValidator: DocumentValidator {
    let key = "birthDate"
    func validate(_ document: inout RecognizedDocument) -> [ValidationResult] {
        // doc.fields["birthDate"] üzerinden 18+ kontrolü...
    }
}
Task { await DocumentValidatorRegistry.shared.register(AgeValidator()) }
```

---

## Sonuç Modeli — `RecognizedDocument`

| Alan | Anlam |
|---|---|
| `croppedImage` | Kırpılmış, perspektifi düzeltilmiş belge görseli |
| `fields` | Alan sözlüğü (`FieldDescriptor.key` → `DocumentField`) |
| `rawText` | Belgeden okunan tüm ham metin |
| `validationResults` | Alan bazlı doğrulama sonuçları |
| `isValid` | Tüm zorunlu doğrulamalar geçti mi |
| `profileID` | Sonucu üreten profil |

## Görünüm ve Davranış Ayarları

`IdentityScannerView`'ın tüm init parametreleri:

| Parametre | Ne işe yarar |
|---|---|
| `profile` | Hangi belge, nasıl taranır (yukarıda) |
| `style: QuadrilateralStyle` | Dörtgen overlay'in görünümü (köşe stili, renkler) |
| `configuration: ScannerConfiguration` | HUD metinleri + zamanlama (aşağıda) |
| `debugROI` | Alan bölgelerini ekranda çizer (geliştirme) |
| `externalTorchOn` | El feneri kontrolünü dışarıdan bağlama (`Binding<Bool>`) |
| `onTorchAvailability` | Cihazda fener var/yok bildirimi |
| `speechKey` / `speechModule` | Açılışta sesli yönerge ([ReadAloud](../../NewTest/Modules/ReadAloud.md) sistemiyle) |
| `onResult` | `Result<RecognizedDocument, Error>` |

### HUD Metinleri ve Zamanlama — `ScannerConfiguration`

Tarayıcının tüm rehber metinleri (`idle`, `focusing`, `reading`, `locked`, `tooClose`,
`align`, `manualCapture`, `orientation`...) aktif SDK diline göre hazır gelir ve tek tek
değiştirilebilir. Üç hazır kompozisyon vardır ve **global override kancaları** sunar:

```swift
ScannerConfiguration.default    // kimlik kartı (override: .overrideDefault)
ScannerConfiguration.passport   // pasaport      (override: .overridePassport)
ScannerConfiguration.document   // serbest belge (override: .overrideDocument)

// Örnek: tüm kimlik taramalarında bekleme metnini değiştir
var cfg = ScannerConfiguration.default
cfg.texts.idle = "Kimliğinizi çerçeveye yerleştirin"
ScannerConfiguration.overrideDefault = cfg
```

`timing` tarafında yakalama hızı, odak davranışı ve manuel yakalama gecikmesi ayarlanır
(`ScannerTimingConfig`).

### Akıllı Davranışlar (kutudan çıkar)

- Belge sensöre çok yaklaşınca **ultra-geniş lense otomatik geçiş** (+ "uzaklaştırın" metni)
- Dokunarak odaklama (sarı odak göstergesi)
- Otomatik yakalama üst üste başarısız olursa **manuel yakalama** teklifi
- Pasaport dik tutulursa **"yana çevirin"** yönlendirmesi
- Işık yetersizse fener önerisi (torch API'siyle)

---

## ⚠️ KYC Akışı İçinde Kullanmayın (Bypass)

Bu motor bağımsız bir bileşendir; ama **KYC akışının kimlik adımını bununla değiştirmeyin.**
`IdentityScannerView`'ı doğrudan kullanıp sonucu kendiniz yüklerseniz `sendStep`/upload
sinyalleri gitmez ve akış sunucuda ilerlemez. Akış içindeyseniz her zaman modül VM'inden
gidin: [IdCard rehberi](../../NewTest/Modules/IdCard/IdCard.md) —
`vm.scanFront(image:)` zaten bu motoru perde arkasında kullanır.

Doğrudan kullanım, **akış dışı** senaryolar içindir: müşteri kaydında form ön-doldurma,
belge arşivleme, şube içi araçlar...
