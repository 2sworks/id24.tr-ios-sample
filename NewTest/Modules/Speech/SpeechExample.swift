//
//  SpeechExample.swift
//  NewTest
//
//  SDK "Konuşma" modülü — ENTEGRASYON REHBERİ.
//  3) SpeechExampleReplaced → KENDİ VIEW'ın + SDK'nın SDKSpeechRecViewModel iş akışı
//  Devreye alma: registry.override(.speech) { SpeechExampleReplaced() }
//

import SwiftUI
import IdentifySDK

// MARK: - 1) Varsayılan
struct SpeechExample: View {
    var body: some View { SDKSpeechRecView() }
}

// MARK: - 2) Tema
struct SpeechExampleThemed: View {
    var body: some View {
        SDKSpeechRecView().showcaseThemed(primary: IDColor.accentPurple)
    }
}

// MARK: - 3) Tam replace — HOST VM (SDKSpeechRecViewModel sarmalı) + dış extension
struct SpeechExampleReplaced: View {
    @StateObject private var host = SpeechHostViewModel()
    // DIŞARIDAN (developer) ayarlanabilen değişkenler — environment object ile enjekte.
    @EnvironmentObject private var config: SpeechConfig
    @EnvironmentObject private var coordinator: SDKFlowCoordinator
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: IDSpacing.lg) {
            Text(config.headerTitle)
                .font(IDFont.bodyLarge(.semibold))
                .foregroundColor(config.accentColor)

            ShowcaseStatusRow(label: "Söylenecek kelime", value: host.targetWord)
            ShowcaseStatusRow(label: "Tanınan", value: host.recognizedText.isEmpty ? "—" : host.recognizedText)
            ShowcaseStatusRow(label: "Başarılı", value: host.speechSuccess ? "evet" : "hayır", ok: host.speechSuccess)

            SDKButton(title: host.isRecording ? "Kaydı Durdur" : "Kayda Başla", style: .secondary) { host.toggleRecording() }
            SDKButton(title: "Onayla ve Devam", style: .primary, isDisabled: !host.speechSuccess) { host.confirm() }

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
#Preview("Konuşma — Varsayılan") { SpeechExample().showcaseHost() }
#Preview("Konuşma — Tema") { SpeechExampleThemed().showcaseHost() }
#Preview("Konuşma — Tam Replace") {
    SpeechExampleReplaced().showcaseHost().environmentObject(SpeechConfig.preview)
}
