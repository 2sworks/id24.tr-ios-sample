//
//  AppNavigationCoordinator.swift
//  NewTest
//
//  UIPilot benzeri koordinatör — iOS 14+ uyumlu.
//  NavigationView + recursive NavigationLink zinciriyle
//  tip güvenli, animasyonlu push/pop navigasyonu sağlar.
//

import SwiftUI

// MARK: - AppNavigationCoordinator

@MainActor
final class AppNavigationCoordinator: ObservableObject {

    /// Login daima kök olduğundan path'e dahil edilmez.
    @Published fileprivate(set) var path: [IdentifyNavigationFlow] = []

    /// Scanner ekranından geri dönüldüğünde çağrılacak callback.
    var onScanComplete: ((UIImage) -> Void)?

    // MARK: - Navigation

    func push(_ route: IdentifyNavigationFlow) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) {
            path.removeAll()
        }
    }
}

// MARK: - IdentifyNavContent (recursive NavigationLink zinciri)

/// Her seviye kendisini bir sonraki rota için NavigationLink zinciri olarak kurar.
/// Body yalnızca o seviye aktif olduğunda render edilir → sonsuz özyineleme oluşmaz.
struct IdentifyNavContent: View {

    @ObservedObject var coordinator: AppNavigationCoordinator
    @ObservedObject var appState: AppStateViewModel
    let depth: Int

    // MARK: - Computed

    /// Tam yol: login sabit kök + coordinator.path
    private var fullPath: [IdentifyNavigationFlow] {
        [.login] + coordinator.path
    }

    /// Bu derinlikte gösterilecek rota (yoksa nil → EmptyView)
    private var currentRoute: IdentifyNavigationFlow? {
        depth < fullPath.count ? fullPath[depth] : nil
    }

    // MARK: - Body

    var body: some View {
        if let route = currentRoute {
            screenFor(route)
                .background(
                    NavigationLink(
                        destination: IdentifyNavContent(
                            coordinator: coordinator,
                            appState: appState,
                            depth: depth + 1
                        ),
                        isActive: Binding(
                            get: { self.coordinator.path.count > self.depth },
                            set: { active in
                                if !active {
                                    // Kullanıcı geri çekince path'i bu seviyeye kırp
                                    self.coordinator.path = Array(
                                        self.coordinator.path.prefix(self.depth)
                                    )
                                }
                            }
                        )
                    ) { EmptyView() }
                    .hidden()
                )
        }
    }

    // MARK: - Screen factory

    @ViewBuilder
    private func screenFor(_ route: IdentifyNavigationFlow) -> some View {
        Group {
            switch route {
            case .login:
                LoginView()
            case .prepare:
                PrepareView()
            case .selfie:
                SelfieView()
            case .idCard:
                IdCardView()
            case .idCardScanning(let cardType):
                IdCardScanningView(cardType: cardType)
            case .idCardOVD:
                OVDView()
            case .nfc:
                NFCView()
            case .liveness:
                LivenessView()
            case .speech:
                SpeechRecView()
            case .addressConfirm:
                AddressConfirmView()
            case .signature:
                SignatureView()
            case .videoRecorder:
                VideoRecorderView()
            case .callScreen:
                CallScreenView()
            case .thankYou(let status):
                ThankYouView(status: status)
            case .idCardScanner(let side):
                IdCardScannerView(side: side)
            case .externalScreen(let title, let subtitle, let icon):
                ExternalView(title: title, subtitle: subtitle, icon: icon)
            }
        }
        .environmentObject(appState)
        .environmentObject(coordinator)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(route != .login)
    }
}
