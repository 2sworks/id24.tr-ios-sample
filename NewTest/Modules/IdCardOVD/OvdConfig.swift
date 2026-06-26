//
//  OvdConfig.swift
//  NewTest
//
//  Kimlik OVD modülü için DIŞARIDAN ayarlanabilen değişkenler (`@EnvironmentObject`).
//

import SwiftUI
import IdentifySDK

@MainActor
final class OvdConfig: ObservableObject {
    @Published var headerTitle: String = "Kimlik OVD (özel UI + host VM)"
    @Published var accentColor: Color = IDColor.primary
    /// Hologram (eğ-çevir) adımı zorunlu mu?
    @Published var requiresHologramStep: Bool = true

    static var preview: OvdConfig {
        let c = OvdConfig()
        c.headerTitle = "OVD (env-config ile özelleştirildi)"
        c.accentColor = IDColor.accentTeal
        c.requiresHologramStep = true
        return c
    }
}
