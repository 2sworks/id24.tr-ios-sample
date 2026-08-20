//
//  NFXExternalLog.swift
//  netfox
//
//  Yerel fork eklentisi — host uygulamanın kendi log kaynağı.
//

import Foundation
import UIKit

/// Panelde ayrı bir sekme olarak gösterilecek tek bir kayıt.
public class NFXExternalLogEntry: NSObject {
    /// Satırın yönü ya da sınıfı. Sekmede etiket olarak gösterilir.
    public let label: String
    /// Satır gövdesi.
    public let message: String
    /// Etiket rozetinin rengi. Verilmezse nötr renk kullanılır.
    public let tint: UIColor?

    public init(label: String, message: String, tint: UIColor? = nil) {
        self.label = label
        self.message = message
        self.tint = tint
        super.init()
    }
}

/// netfox'un bilmediği bir kaynağı (ör. WebSocket trafiği) panele bağlar.
///
/// netfox paketi host uygulamaya bağımlı olamayacağı için kayıtlar çağrı anında
/// bu closure üzerinden istenir.
public class NFXExternalLogSource: NSObject {
    /// Sekme başlığı.
    public let title: String
    /// Sekmenin her açılışında ve yenilemede çağrılır.
    private let provider: () -> [NFXExternalLogEntry]

    public init(title: String, provider: @escaping () -> [NFXExternalLogEntry]) {
        self.title = title
        self.provider = provider
        super.init()
    }

    public func fetch() -> [NFXExternalLogEntry] {
        return provider()
    }
}
