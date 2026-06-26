//
//  SwlConfig.swift
//  NewTest
//
//  Canlılıkla Selfie (ARKit) modülü için DIŞARIDAN ayarlanabilen değişkenler.
//  Not: AR doğrulama mantığı SDK controller'ında; host tema/başlık ve tam-replace ile özelleştirir.
//

import SwiftUI
import IdentifySDK

@MainActor
final class SwlConfig: ObservableObject {
    @Published var headerTitle: String = "Canlılıkla Selfie (ARKit)"
    @Published var accentColor: Color = IDColor.primary

    static var preview: SwlConfig {
        let c = SwlConfig()
        c.headerTitle = "Canlılıkla Selfie (env-config)"
        c.accentColor = IDColor.accentTeal
        return c
    }
}
