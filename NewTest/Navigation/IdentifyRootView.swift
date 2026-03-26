//
//  IdentifyRootView.swift
//  NewTest
//
//  SwiftUI navigasyon kökü.
//  AppStateViewModel'i oluşturur ve tüm child view'lara EnvironmentObject olarak iletir.
//  NavigationView ile Login ekranını gösterir; SDK modülleri geldiğinde SDKModuleHostView'a geçer.
//

import SwiftUI
import IdentifySDK

struct IdentifyRootView: View {

    @StateObject private var appState = AppStateViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                LoginView()
                    .environmentObject(appState)
                    .navigationBarHidden(true)

                // nextModuleVC set edildiğinde gizli NavigationLink tetiklenir.
                // UIKit VC'ler kendi navigationController push'larını kullanır.
                NavigationLink(
                    destination: Group {
                        if let vc = appState.nextModuleVC {
                            SDKModuleHostView(viewController: vc)
                                .ignoresSafeArea()
                                .navigationBarBackButtonHidden(true)
                                .environmentObject(appState)
                        }
                    },
                    isActive: Binding(
                        get: { appState.nextModuleVC != nil },
                        set: { if !$0 { appState.nextModuleVC = nil } }
                    )
                ) {
                    EmptyView()
                }
                .hidden()
            }
        }
        .navigationViewStyle(.stack)
    }
}
