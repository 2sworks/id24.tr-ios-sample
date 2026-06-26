//
//  IdCardConfig.swift
//  NewTest
//
//  Kimlik Kartı modülü için DIŞARIDAN ayarlanabilen değişkenler (`@EnvironmentObject`).
//

import SwiftUI
import IdentifySDK

@MainActor
final class IdCardConfig: ObservableObject {
    @Published var headerTitle: String = "Kimlik Kartı (özel UI + host VM)"
    @Published var accentColor: Color = IDColor.primary
    /// Arka yüz taraması da zorunlu mu? (rehber gösterimi)
    @Published var requireBackSide: Bool = true

    static var preview: IdCardConfig {
        let c = IdCardConfig()
        c.headerTitle = "Kimlik (env-config ile özelleştirildi)"
        c.accentColor = IDColor.accentTeal
        return c
    }
}
