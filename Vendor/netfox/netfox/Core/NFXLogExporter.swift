//
//  NFXLogExporter.swift
//  netfox
//
//  Yerel fork eklentisi — log satırlarının dosya olarak dışa aktarımı.
//

import Foundation

/// Dışa aktarma biçimi.
enum NFXExportFormat {
    case csv
    case json
    case plainText

    var title: String {
        switch self {
        case .csv: return "CSV"
        case .json: return "JSON"
        case .plainText: return "Düz metin"
        }
    }

    var fileExtension: String {
        switch self {
        case .csv: return "csv"
        case .json: return "json"
        case .plainText: return "txt"
        }
    }
}

/// Panel kayıtlarını paylaşılabilir bir dosyaya çevirir.
///
/// Paylaşım sayfasına düz metin yerine dosya verilir; böylece kayıt WhatsApp ya da
/// e-posta eki olarak gönderilebilir. İçerik panelde görünen hâliyle, yani
/// `NFXLogRedactor` uygulanmış olarak yazılır.
enum NFXLogExporter {

    private static let fileNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()

    private static let isoFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter
    }()

    // MARK: Konsol kayıtları

    /// Konsol satırlarını geçici dizine yazar ve dosya adresini döndürür.
    static func exportConsole(entries: [NFXLogEntry], format: NFXExportFormat) -> URL? {
        let content: String
        switch format {
        case .csv:
            var rows = ["time,type,source,message"]
            rows += entries.map { entry in
                [entry.timeText, entry.type, entry.isStructured ? "sdk" : "console", entry.message]
                    .map(escapeCSVField)
                    .joined(separator: ",")
            }
            content = rows.joined(separator: "\n")

        case .json:
            let items: [[String: Any]] = entries.map { entry in
                [
                    "time": entry.timeText,
                    "timestamp": isoFormatter.string(from: entry.date),
                    "type": entry.type,
                    "source": entry.isStructured ? "sdk" : "console",
                    "message": entry.message
                ]
            }
            content = jsonText(root: ["kind": "console", "entries": items])

        case .plainText:
            content = entries.map { $0.exportText }.joined(separator: "\n")
        }

        return write(content: content, name: "console", format: format)
    }

    // MARK: Harici kaynak kayıtları

    /// Harici kaynağın (ör. WebSocket) kayıtlarını dosyaya yazar.
    static func exportExternal(entries: [NFXExternalLogEntry], sourceTitle: String, format: NFXExportFormat) -> URL? {
        let content: String
        switch format {
        case .csv:
            var rows = ["index,direction,message"]
            rows += entries.enumerated().map { index, entry in
                ["\(index + 1)", entry.label, entry.message]
                    .map(escapeCSVField)
                    .joined(separator: ",")
            }
            content = rows.joined(separator: "\n")

        case .json:
            let items: [[String: Any]] = entries.enumerated().map { index, entry in
                ["index": index + 1, "direction": entry.label, "message": entry.message]
            }
            content = jsonText(root: ["kind": sourceTitle.lowercased(), "entries": items])

        case .plainText:
            content = entries.map { "[\($0.label)] \($0.message)" }.joined(separator: "\n")
        }

        return write(content: content, name: sourceTitle.lowercased(), format: format)
    }


    // MARK: HTTP kayıtları

    /// Listelenen istekleri dosyaya yazar. Gövdeler değil, üstbilgi ve zamanlama
    /// alanları aktarılır; ayrıntı için tek istek ekranındaki paylaşım kullanılır.
    static func exportRequests(models: [NFXHTTPModel], format: NFXExportFormat) -> URL? {
        let content: String
        switch format {
        case .csv:
            var rows = ["time,method,status,duration_s,type,request_bytes,response_bytes,url"]
            rows += models.map { model in
                let time: String = model.requestTime ?? ""
                let method: String = model.requestMethod ?? ""
                let status: String = model.responseStatus.map { String($0) } ?? ""
                let duration: String = model.timeInterval.map { String(format: "%.3f", $0) } ?? ""
                let requestBytes: String = String(model.requestBodyLength ?? 0)
                let responseBytes: String = String(model.responseBodyLength ?? 0)
                let url: String = NFXLogRedactor.redact(model.requestURL ?? "")

                let fields: [String] = [
                    time, method, status, duration,
                    model.shortTypeString, requestBytes, responseBytes, url
                ]
                return fields.map(escapeCSVField).joined(separator: ",")
            }
            content = rows.joined(separator: "\n")

        case .json:
            let items: [[String: Any]] = models.map { model in
                var item: [String: Any] = [
                    "time": model.requestTime ?? "",
                    "method": model.requestMethod ?? "",
                    "type": model.shortTypeString,
                    "url": NFXLogRedactor.redact(model.requestURL ?? ""),
                    "requestBytes": model.requestBodyLength ?? 0,
                    "responseBytes": model.responseBodyLength ?? 0
                ]
                if let status = model.responseStatus { item["status"] = status }
                if let interval = model.timeInterval { item["durationSeconds"] = interval }
                if let date = model.requestDate { item["timestamp"] = isoFormatter.string(from: date) }
                return item
            }
            content = jsonText(root: ["kind": "requests", "entries": items])

        case .plainText:
            content = models.map { model in
                let time: String = model.requestTime ?? ""
                let method: String = model.requestMethod ?? ""
                let status: String = model.responseStatus.map { String($0) } ?? "-"
                let url: String = NFXLogRedactor.redact(model.requestURL ?? "")
                return "\(time) \(method) \(status) \(url)"
            }.joined(separator: "\n")
        }

        return write(content: content, name: "requests", format: format)
    }

    // MARK: Yardımcılar

    /// Ortak üstbilgiyi ekleyip JSON metni üretir.
    private static func jsonText(root: [String: Any]) -> String {
        var payload = root
        payload["app"] = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "app"
        payload["exportedAt"] = isoFormatter.string(from: Date())

        guard
            let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]),
            let text = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }
        return text
    }

    /// RFC 4180: alan tırnaklanır, içindeki tırnak ikilenir.
    private static func escapeCSVField(_ field: String) -> String {
        let normalized = field
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(normalized)\""
    }

    /// İçeriği geçici dizine yazar. Aynı adla önceki dosya varsa üzerine yazılır.
    private static func write(content: String, name: String, format: NFXExportFormat) -> URL? {
        let stamp = fileNameFormatter.string(from: Date())
        let fileName = "\(name)-log-\(stamp).\(format.fileExtension)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
