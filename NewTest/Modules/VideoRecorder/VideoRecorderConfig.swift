//
//  VideoRecorderConfig.swift
//  NewTest
//
//  Video Kayıt modülü için DIŞARIDAN ayarlanabilen değişkenler (`@EnvironmentObject`).
//

import SwiftUI
import IdentifySDK

@MainActor
final class VideoRecorderConfig: ObservableObject {
    @Published var headerTitle: String = "Video Kayıt (özel UI + host VM)"
    @Published var accentColor: Color = IDColor.primary

    static var preview: VideoRecorderConfig {
        let c = VideoRecorderConfig()
        c.headerTitle = "Video (env-config ile özelleştirildi)"
        c.accentColor = IDColor.accentTeal
        return c
    }
}
