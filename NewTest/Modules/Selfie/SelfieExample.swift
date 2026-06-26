//
//  SelfieExample.swift
//  NewTest
//
//  SDK "Selfie" modülü — ENTEGRASYON REHBERİ.
//  1) SelfieExample         → SDK hazır ekranı
//  2) SelfieExampleThemed   → tema override
//  3) SelfieExampleReplaced → KENDİ VIEW'ın + SDK'nın SDKSelfieViewModel iş akışı
//
//  Devreye alma: registry.override(.selfie) { SelfieExampleReplaced() }
//

import SwiftUI
import IdentifySDK

// MARK: - 1) Varsayılan
struct SelfieExample: View {
    var body: some View { SDKSelfieView() }
}

// MARK: - 2) Tema
struct SelfieExampleThemed: View {
    var body: some View {
        SDKSelfieView().showcaseThemed(primary: IDColor.accentPurple)
    }
}

// MARK: - 3) Tam replace — HOST VM (SDKSelfieViewModel sarmalı) + dış extension noktaları
struct SelfieExampleReplaced: View {
    // Host VM: SDK iş mantığını sarar + maxAttempts/customValidation/event-log ekler.
    @StateObject private var host = SelfieHostViewModel()
    // DIŞARIDAN (developer) ayarlanabilen değişkenler — environment object ile enjekte.
    @EnvironmentObject private var config: SelfieConfig
    @EnvironmentObject private var coordinator: SDKFlowCoordinator
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: IDSpacing.lg) {
            Text(config.headerTitle)
                .font(IDFont.bodyLarge(.semibold))
                .foregroundColor(config.accentColor)

            ShowcaseStatusRow(label: "Yüz tespit edildi", value: host.faceDetected ? "evet" : "hayır", ok: host.faceDetected)
            ShowcaseStatusRow(label: "Deneme", value: "\(host.attemptCount)/\(host.maxAttempts)")
            ShowcaseStatusRow(label: "Sonuç", value: host.resultText.isEmpty ? "—" : host.resultText)

            SDKButton(title: "Selfie'yi Doğrula", style: .secondary) {
                host.capture(ShowcaseSample.image)   // host: limit + custom validation + SDK
            }
            SDKButton(title: "Devam", style: .primary, isDisabled: !host.canContinue) {
                coordinator.advanceToNextModule()
            }

            ShowcaseEventLog(events: host.events)
            Spacer()
        }
        .padding(IDSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(IDColor.adaptiveBackground(for: colorScheme).ignoresSafeArea())
        .onAppear {
            // DIŞARIDAN ENJEKTE: analytics hook + özel doğrulama + config (env'den)
            host.maxAttempts = config.maxAttempts
            host.onEvent = { event in print("analytics:", event) }
            if config.rejectEmptyImage {
                host.customValidation = { image in image.size.width > 0 } // kendi kuralın
            }
        }
    }
}

// MARK: - Previews
#Preview("Selfie — Varsayılan") { SelfieExample().showcaseHost() }
#Preview("Selfie — Tema") { SelfieExampleThemed().showcaseHost() }
#Preview("Selfie — Tam Replace") {
    SelfieExampleReplaced().showcaseHost().environmentObject(SelfieConfig.preview)
}
