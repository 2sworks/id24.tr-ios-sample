//
//  OvdExample.swift
//  NewTest
//
//  SDK "Kimlik OVD" (hologram/gökkuşağı) modülü — ENTEGRASYON REHBERİ.
//  1) OvdExample         → SDK hazır ekranı (kamera + yönlendirmeli adımlar)
//  2) OvdExampleThemed   → tema override
//  3) OvdExampleReplaced → KENDİ VIEW'ın + SDK'nın SDKIdCardOVDViewModel iş akışı
//
//  Devreye alma: registry.override(.idCardOVD) { OvdExampleReplaced() }
//  Not: Gerçek hologram tespiti SDK'da TODO (algoritma yok); akış/adımlar çalışır.
//

import SwiftUI
import IdentifySDK

// MARK: - 1) Varsayılan
struct OvdExample: View {
    var body: some View { SDKIdCardOVDView() }
}

// MARK: - 2) Tema
struct OvdExampleThemed: View {
    var body: some View {
        SDKIdCardOVDView().showcaseThemed(primary: IDColor.accentPurple)
    }
}

// MARK: - 3) Tam replace — HOST VM (SDKIdCardOVDViewModel sarmalı) + dış extension
struct OvdExampleReplaced: View {
    @StateObject private var host = OvdHostViewModel()
    // DIŞARIDAN (developer) ayarlanabilen değişkenler — environment object ile enjekte.
    @EnvironmentObject private var config: OvdConfig
    @EnvironmentObject private var coordinator: SDKFlowCoordinator
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: IDSpacing.lg) {
            Text(config.headerTitle)
                .font(IDFont.bodyLarge(.semibold))
                .foregroundColor(config.accentColor)

            ProgressView(value: host.progress)
                .tint(config.accentColor)

            ShowcaseStatusRow(label: "Aktif adım", value: host.stepText, ok: host.canContinue)
            ShowcaseStatusRow(label: "Talimat", value: host.instruction)

            // Rehber/preview'de gerçek kamera yok → örnek kare ile adımı ilerletiyoruz.
            SDKButton(title: "Kareyi Yakala (örnek)", style: .secondary) {
                host.capture(ShowcaseSample.image)
            }
            SDKButton(title: "Devam", style: .primary, isDisabled: !host.canContinue) {
                coordinator.advanceToNextModule()
            }
            SDKButton(title: "Baştan Başlat", style: .cancel) { host.reset() }

            ShowcaseEventLog(events: host.events)
            Spacer()
        }
        .padding(IDSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(IDColor.adaptiveBackground(for: colorScheme).ignoresSafeArea())
        .onAppear {
            host.onEvent = { print("analytics:", $0) }
            host.applyConfig(requiresHologram: config.requiresHologramStep)   // env-config → host
        }
    }
}

// MARK: - Previews
#Preview("OVD — Varsayılan") { OvdExample().showcaseHost() }
#Preview("OVD — Tema") { OvdExampleThemed().showcaseHost() }
#Preview("OVD — Tam Replace") {
    OvdExampleReplaced().showcaseHost().environmentObject(OvdConfig.preview)
}
