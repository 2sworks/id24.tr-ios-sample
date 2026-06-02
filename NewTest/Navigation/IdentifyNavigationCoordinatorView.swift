//
//  IdentifyNavigationCoordinatorView.swift
//  NewTest
//
//  Uygulamanın navigasyon köküdür.
//  AppNavigationCoordinator + AppStateViewModel burada oluşturulur ve
//  tüm alt ekranlara EnvironmentObject olarak iletilir.
//

import SwiftUI

struct IdentifyNavigationCoordinatorView: View {

    // MARK: - State

    @StateObject private var coordinator: AppNavigationCoordinator
    @StateObject private var appState: AppStateViewModel

    // MARK: - Init

    init() {
        let c = AppNavigationCoordinator()
        let s = AppStateViewModel(coordinator: c)
        self._coordinator = StateObject(wrappedValue: c)
        self._appState    = StateObject(wrappedValue: s)
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            // Derinlik 0 = login (sabit kök)
            IdentifyNavContent(
                coordinator: coordinator,
                appState: appState,
                depth: 0
            )
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Preview

struct IdentifyNavigationCoordinatorView_Previews: PreviewProvider {
    static var previews: some View {
        IdentifyNavigationCoordinatorView()
    }
}
