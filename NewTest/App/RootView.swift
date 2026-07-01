//
//  RootView.swift
//  NewTest
//
//  Minimal SDK tüketici kökü. Tüm akış SDK'nın Default UI'ından gelir:
//  SDKFlowHostView (route → drop-in View) + SDKViewRegistry (override/custom) +
//  SDKFlowCoordinator (modül geçişleri). Host yalnızca LoginView'ı kök olarak verir.
//

import SwiftUI
import IdentifySDK

struct RootView: View {

    @StateObject private var coordinator = SDKFlowCoordinator()
    @State private var registry = SDKViewRegistry()
    @State private var didConfigure = false

    var body: some View {
        SDKFlowHostView(coordinator: coordinator, registry: registry) {
            LoginView()
                .environmentObject(coordinator)
        }
        .onAppear(perform: configureIfNeeded)
    }

    /// WS3d — host tarafı genişletme/override demoları (kullanıcı isteğinin canlı kanıtı).
    private func configureIfNeeded() {
        guard !didConfigure else { return }
        didConfigure = true

        // 1) Host-side localization override: dışarıdan SDK string'ini değiştir.
//        SDKLocalization.shared.registerOverrides([
//            .tr: ["Connect": "Bağlan (host)"],
//            .eng: ["Connect": "Connect (host)"]
//        ])

        // 2) External ekran ekleme: Selfie modülünden ÖNCE bir bilgilendirme ekranı.
//        registry.custom("welcome") {
//            SDKExternalInfoView(
//                title: "Hoş geldiniz",
//                subtitle: "Selfie adımından önce kısa bir bilgilendirme ekranı (host tarafından eklendi).",
//                systemIcon: "hand.wave.fill"
//            )
//        }
//        coordinator.insert(["welcome"], before: .selfie)

        // 3) Mevcut bir SDK modülünü host tasarımıyla override: AddressConfirm farklı renkte.
//        registry.override(.addressConfirm) {
//            AddressConfirmExample()
//        }
    }
}
