//
//  SpeechConfig.swift
//  NewTest
//
//  Konuşma modülü için DIŞARIDAN ayarlanabilen değişkenler (`@EnvironmentObject`).
//

import SwiftUI
import IdentifySDK

@MainActor
final class SpeechConfig: ObservableObject {
    @Published var headerTitle: String = "Konuşma (özel UI + host VM)"
    @Published var accentColor: Color = IDColor.primary

    static var preview: SpeechConfig {
        let c = SpeechConfig()
        c.headerTitle = "Konuşma (env-config ile özelleştirildi)"
        c.accentColor = IDColor.accentTeal
        return c
    }
}
