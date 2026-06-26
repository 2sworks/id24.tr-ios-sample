//
//  NfcExample.swift
//  NewTest
//
//  SDK "NFC" modülü — ENTEGRASYON REHBERİ.
//  1) NfcExample         → SDK hazır ekranı
//  2) NfcExampleThemed   → tema override
//  3) NfcExampleReplaced → KENDİ VIEW'ın + SDK'nın SDKNfcViewModel iş akışı
//
//  Devreye alma: registry.override(.nfc) { NfcExampleReplaced() }
//

import SwiftUI
import IdentifySDK

// MARK: - 1) Varsayılan
struct NfcExample: View {
    var body: some View { SDKNfcView() }
}

// MARK: - 2) Tema
struct NfcExampleThemed: View {
    var body: some View {
        SDKNfcView().showcaseThemed(primary: IDColor.accentPurple)
    }
}

// MARK: - 3) Tam replace — HOST VM (SDKNfcViewModel sarmalı) + dış extension
struct NfcExampleReplaced: View {
    @StateObject private var host = NfcHostViewModel()
    // DIŞARIDAN (developer) ayarlanabilen değişkenler — environment object ile enjekte.
    @EnvironmentObject private var config: NfcConfig
    @EnvironmentObject private var coordinator: SDKFlowCoordinator
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: IDSpacing.md) {
            Text(config.headerTitle)
                .font(IDFont.bodyLarge(.semibold))
                .foregroundColor(config.accentColor)

            // MRZ alanları host VM üzerinden binding:
            TextField("Seri No", text: Binding(get: { host.serialNo }, set: { host.serialNo = $0 })).textFieldStyle(.roundedBorder)
            TextField("Doğum (YYMMDD)", text: Binding(get: { host.birthDate }, set: { host.birthDate = $0 })).textFieldStyle(.roundedBorder)
            TextField("Geçerlilik (YYMMDD)", text: Binding(get: { host.validDate }, set: { host.validDate = $0 })).textFieldStyle(.roundedBorder)

            ShowcaseStatusRow(label: "Durum", value: host.nfcStatus.isEmpty ? "hazır" : host.nfcStatus, ok: host.nfcCompleted)

            SDKButton(title: "Çip Okumayı Başlat", style: .secondary) { host.startNFC() }
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
            host.onCompleted = { coordinator.advanceToNextModule() }
            host.onEvent = { print("analytics:", $0) }
            // DIŞARIDAN (env-config): MRZ ön-doldurma (örn. kullanıcı profilinden)
            if config.autoPrefill {
                host.prefill(serial: config.prefillSerial, birth: config.prefillBirth, valid: config.prefillValid)
            }
        }
    }
}

// MARK: - Previews
#Preview("NFC — Varsayılan") { NfcExample().showcaseHost() }
#Preview("NFC — Tema") { NfcExampleThemed().showcaseHost() }
#Preview("NFC — Tam Replace") {
    NfcExampleReplaced().showcaseHost().environmentObject(NfcConfig.preview)
}
