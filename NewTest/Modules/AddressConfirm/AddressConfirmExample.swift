//
//  AddressConfirmExample.swift
//  NewTest
//
//  SDK "Adres Onayı" modülü — ENTEGRASYON REHBERİ örneği.
//
//  Bu modül, rehberdeki CANLI / AKTİF örnektir: RootView.configureIfNeeded()
//  içinde `registry.override(.addressConfirm) { AddressConfirmExample() }` ile
//  gerçek akışa kayıtlıdır. Yani uygulama bu adıma geldiğinde mor temayla gelir.
//
//  Üç kullanım biçimi + #Preview:
//    1) AddressConfirmExample          → SDK ekranı + tema (renk) override (AKTİF)
//    2) AddressConfirmExampleDefault   → hiç dokunmadan SDK'nın hazır ekranı
//    3) AddressConfirmExampleReplaced  → ekranı tamamen kendi view'ınla değiştirme
//

import SwiftUI
import IdentifySDK

// MARK: - 1) Tema ile özelleştirilmiş (AKTİF — RootView'da kayıtlı)

struct AddressConfirmExample: View {
    var body: some View {
        SDKAddressConfirmView()
    }
}

// MARK: - 2) Varsayılan (dokunulmamış) SDK ekranı

struct AddressConfirmExampleDefault: View {
    var body: some View {
        SDKAddressConfirmView()
    }
}

// MARK: - 3) Tam replace — HOST VM (SDKAddressConfirmViewModel sarmalı) + dış extension

struct AddressConfirmExampleReplaced: View {
    @StateObject private var host = AddressConfirmHostViewModel()
    // DIŞARIDAN (developer) ayarlanabilen değişkenler — environment object ile enjekte.
    @EnvironmentObject private var config: AddressConfirmConfig
    @EnvironmentObject private var coordinator: SDKFlowCoordinator
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: IDSpacing.lg) {
            Text(config.headerTitle)
                .font(IDFont.bodyLarge(.semibold))
                .foregroundColor(config.accentColor)

            TextEditor(text: Binding(get: { host.addressText }, set: { host.addressText = $0 }))
                .frame(height: 80)
                .overlay(RoundedRectangle(cornerRadius: IDRadius.md).stroke(IDColor.inkBorder))

            ShowcaseStatusRow(label: "Adres geçerli", value: host.isAddressValid ? "evet" : "hayır", ok: host.isAddressValid)
            ShowcaseStatusRow(label: "Belge", value: host.hasDocument ? "yüklendi" : "yok", ok: host.hasDocument)

            SDKButton(title: "Belge Tara", style: .secondary) { host.selectDocument(ShowcaseSample.image) }
            SDKButton(title: "Gönder ve Devam", style: .primary, isDisabled: !host.canSubmit) { host.submit() }

            ShowcaseEventLog(events: host.events)
            Spacer()
        }
        .padding(IDSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(IDColor.adaptiveBackground(for: colorScheme).ignoresSafeArea())
        .onAppear {
            host.onCompleted = { coordinator.advanceToNextModule() }
            host.onEvent = { print("analytics:", $0) }
            // DIŞARIDAN (env-config): ekstra doğrulama (adreste en az N kelime)
            host.extraValidation = { $0.split(separator: " ").count >= config.minWordCount }
        }
    }
}

// MARK: - Previews

#Preview("Adres Onayı — Tema (aktif)") {
    AddressConfirmExample().showcaseHost()
}

#Preview("Adres Onayı — Varsayılan") {
    AddressConfirmExampleDefault().showcaseHost()
}

#Preview("Adres Onayı — Tam Replace") {
    AddressConfirmExampleReplaced().showcaseHost().environmentObject(AddressConfirmConfig.preview)
}
