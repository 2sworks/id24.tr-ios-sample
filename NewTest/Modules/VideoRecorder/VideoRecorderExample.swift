//
//  VideoRecorderExample.swift
//  NewTest
//
//  SDK "Video Kayıt" modülü — ENTEGRASYON REHBERİ.
//  3) VideoRecorderExampleReplaced → KENDİ VIEW'ın + SDK'nın SDKVideoRecorderViewModel iş akışı
//  Devreye alma: registry.override(.videoRecorder) { VideoRecorderExampleReplaced() }
//

import SwiftUI
import IdentifySDK

// MARK: - 1) Varsayılan
struct VideoRecorderExample: View {
    var body: some View { SDKVideoRecorderView() }
}

// MARK: - 2) Tema
struct VideoRecorderExampleThemed: View {
    var body: some View {
        SDKVideoRecorderView().showcaseThemed(primary: IDColor.accentPurple)
    }
}

// MARK: - 3) Tam replace — HOST VM (SDKVideoRecorderViewModel sarmalı) + dış extension
struct VideoRecorderExampleReplaced: View {
    @StateObject private var host = VideoRecorderHostViewModel()
    // DIŞARIDAN (developer) ayarlanabilen değişkenler — environment object ile enjekte.
    @EnvironmentObject private var config: VideoRecorderConfig
    @EnvironmentObject private var coordinator: SDKFlowCoordinator
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: IDSpacing.lg) {
            Text(config.headerTitle)
                .font(IDFont.bodyLarge(.semibold))
                .foregroundColor(config.accentColor)

            ShowcaseStatusRow(label: "Süre limiti", value: "\(host.timeLimit) sn")
            ShowcaseStatusRow(label: "Video seçildi", value: host.hasVideo ? "evet" : "hayır", ok: host.hasVideo)
            ShowcaseStatusRow(label: "Yükleme", value: host.uploadCompleted ? "tamam" : "—", ok: host.uploadCompleted)

            SDKButton(title: "Videoyu Sil", style: .secondary) { host.deleteVideo() }
            SDKButton(title: "Yükle ve Devam", style: .primary, isDisabled: !host.hasVideo) { host.upload() }

            ShowcaseEventLog(events: host.events)
            Spacer()
        }
        .padding(IDSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(IDColor.adaptiveBackground(for: colorScheme).ignoresSafeArea())
        .onAppear {
            host.onCompleted = { coordinator.advanceToNextModule() }
            host.onEvent = { print("analytics:", $0) }
        }
    }
}

// MARK: - Previews
#Preview("Video — Varsayılan") { VideoRecorderExample().showcaseHost() }
#Preview("Video — Tema") { VideoRecorderExampleThemed().showcaseHost() }
#Preview("Video — Tam Replace") {
    VideoRecorderExampleReplaced().showcaseHost().environmentObject(VideoRecorderConfig.preview)
}
