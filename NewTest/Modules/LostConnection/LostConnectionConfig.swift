//
//  LostConnectionConfig.swift
//  NewTest
//
//  Bağlantı Koptu (yeniden bağlanma) ekranı için DIŞARIDAN ayarlanabilen değişkenler.
//  Bu ekran, görüşme sırasında internet/socket koptuğunda SDK tarafından otomatik sunulur.
//

import SwiftUI
import IdentifySDK

@MainActor
final class LostConnectionConfig: ObservableObject {
    @Published var headerTitle: String = "Bağlantı Koptu (özel UI + host VM)"
    @Published var accentColor: Color = IDColor.primary
    /// Ağ geri geldiğinde otomatik yeniden bağlanmayı dene.
    @Published var autoReconnect: Bool = false

    static var preview: LostConnectionConfig {
        let c = LostConnectionConfig()
        c.headerTitle = "Bağlantı Koptu (env-config ile özelleştirildi)"
        c.accentColor = IDColor.accentTeal
        return c
    }
}
