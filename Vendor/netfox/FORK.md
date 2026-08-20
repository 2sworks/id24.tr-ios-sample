# netfox forku (yerel)

Kaynak: https://github.com/kasketis/netfox — `5575760` (v1.21.0 etiketiyle aynı commit).
Uzak SPM bağımlılığı yerine bu yerel paket kullanılır.

## Neden fork

netfox yalnızca `URLSession` trafiğini gösterir. Bu projede üç ayrı log kaynağı var
(HTTP, Starscream WebSocket, `print`/`sdkLog` çıktısı) ve hepsi tek panelde
görülmek isteniyor. Upstream 1.21.0'da durgun olduğu için fork bakım riski düşük.

## Upstream'e göre farklar

- `Package.swift`: iOS 14 minimum, OS X hedefi ve demo/asset dizinleri çıkarıldı.
- `Core/NFXLogStore.swift` *(yeni)*: konsol satırları için thread-safe halka arabellek.
- `Core/NFXStdoutCapture.swift` *(yeni)*: `dup2` ile stdout/stderr yakalama;
  satırlar orijinal fd'ye geri yazılır, Xcode konsolu bozulmaz.
- `Core/NFXExternalLog.swift` *(yeni)*: host uygulamanın WebSocket gibi kendi log
  kaynaklarını panele bağlaması için sağlayıcı arayüzü.
- `iOS/NFXConsoleController_iOS.swift` *(yeni)*: canlı konsol sekmesi.
- `iOS/NFXExternalLogController_iOS.swift` *(yeni)*: harici kaynak sekmesi.
- `Core/NFXLogRedactor.swift` *(yeni)*: panelde gösterilen satırlarda paket kimliği,
  paket yolu, mutlak dosya yolları, bellek adresleri ve uzun base64 blokları kısaltılır.
  Xcode konsoluna aynalanan çıktı ve sunucuya giden log ham kalır.
- `Core/NFXLogExporter.swift` *(yeni)*: kayıtları CSV / JSON / düz metin dosyası olarak
  geçici dizine yazar; paylaşım sayfası dosyayla açılır. Üç sekme de kullanır.
- `iOS/NFXListController_iOS.swift`: liste ekranına toplu dışa aktarma butonu eklendi
  (upstream'de yalnız tek istek detayında paylaşım vardı).
- `Core/NFX.swift`: sunum `UINavigationController` yerine `UITabBarController`;
  `startConsoleCapture()`, `log(_:)`, `externalLogSource`, `isRequestsTabEnabled`,
  `isConsoleTabEnabled`, `isExternalTabEnabled` public yüzeyi eklendi. HTTP sekmesi
  kapalıyken `URLSession` swizzle'ı hiç kurulmaz.

Upstream'den güncelleme alınırsa yukarıdaki dosyalar korunmalı, `NFX.swift`
değişiklikleri elle taşınmalıdır.
