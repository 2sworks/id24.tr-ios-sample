//
//  PrepareExample.swift
//  NewTest
//
//  SDK "Hazırlık" modülü — ENTEGRASYON REHBERİ.
//  1) PrepareExample         → SDK hazır ekranı
//  2) PrepareExampleThemed   → tema override
//  3) PrepareExampleReplaced → KENDİ VIEW'ın + SDK'nın SDKPrepareViewModel iş akışı
//
//  Devreye alma: registry.override(.prepare) { PrepareExampleReplaced() }
//

import SwiftUI
import IdentifySDK

// MARK: - 1) Varsayılan
struct PrepareExample: View {
    var body: some View { SDKPrepareView() }
}

// MARK: - 2) Tema
struct PrepareExampleThemed: View {
    var body: some View {
        SDKPrepareView().showcaseThemed(primary: IDColor.accentPurple)
    }
}

// MARK: - 3) Tam replace — HOST VM (SDKPrepareViewModel sarmalı) + dış extension
struct PrepareExampleReplaced: View {
    @StateObject private var host = PrepareHostViewModel()
    // DIŞARIDAN (developer) ayarlanabilen değişkenler — environment object ile enjekte.
    @EnvironmentObject private var config: PrepareConfig
    @EnvironmentObject private var coordinator: SDKFlowCoordinator
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: IDSpacing.lg) {
            Text(config.headerTitle)
                .font(IDFont.bodyLarge(.semibold))
                .foregroundColor(config.accentColor)

            ShowcaseStatusRow(label: "Kamera izni", value: host.cameraAuthorized ? "verildi" : "bekliyor", ok: host.cameraAuthorized)
            ShowcaseStatusRow(label: "Mikrofon izni", value: host.micAuthorized ? "verildi" : "bekliyor", ok: host.micAuthorized)
            ShowcaseStatusRow(label: "Konuşma izni", value: host.speechAuthorized ? "verildi" : "bekliyor", ok: host.speechAuthorized)

            SDKButton(title: "İzinleri Kontrol Et", style: .secondary) { host.checkPermissions() }
            SDKButton(title: "Devam", style: .primary, isDisabled: !host.allPermissionsGranted) { host.complete() }

            ShowcaseEventLog(events: host.events)
            Spacer()
        }
        .padding(IDSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(IDColor.adaptiveBackground(for: colorScheme).ignoresSafeArea())
        .onAppear {
            host.onCompleted = { coordinator.advanceToNextModule() }   // dışarıdan enjekte
            host.onEvent = { print("analytics:", $0) }
            host.requireSpeech = config.requireSpeechPermission        // env-config → host davranışı
        }
    }
}

// MARK: - Previews
#Preview("Hazırlık — Varsayılan") { PrepareExample().showcaseHost() }
#Preview("Hazırlık — Tema") { PrepareExampleThemed().showcaseHost() }
#Preview("Hazırlık — Tam Replace") {
    PrepareExampleReplaced().showcaseHost().environmentObject(PrepareConfig.preview)
}
