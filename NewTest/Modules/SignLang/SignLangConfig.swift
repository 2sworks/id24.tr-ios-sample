//
//  SignLangConfig.swift
//  NewTest
//
//  İşaret Dili (opt-in) modülü için DIŞARIDAN ayarlanabilen değişkenler (`@EnvironmentObject`).
//

import SwiftUI
import IdentifySDK

@MainActor
final class SignLangConfig: ObservableObject {
    @Published var headerTitle: String = "İşaret Dili (özel UI + host VM)"
    @Published var accentColor: Color = IDColor.primary
    /// Açılışta işaret dili tercihinin varsayılan değeri.
    @Published var defaultEnabled: Bool = false

    static var preview: SignLangConfig {
        let c = SignLangConfig()
        c.headerTitle = "İşaret Dili (env-config ile özelleştirildi)"
        c.accentColor = IDColor.accentTeal
        c.defaultEnabled = true
        return c
    }
}
