# Lokalizasyon — Dil Desteği ve Metin Override

SDK beş dilde hazır gelir: **Türkçe, İngilizce, Almanca, Azerbaycanca, Rusça.**
Tüm ekran metinleri anahtar tabanlıdır (`SDKKeyword`) ve her biri host tarafından
tek tek ezilebilir — kendi üslubunuzu SDK ekranlarına taşıyabilirsiniz.

← [README'ye dön](../../README.md) · İlgili: [Tema](theming.md) · [ReadAloud](../../NewTest/Modules/ReadAloud.md)

---

## Dil Seçimi

Aktif dili `IdentifyManager` üzerinden ayarlarsınız (varsayılan: Türkçe; bilinmeyen durumda
İngilizce'ye düşer):

```swift
IdentifyManager.shared.sdkLang = .eng    // .tr / .eng / .de / .az / .ru
```

| `SDKLang` | Dil | STT kodu |
|---|---|---|
| `.tr` | Türkçe | `tr` |
| `.eng` | İngilizce | `en` |
| `.de` | Almanca | `de` |
| `.az` | Azerbaycanca | `az` |
| `.ru` | Rusça | `ru` |

Dil seçimi yalnızca ekran metinlerini değil, **konuşma tanıma** (Speech modülü) ve
**sesli okuma** (Read-Aloud) dillerini de belirler.

> OCR için ayrı bir ipucu vardır: `setupSDK(idCardLang:)` — belge üzerindeki yazının dili.

---

## Metinleri Okumak

SDK içi tüm metinler `SDKKeyword` enum'ıyla çözülür. Kendi custom ekranınızda SDK ile aynı
metni göstermek isterseniz:

```swift
let title = SDKLocalization.shared.translate(.connect)
```

---

## Metinleri Ezmek (Override)

Üç yol vardır; hepsi çalışma zamanında, `setupSDK`'dan önce uygulanır:

### 1. Tek metin

```swift
SDKLocalization.shared.setOverride(key: .connect, language: .tr, value: "Bağlan")
```

### 2. Toplu sözlük

```swift
SDKLocalization.shared.registerOverrides([
    .tr: ["connect": "Bağlan", "selfie_info": "Yüzünüzü çerçeveye alın"],
    .eng: ["connect": "Connect"]
])
```

### 3. Dosyadan yükleme

Metinleri uygulamanıza bir kaynak dosyası olarak koyup tek seferde yükleyin —
sunucudan indirilen bir dosyayla **uygulama güncellemeden metin değiştirme** de mümkündür:

```swift
if let url = Bundle.main.url(forResource: "sdk_texts_tr", withExtension: "json") {
    SDKLocalization.shared.loadOverrides(from: url, language: .tr)
}
```

Temizlik: `clearOverrides()` tüm ezmeleri kaldırır, `clearCache()` çeviri önbelleğini tazeler.

---

## Sesli Okuma Metinleri

Modül yönergelerinin seslendirilen halleri de aynı sistemden geçer — her modülün bir
`*Tts` anahtarı vardır (ör. `.selfieTts`). Sesli metni ekran metninden bağımsız
değiştirebilirsiniz:

```swift
SDKLocalization.shared.setOverride(
    key: .selfieTts, language: .tr,
    value: "Lütfen yüzünüzü ekrandaki çerçeveye hizalayın."
)
```

Ayrıntı: [ReadAloud rehberi](../../NewTest/Modules/ReadAloud.md).

---

## İpuçları

- Override anahtarları `SDKKeyword.rawValue` üzerinden eşleşir; mevcut anahtarların tam
  listesi için SDK'daki `SDKKeyword` enum'ına (400+ anahtar) bakın ya da bir metnin
  anahtarını ilgili modülün rehberinden bulun.
- Dil değiştirme butonu SDK'nın nav bar'ında hazırdır (`langButton` ikonu) — kendi dil
  seçiminizi kullanıyorsanız `sdkLang`'i güncellemeniz yeterlidir.
