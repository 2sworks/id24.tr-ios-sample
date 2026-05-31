# CLAUDE.md — id24.tr iOS Sample

## Figma Entegrasyonu

### Token Konumu
Figma token `~/.claude/settings.json` içinde `env.FIGMA_ACCESS_TOKEN` anahtarında saklanmaktadır.

### Figma'dan Tasarım Verisi Çekme

Kullanıcı bir Figma linki paylaştığında, aşağıdaki curl komutuyla tasarım verisini çek ve Swift/SwiftUI koduna uygula:

```bash
# File key ve node ID'yi linkten çıkar:
# https://www.figma.com/design/{FILE_KEY}/...?node-id={NODE_ID}
# NODE_ID'deki "-" yerine ":" kullan (örn: 82-4150 → 82:4150)

FIGMA_TOKEN=$(python3 -c "import json; d=json.load(open('/Users/ayhanhakantekin/.claude/settings.json')); print(d['env']['FIGMA_ACCESS_TOKEN'])")
FILE_KEY="ie0xPbYDYeglvKZYcKw8f1"
NODE_IDS="82:4150,82:5425"  # virgülle birden fazla node

curl -s -H "X-Figma-Token: $FIGMA_TOKEN" \
  "https://api.figma.com/v1/files/$FILE_KEY/nodes?ids=$NODE_IDS&depth=5" \
  -o /tmp/figma_data.json
```

### Veri İşleme (Python)

```python
import json

data = json.load(open('/tmp/figma_data.json'))
nodes = data.get('nodes', {})

def extract_design(node, indent=0):
    t = node.get('type', '')
    name = node.get('name', '')
    chars = node.get('characters', '')
    fills = node.get('fills', [])
    size = node.get('absoluteBoundingBox', {})
    style = node.get('style', {})

    # Renk
    color_str = ''
    if fills:
        f = fills[0]
        if f.get('type') == 'SOLID':
            c = f.get('color', {})
            r, g, b = int(c['r']*255), int(c['g']*255), int(c['b']*255)
            a = round(c.get('a', 1), 2)
            color_str = f' fill=rgba({r},{g},{b},{a})'

    size_str = f' [{int(size.get("width",0))}x{int(size.get("height",0))}]' if size else ''
    text_str = f' text="{chars[:60]}"' if chars else ''
    font_str = f' font={style.get("fontFamily","")}/{style.get("fontSize","")}/{style.get("fontWeight","")}' if style else ''

    print(' ' * indent + f'[{t}] {name}{text_str}{size_str}{color_str}{font_str}')
    for child in node.get('children', []):
        extract_design(child, indent + 2)

for node_id, node_data in nodes.items():
    doc = node_data.get('document', {})
    print(f'=== NODE: {node_id} - {doc.get("name","")} ===')
    extract_design(doc)
```

### Önemli Notlar
- Rate limit aşılırsa 60 saniye bekle ve tekrar dene
- Node ID'deki `-` karakterini API'de `:` olarak kullan (URL encode gerekebilir)
- `depth` parametresiyle ağaç derinliğini kontrol et (4-5 genellikle yeterli)
- Token'ı asla kaynak koduna veya git'e commit etme

---

## Proje Yapısı

**Mimari:** Clean Architecture + SwiftUI + UIKit hybrid (ViewController host pattern)

Her modül şu dosyalardan oluşur:
- `SDK{Name}ViewController.swift` — UIKit host, SwiftUI view'ı barındırır
- `{Name}View.swift` — SwiftUI UI
- `{Name}ViewModel.swift` — İş mantığı ve state

**Tema:**
- `IDColor.*` — renk token'ları (`SDKDesignTokens.swift`)
- `IDFont.*` — yazı tipi token'ları
- `IDSpacing.*` — boşluk token'ları
- `IDRadius.*` — köşe yuvarlama token'ları

**Dil Desteği:** TR, EN, DE, AZ, RU (`SDKLangManager`)
