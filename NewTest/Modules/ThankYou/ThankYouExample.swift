//
//  ThankYouExample.swift
//  NewTest
//
//  SDK "Teşekkür/Sonuç" modülü — ENTEGRASYON REHBERİ.
//  3) ThankYouExampleReplaced → KENDİ VIEW'ın + SDK'nın SDKThankYouViewModel iş akışı
//  Devreye alma: registry.override(.thankYou(nil)) { ThankYouExampleReplaced() }
//
//  Not: ThankYou TERMİNAL ekrandır (sonraki modül yoktur); sadece sonucu gösterir.
//

import SwiftUI
import IdentifySDK

// MARK: - 1) Varsayılan
struct ThankYouExample: View {
    var body: some View { SDKThankYouView() }
}

// MARK: - 2) Tema
struct ThankYouExampleThemed: View {
    var body: some View {
        SDKThankYouView().showcaseThemed(primary: IDColor.accentPurple)
    }
}

// MARK: - 3) Tam replace — HOST VM (SDKThankYouViewModel sarmalı)
struct ThankYouExampleReplaced: View {
    // Host, sonuç statüsünü dışarıdan verebilir: ThankYouHostViewModel(status: .positive)
    @StateObject private var host = ThankYouHostViewModel()
    // DIŞARIDAN (developer) ayarlanabilen değişkenler — environment object ile enjekte.
    @EnvironmentObject private var config: ThankYouConfig
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: IDSpacing.lg) {
            Spacer()
            Image(systemName: host.kycCompleted ? "checkmark.seal.fill" : "seal")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(config.accentColor)
            Text(config.headerTitle)
                .font(IDFont.bodyLarge(.semibold))
                .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
            ShowcaseStatusRow(label: "KYC tamamlandı", value: host.kycCompleted ? "evet" : "hayır", ok: host.kycCompleted)
                .padding(.horizontal, IDSpacing.xl)
            ShowcaseEventLog(events: host.events)
                .padding(.horizontal, IDSpacing.xl)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(IDColor.adaptiveBackground(for: colorScheme).ignoresSafeArea())
    }
}

// MARK: - Previews
#Preview("Teşekkür — Varsayılan") { ThankYouExample().showcaseHost() }
#Preview("Teşekkür — Tema") { ThankYouExampleThemed().showcaseHost() }
#Preview("Teşekkür — Tam Replace") {
    ThankYouExampleReplaced().environmentObject(ThankYouConfig.preview)
}
