//
//  SignatureConfig.swift
//  NewTest
//
//  İmza modülü için DIŞARIDAN ayarlanabilen değişkenler (`@EnvironmentObject`).
//

import SwiftUI
import IdentifySDK

@MainActor
final class SignatureConfig: ObservableObject {
    @Published var headerTitle: String = "İmza (özel UI + host VM)"
    @Published var accentColor: Color = IDColor.primary

    static var preview: SignatureConfig {
        let c = SignatureConfig()
        c.headerTitle = "İmza (env-config ile özelleştirildi)"
        c.accentColor = IDColor.accentTeal
        return c
    }
}
