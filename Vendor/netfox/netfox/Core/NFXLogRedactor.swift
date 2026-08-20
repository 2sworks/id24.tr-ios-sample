//
//  NFXLogRedactor.swift
//  netfox
//
//  Yerel fork eklentisi — panelde gösterilen satırların sadeleştirilmesi.
//

import Foundation

/// Panele düşen satırlarda uygulamaya özgü kimlikleri ve okumayı zorlaştıran
/// blokları kısaltır.
///
/// Yalnız panelde uygulanır: Xcode konsoluna aynalanan çıktı ve SDK'nın sunucuya
/// gönderdiği log kuyruğu ham hâlinde kalır.
enum NFXLogRedactor {

    /// Ana uygulamanın paket kimliği. Metinde geçtiği yerde etiketle değiştirilir.
    private static let bundleIdentifier = Bundle.main.bundleIdentifier

    /// Ana uygulamanın paket dizini. Mutlak yol kuralından önce denenir.
    private static let bundlePath = Bundle.main.bundlePath

    /// Bellek adresleri: `0x104836c00` gibi. Küçük hex sabitlerine dokunulmaz.
    private static let pointerRegex = try? NSRegularExpression(pattern: "0x[0-9a-fA-F]{6,}")

    /// Uzun base64 blokları — fotoğraf ve belge yükleri.
    private static let base64Regex = try? NSRegularExpression(pattern: "[A-Za-z0-9+/]{200,}={0,2}")

    /// Mutlak dosya yolları: uygulama konteyneri, simülatör ve geliştirici dizinleri.
    private static let pathRegex = try? NSRegularExpression(pattern: "/(?:Users|private|var)/[^\\s\"',)]+")

    /// Satırı panelde gösterilecek hâline getirir.
    static func redact(_ line: String) -> String {
        var result = line

        if let bundlePath = bundlePath as String?, !bundlePath.isEmpty {
            result = result.replacingOccurrences(of: bundlePath, with: "‹bundle›")
        }
        if let identifier = bundleIdentifier, !identifier.isEmpty {
            result = result.replacingOccurrences(of: identifier, with: "‹bundle-id›")
        }

        result = replaceBase64(in: result)
        result = replacePaths(in: result)
        result = replaceMatches(of: pointerRegex, in: result, with: "0x…")

        return result
    }

    /// Base64 bloğunu yaklaşık boyutuyla etiketler.
    private static func replaceBase64(in text: String) -> String {
        guard let regex = base64Regex else { return text }

        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        guard !matches.isEmpty else { return text }

        var result = text
        for match in matches.reversed() {
            let encodedLength = match.range.length
            // Base64 çözüldüğünde yaklaşık dörtte üç uzunluğa iner.
            let byteCount = encodedLength * 3 / 4
            let label = "‹base64 \(sizeText(byteCount))›"
            if let range = Range(match.range, in: result) {
                result.replaceSubrange(range, with: label)
            }
        }
        return result
    }

    /// Mutlak yolu son bileşenine indirir.
    private static func replacePaths(in text: String) -> String {
        guard let regex = pathRegex else { return text }

        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        guard !matches.isEmpty else { return text }

        var result = text
        for match in matches.reversed() {
            let path = nsText.substring(with: match.range)
            let lastComponent = (path as NSString).lastPathComponent
            if let range = Range(match.range, in: result) {
                result.replaceSubrange(range, with: lastComponent.isEmpty ? "…" : "…/\(lastComponent)")
            }
        }
        return result
    }

    private static func replaceMatches(of regex: NSRegularExpression?, in text: String, with template: String) -> String {
        guard let regex = regex else { return text }
        let range = NSRange(location: 0, length: (text as NSString).length)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: template)
    }

    private static func sizeText(_ byteCount: Int) -> String {
        if byteCount < 1024 { return "\(byteCount) B" }
        let kilobytes = Double(byteCount) / 1024
        if kilobytes < 1024 { return String(format: "%.1f KB", kilobytes) }
        return String(format: "%.1f MB", kilobytes / 1024)
    }
}
