//
//  SelfieConfig.swift
//  NewTest
//
//  Selfie modülü için DIŞARIDAN (developer) ayarlanabilen değişkenler.
//  `@EnvironmentObject` ile enjekte edilir; host VM davranışlarını besler.
//
//      SelfieExampleReplaced().environmentObject(SelfieConfig())
//

import SwiftUI
import IdentifySDK

@MainActor
final class SelfieConfig: ObservableObject {
    @Published var headerTitle: String = "Selfie (özel UI + host VM)"
    @Published var accentColor: Color = IDColor.primary
    /// Deneme limiti (host VM'e geçirilir).
    @Published var maxAttempts: Int = 3
    /// Boş/geçersiz görseli ele (host customValidation'ı besler).
    @Published var rejectEmptyImage: Bool = true

    static var preview: SelfieConfig {
        let c = SelfieConfig()
        c.headerTitle = "Selfie (env-config ile özelleştirildi)"
        c.accentColor = IDColor.accentTeal
        c.maxAttempts = 5
        return c
    }
}
