//
//  CallScreenConfig.swift
//  NewTest
//
//  Görüşme modülü için DIŞARIDAN ayarlanabilen değişkenler (`@EnvironmentObject`).
//

import SwiftUI
import IdentifySDK

@MainActor
final class CallScreenConfig: ObservableObject {
    @Published var headerTitle: String = "Görüşme (özel UI + host VM)"
    @Published var accentColor: Color = IDColor.primary
    /// SMS kod uzunluğu (gösterim/ipucu).
    @Published var smsCodeLength: Int = 6

    static var preview: CallScreenConfig {
        let c = CallScreenConfig()
        c.headerTitle = "Görüşme (env-config ile özelleştirildi)"
        c.accentColor = IDColor.accentTeal
        return c
    }
}
