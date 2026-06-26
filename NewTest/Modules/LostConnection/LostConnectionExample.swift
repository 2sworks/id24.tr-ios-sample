//
//  LostConnectionExample.swift
//  NewTest
//
//  SDK "Bağlantı Koptu" (yeniden bağlanma) ekranı — ENTEGRASYON REHBERİ.
//  Görüşme sırasında internet/socket koptuğunda SDK bu ekranı otomatik sunar.
//  1) LostConnectionExample         → SDK hazır ekranı
//  2) LostConnectionExampleThemed   → tema override
//  3) LostConnectionExampleReplaced → KENDİ VIEW'ın + SDK'nın SDKLostConnectionViewModel iş akışı
//

import SwiftUI
import IdentifySDK

// MARK: - 1) Varsayılan
struct LostConnectionExample: View {
    var body: some View { SDKLostConnectionView() }
}

// MARK: - 2) Tema
struct LostConnectionExampleThemed: View {
    var body: some View {
        SDKLostConnectionView().showcaseThemed(primary: IDColor.accentPurple)
    }
}

// MARK: - 3) Tam replace — HOST VM (SDKLostConnectionViewModel sarmalı) + dış extension
struct LostConnectionExampleReplaced: View {
    @StateObject private var host = LostConnectionHostViewModel()
    // DIŞARIDAN (developer) ayarlanabilen değişkenler — environment object ile enjekte.
    @EnvironmentObject private var config: LostConnectionConfig
    @EnvironmentObject private var coordinator: SDKFlowCoordinator
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: IDSpacing.lg) {
            Text(config.headerTitle)
                .font(IDFont.bodyLarge(.semibold))
                .foregroundColor(config.accentColor)

            ShowcaseStatusRow(label: "İnternet", value: host.isNetworkAvailable ? "var" : "yok", ok: host.isNetworkAvailable)
            ShowcaseStatusRow(label: "Durum", value: host.statusText, ok: host.canReconnect)

            SDKButton(title: host.isReconnecting ? "Bağlanıyor…" : "Yeniden Bağlan",
                      style: .primary, isDisabled: !host.canReconnect) {
                host.reconnect()
            }

            ShowcaseEventLog(events: host.events)
            Spacer()
        }
        .padding(IDSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(IDColor.adaptiveBackground(for: colorScheme).ignoresSafeArea())
        .onAppear {
            host.onCompleted = { coordinator.advanceToNextModule() }
            host.onEvent = { print("analytics:", $0) }
            host.autoReconnect = config.autoReconnect   // env-config → otomatik yeniden bağlanma
        }
    }
}

// MARK: - Previews
#Preview("Bağlantı Koptu — Varsayılan") { LostConnectionExample().showcaseHost() }
#Preview("Bağlantı Koptu — Tema") { LostConnectionExampleThemed().showcaseHost() }
#Preview("Bağlantı Koptu — Tam Replace") {
    LostConnectionExampleReplaced().showcaseHost().environmentObject(LostConnectionConfig.preview)
}
