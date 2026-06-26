//
//  LivenessConfig.swift
//  NewTest
//
//  Canlılık modülü için DIŞARIDAN ayarlanabilen değişkenler (`@EnvironmentObject`).
//

import SwiftUI
import IdentifySDK

@MainActor
final class LivenessConfig: ObservableObject {
    @Published var headerTitle: String = "Canlılık (özel UI + host VM)"
    @Published var accentColor: Color = IDColor.primary
    /// Ekran açılır açılmaz ilk adımı çek.
    @Published var autoStart: Bool = true

    static var preview: LivenessConfig {
        let c = LivenessConfig()
        c.headerTitle = "Canlılık (env-config ile özelleştirildi)"
        c.accentColor = IDColor.accentTeal
        return c
    }
}
