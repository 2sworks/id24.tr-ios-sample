//
//  NFXLogStore.swift
//  netfox
//
//  Yerel fork eklentisi — konsol satırlarının bellek içi deposu.
//

import Foundation

/// Panelde gösterilen tek bir konsol satırı.
public class NFXLogEntry: NSObject {
    /// Satırın üretildiği an.
    public let date: Date
    /// Satır gövdesi. Zaman damgası ve süsleme ayıklanmış hâlidir.
    public let message: String
    /// Kaynağın verdiği sınıflandırma. Yapısal kaynak yoksa "console".
    public let type: String
    /// Satır uygulama kodundan mı yoksa yakalanan stdout/stderr'den mi geldi.
    public let isStructured: Bool

    init(date: Date = Date(), message: String, type: String, isStructured: Bool) {
        self.date = date
        self.message = message
        self.type = type
        self.isStructured = isStructured
        super.init()
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    /// Listede ve dışa aktarmada kullanılan zaman metni.
    public var timeText: String {
        return NFXLogEntry.formatter.string(from: date)
    }

    /// Dışa aktarma satırı.
    public var exportText: String {
        return "\(timeText) [\(type)] \(message)"
    }
}

/// Konsol satırlarını tutan halka arabellek.
///
/// İki kaynaktan beslenir: SDK'nın yapısal log geri çağrısı ve `NFXStdoutCapture`
/// üzerinden gelen ham stdout/stderr satırları. Aynı satır iki kaynaktan da
/// gelebildiği için yapısal kayıtların gövdesi kısa süre saklanır; ham satır bu
/// gövdelerden birini içeriyorsa yutulur ve yapısal kayıt korunur.
public class NFXLogStore: NSObject {
    public static let shared = NFXLogStore()

    /// Deponun taşıyacağı en fazla satır sayısı.
    public var capacity: Int = 5000

    /// Yeni satır eklendiğinde ana kuyrukta yayınlanır.
    public static let didAddEntryNotification = Notification.Name("NFXLogStoreDidAddEntry")

    private var entries: [NFXLogEntry] = []
    private let queue = DispatchQueue(label: "com.netfox.logstore", attributes: .concurrent)

    /// Yapısal kaynağın son verdiği gövdeler. Ham satır ayıklamasında kullanılır.
    private var recentStructuredBodies: [(body: String, date: Date)] = []
    /// Bir gövdenin ham eşleşmesinin ne kadar süre bekleneceği.
    private let duplicateWindow: TimeInterval = 2.0

    /// Bekleyen bir değişiklik bildirimi var mı. Kendi kilidiyle korunur; depo
    /// kuyruğuyla iç içe girmemesi için ayrıdır.
    private var notificationScheduled = false
    private let notificationLock = NSLock()
    /// İki bildirim arasındaki en kısa süre.
    private let notificationInterval: TimeInterval = 0.2

    private override init() {
        super.init()
    }

    /// Depodaki satırların anlık kopyası.
    public func allEntries() -> [NFXLogEntry] {
        return queue.sync { entries }
    }

    /// Yapısal kaynaktan gelen satır. Ayıklamaya takılmaz, her zaman eklenir.
    public func addStructured(message: String, type: String, date: Date = Date()) {
        let trimmed = NFXLogRedactor.redact(message).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        queue.async(flags: .barrier) {
            self.recentStructuredBodies.append((body: trimmed, date: date))
            self.pruneStructuredBodiesLocked()
        }
        append(NFXLogEntry(date: date, message: trimmed, type: type, isStructured: true))
    }

    /// Yakalanan stdout/stderr satırı. Yapısal bir kaydın konsol izdüşümüyse yutulur.
    ///
    /// Sadeleştirme ayıklamadan önce yapılır; iki kaynak da aynı kurallardan
    /// geçtiği için gövde eşleşmesi bozulmaz.
    public func addRaw(line: String) {
        let trimmed = NFXLogRedactor.redact(line).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let isDuplicate: Bool = queue.sync {
            let now = Date()
            return recentStructuredBodies.contains { candidate in
                now.timeIntervalSince(candidate.date) <= duplicateWindow
                    && trimmed.contains(candidate.body)
            }
        }
        guard !isDuplicate else { return }

        append(NFXLogEntry(message: trimmed, type: "console", isStructured: false))
    }

    /// Depoyu boşaltır.
    public func clear() {
        queue.async(flags: .barrier) {
            self.entries.removeAll()
            self.recentStructuredBodies.removeAll()
        }
        postDidAddEntry()
    }

    /// Tüm satırları paylaşılabilir tek metne çevirir.
    public func exportText() -> String {
        return allEntries().map { $0.exportText }.joined(separator: "\n")
    }

    private func append(_ entry: NFXLogEntry) {
        queue.async(flags: .barrier) {
            self.entries.append(entry)
            if self.entries.count > self.capacity {
                self.entries.removeFirst(self.entries.count - self.capacity)
            }
        }
        postDidAddEntry()
    }

    /// Bildirim yayınını kısıtlar: yoğun akışta her satır için ana kuyruğa iş
    /// bırakılmaz, pencere başına tek bildirim gider.
    private func postDidAddEntry() {
        notificationLock.lock()
        let alreadyScheduled = notificationScheduled
        notificationScheduled = true
        notificationLock.unlock()
        guard !alreadyScheduled else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + notificationInterval) { [weak self] in
            guard let self = self else { return }
            self.notificationLock.lock()
            self.notificationScheduled = false
            self.notificationLock.unlock()
            NotificationCenter.default.post(name: NFXLogStore.didAddEntryNotification, object: nil)
        }
    }

    /// Yalnız `queue` üstünde barrier içinde çağrılmalıdır.
    private func pruneStructuredBodiesLocked() {
        let now = Date()
        recentStructuredBodies.removeAll { now.timeIntervalSince($0.date) > duplicateWindow }
    }
}
