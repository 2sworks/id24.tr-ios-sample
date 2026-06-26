//
//  ThankYouConfig.swift
//  NewTest
//
//  Sonuç modülü için DIŞARIDAN ayarlanabilen değişkenler (`@EnvironmentObject`).
//  status, gösterilecek sonucu (pozitif/negatif/...) dışarıdan belirler.
//

import SwiftUI
import IdentifySDK

@MainActor
final class ThankYouConfig: ObservableObject {
    @Published var headerTitle: String = "İşlem Sonucu (özel UI + host VM)"
    @Published var accentColor: Color = IDColor.primary
    /// Dışarıdan verilen sonuç statüsü.
    @Published var status: ThankYouStatus = .completed

    static var preview: ThankYouConfig {
        let c = ThankYouConfig()
        c.headerTitle = "Sonuç (env-config ile özelleştirildi)"
        c.accentColor = IDColor.accentTeal
        return c
    }
}
