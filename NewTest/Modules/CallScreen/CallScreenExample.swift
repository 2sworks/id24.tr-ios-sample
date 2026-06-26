//
//  CallScreenExample.swift
//  NewTest
//
//  SDK "Görüşme" modülü — ENTEGRASYON REHBERİ.
//  3) CallScreenExampleReplaced → KENDİ VIEW'ın + SDK'nın SDKCallScreenViewModel iş akışı
//  Devreye alma: registry.override(.callScreen) { CallScreenExampleReplaced() }
//

import SwiftUI
import IdentifySDK

// MARK: - 1) Varsayılan
struct CallScreenExample: View {
    var body: some View { SDKCallScreenView() }
}

// MARK: - 2) Tema
struct CallScreenExampleThemed: View {
    var body: some View {
        SDKCallScreenView().showcaseThemed(primary: IDColor.accentPurple)
    }
}

// MARK: - 3) Tam replace — HOST VM (SDKCallScreenViewModel sarmalı) + dış extension
struct CallScreenExampleReplaced: View {
    @StateObject private var host = CallScreenHostViewModel()
    // DIŞARIDAN (developer) ayarlanabilen değişkenler — environment object ile enjekte.
    @EnvironmentObject private var config: CallScreenConfig
    @EnvironmentObject private var coordinator: SDKFlowCoordinator
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: IDSpacing.lg) {
            Text(config.headerTitle)
                .font(IDFont.bodyLarge(.semibold))
                .foregroundColor(config.accentColor)

            ShowcaseStatusRow(label: "Durum", value: host.callStateText)
            ShowcaseStatusRow(label: "Sıra", value: host.queuePosition.isEmpty ? "—" : host.queuePosition)

            SDKButton(title: "Çağrıyı Kabul Et", style: .secondary) { host.acceptCall() }

            TextField("SMS Kodu (\(config.smsCodeLength) hane)", text: Binding(get: { host.smsCode }, set: { host.smsCode = $0 }))
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
            SDKButton(title: "Kodu Doğrula", style: .primary, isDisabled: !host.isSMSCodeValid) { host.verifySMS() }

            SDKButton(title: "Görüşmeyi Sonlandır", style: .cancel) { host.terminate(coordinator) }

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
#Preview("Görüşme — Varsayılan") { CallScreenExample().showcaseHost() }
#Preview("Görüşme — Tema") { CallScreenExampleThemed().showcaseHost() }
#Preview("Görüşme — Tam Replace") {
    CallScreenExampleReplaced().showcaseHost().environmentObject(CallScreenConfig.preview)
}
