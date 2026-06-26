//
//  SignatureExample.swift
//  NewTest
//
//  SDK "İmza" modülü — ENTEGRASYON REHBERİ.
//  3) SignatureExampleReplaced → KENDİ VIEW'ın + SDK'nın SDKSignatureViewModel iş akışı
//  Devreye alma: registry.override(.signature) { SignatureExampleReplaced() }
//

import SwiftUI
import IdentifySDK

// MARK: - 1) Varsayılan
struct SignatureExample: View {
    var body: some View { SDKSignatureView() }
}

// MARK: - 2) Tema
struct SignatureExampleThemed: View {
    var body: some View {
        SDKSignatureView().showcaseThemed(primary: IDColor.accentPurple)
    }
}

// MARK: - 3) Tam replace — HOST VM (SDKSignatureViewModel sarmalı) + dış extension
struct SignatureExampleReplaced: View {
    @StateObject private var host = SignatureHostViewModel()
    // DIŞARIDAN (developer) ayarlanabilen değişkenler — environment object ile enjekte.
    @EnvironmentObject private var config: SignatureConfig
    @EnvironmentObject private var coordinator: SDKFlowCoordinator
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: IDSpacing.lg) {
            Text(config.headerTitle)
                .font(IDFont.bodyLarge(.semibold))
                .foregroundColor(config.accentColor)

            ShowcaseStatusRow(label: "İmza çizildi", value: host.signatureDrawn ? "evet" : "hayır", ok: host.signatureDrawn)
            ShowcaseStatusRow(label: "Yükleme", value: host.uploadCompleted ? "tamam" : "—", ok: host.uploadCompleted)

            SDKButton(title: "İmzayı İşaretle", style: .secondary) { host.markDrawn() }
            SDKButton(title: "Temizle", style: .secondary) { host.clear() }
            SDKButton(title: "Yükle ve Devam", style: .primary, isDisabled: !host.signatureDrawn) {
                host.upload(ShowcaseSample.image)
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
        }
    }
}

// MARK: - Previews
#Preview("İmza — Varsayılan") { SignatureExample().showcaseHost() }
#Preview("İmza — Tema") { SignatureExampleThemed().showcaseHost() }
#Preview("İmza — Tam Replace") {
    SignatureExampleReplaced().showcaseHost().environmentObject(SignatureConfig.preview)
}
