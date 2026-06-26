//
//  IdCardExample.swift
//  NewTest
//
//  SDK "Kimlik Kartı" modülü — ENTEGRASYON REHBERİ.
//  1) IdCardExample         → SDK hazır ekranı
//  2) IdCardExampleThemed   → tema override
//  3) IdCardExampleReplaced → KENDİ VIEW'ın + SDK'nın SDKIdCardViewModel iş akışı
//
//  Devreye alma: registry.override(.idCard) { IdCardExampleReplaced() }
//

import SwiftUI
import IdentifySDK

// MARK: - 1) Varsayılan
struct IdCardExample: View {
    var body: some View { SDKIdCardView() }
}

// MARK: - 2) Tema
struct IdCardExampleThemed: View {
    var body: some View {
        SDKIdCardView().showcaseThemed(primary: IDColor.accentPurple)
    }
}

// MARK: - 3) Tam replace — HOST VM (SDKIdCardViewModel sarmalı) + dış extension
struct IdCardExampleReplaced: View {
    @StateObject private var host = IdCardHostViewModel()
    // DIŞARIDAN (developer) ayarlanabilen değişkenler — environment object ile enjekte.
    @EnvironmentObject private var config: IdCardConfig
    @EnvironmentObject private var coordinator: SDKFlowCoordinator
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: IDSpacing.lg) {
            Text(config.headerTitle)
                .font(IDFont.bodyLarge(.semibold))
                .foregroundColor(config.accentColor)

            ShowcaseStatusRow(label: "Aktif yüz", value: host.currentSideText)
            ShowcaseStatusRow(label: "OCR sonucu", value: host.resultText.isEmpty ? "—" : host.resultText)

            SDKButton(title: "Ön Yüzü Tara", style: .secondary) { host.scanFront(ShowcaseSample.image) }
            if config.requireBackSide {
                SDKButton(title: "Arka Yüzü Tara", style: .secondary) { host.scanBack(ShowcaseSample.image) }
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
        .onAppear { host.onEvent = { print("analytics:", $0) } }
    }
}

// MARK: - Previews
#Preview("Kimlik — Varsayılan") { IdCardExample().showcaseHost() }
#Preview("Kimlik — Tema") { IdCardExampleThemed().showcaseHost() }
#Preview("Kimlik — Tam Replace") {
    IdCardExampleReplaced().showcaseHost().environmentObject(IdCardConfig.preview)
}
