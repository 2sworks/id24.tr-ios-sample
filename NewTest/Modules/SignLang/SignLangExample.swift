//
//  SignLangExample.swift
//  NewTest
//
//  SDK "İşaret Dili" (opt-in) modülü — ENTEGRASYON REHBERİ.
//  CallScreen başında, sunucu işaret dili desteği istediğinde fullScreenCover olarak sunulur.
//  1) SignLangExample         → SDK hazır ekranı (onFinish closure'ı ile)
//  2) SignLangExampleThemed   → tema override
//  3) SignLangExampleReplaced → KENDİ VIEW'ın + SDK'nın SDKSignLangViewModel iş akışı
//

import SwiftUI
import IdentifySDK

// MARK: - 1) Varsayılan
struct SignLangExample: View {
    var body: some View { SDKSignLangView(onFinish: {}) }
}

// MARK: - 2) Tema
struct SignLangExampleThemed: View {
    var body: some View {
        SDKSignLangView(onFinish: {}).showcaseThemed(primary: IDColor.accentPurple)
    }
}

// MARK: - 3) Tam replace — HOST VM (SDKSignLangViewModel sarmalı) + dış extension
struct SignLangExampleReplaced: View {
    @StateObject private var host = SignLangHostViewModel()
    // DIŞARIDAN (developer) ayarlanabilen değişkenler — environment object ile enjekte.
    @EnvironmentObject private var config: SignLangConfig
    @EnvironmentObject private var coordinator: SDKFlowCoordinator
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: IDSpacing.lg) {
            Text(config.headerTitle)
                .font(IDFont.bodyLarge(.semibold))
                .foregroundColor(config.accentColor)

            Toggle("İşaret dili desteği iste",
                   isOn: Binding(get: { host.isEnabled }, set: { host.isEnabled = $0 }))
                .tint(config.accentColor)

            ShowcaseStatusRow(label: "Tercih", value: host.isEnabled ? "açık" : "kapalı", ok: host.isEnabled)

            SDKButton(title: "Onayla ve Devam", style: .primary) { host.proceed() }

            ShowcaseEventLog(events: host.events)
            Spacer()
        }
        .padding(IDSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(IDColor.adaptiveBackground(for: colorScheme).ignoresSafeArea())
        .onAppear {
            host.onCompleted = { coordinator.advanceToNextModule() }
            host.onEvent = { print("analytics:", $0) }
            host.applyDefault(config.defaultEnabled)   // env-config → varsayılan tercih
        }
    }
}

// MARK: - Previews
#Preview("İşaret Dili — Varsayılan") { SignLangExample().showcaseHost() }
#Preview("İşaret Dili — Tema") { SignLangExampleThemed().showcaseHost() }
#Preview("İşaret Dili — Tam Replace") {
    SignLangExampleReplaced().showcaseHost().environmentObject(SignLangConfig.preview)
}
