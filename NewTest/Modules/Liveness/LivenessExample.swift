//
//  LivenessExample.swift
//  NewTest
//
//  SDK "Canlılık" modülü — ENTEGRASYON REHBERİ.
//  3) LivenessExampleReplaced → KENDİ VIEW'ın + SDK'nın SDKLivenessViewModel iş akışı
//  Devreye alma: registry.override(.liveness) { LivenessExampleReplaced() }
//

import SwiftUI
import IdentifySDK

// MARK: - 1) Varsayılan
struct LivenessExample: View {
    var body: some View { SDKLivenessView() }
}

// MARK: - 2) Tema
struct LivenessExampleThemed: View {
    var body: some View {
        SDKLivenessView().showcaseThemed(primary: IDColor.accentPurple)
    }
}

// MARK: - 3) Tam replace — HOST VM (SDKLivenessViewModel sarmalı) + dış extension
struct LivenessExampleReplaced: View {
    @StateObject private var host = LivenessHostViewModel()
    // DIŞARIDAN (developer) ayarlanabilen değişkenler — environment object ile enjekte.
    @EnvironmentObject private var config: LivenessConfig
    @EnvironmentObject private var coordinator: SDKFlowCoordinator
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: IDSpacing.lg) {
            Text(config.headerTitle)
                .font(IDFont.bodyLarge(.semibold))
                .foregroundColor(config.accentColor)

            ShowcaseStatusRow(label: "Talimat", value: host.stepInstruction.isEmpty ? "—" : host.stepInstruction)
            ShowcaseStatusRow(label: "Tüm adımlar", value: host.allStepsCompleted ? "tamam" : "devam", ok: host.allStepsCompleted)

            SDKButton(title: "Sıradaki Adımı Al", style: .secondary) { host.nextStep() }
            SDKButton(title: "Kareyi Gönder", style: .secondary) { host.sendFrame(ShowcaseSample.image) }

            ShowcaseEventLog(events: host.events)
            Spacer()
        }
        .padding(IDSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(IDColor.adaptiveBackground(for: colorScheme).ignoresSafeArea())
        .onAppear {
            host.onCompleted = { coordinator.advanceToNextModule() }
            host.onEvent = { print("analytics:", $0) }
            if config.autoStart { host.start() }   // env-config → ilk adımı otomatik çek
        }
    }
}

// MARK: - Previews
#Preview("Canlılık — Varsayılan") { LivenessExample().showcaseHost() }
#Preview("Canlılık — Tema") { LivenessExampleThemed().showcaseHost() }
#Preview("Canlılık — Tam Replace") {
    LivenessExampleReplaced().showcaseHost().environmentObject(LivenessConfig.preview)
}
