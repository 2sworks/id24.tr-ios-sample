//
//  AppStateViewModel.swift
//  NewTest
//
//  Ana uygulama state'ini yöneten ViewModel.
//  SDK kurulumu, modül geçişleri ve modulePublisher aboneliğini yönetir.
//

import Foundation
import SwiftUI
import Combine
import IdentifySDK

@MainActor
final class AppStateViewModel: ObservableObject {

    // MARK: - Published State

    /// Şu an aktif olan SDK modülü (modulePublisher'dan gelir)
    @Published private(set) var activeModule: SdkModules? = nil

    /// Gösterilecek bir sonraki UIKit VC (SDKModuleHostView tarafından kullanılır)
    @Published var nextModuleVC: UIViewController? = nil

    /// SDK bağlantısı devam ediyor mu
    @Published private(set) var isLoading: Bool = false

    /// SDK veya ağ hatası mesajı
    @Published var sdkError: String? = nil

    // MARK: - Private

    let manager = IdentifyManager.shared
    private var modulePublisherCancellable: AnyCancellable?

    // MARK: - Init

    init() {
        subscribeToModulePublisher()
    }

    // MARK: - modulePublisher Aboneliği

    /// Her setupSDK çağrısı öncesinde yeniden abone olunur.
    /// closeSDK sonrası send(completion: .finished) geldiğinde stream kapandığından
    /// yeni oturum için abonelik yenilenmesi gerekir.
    func subscribeToModulePublisher() {
        modulePublisherCancellable?.cancel()
        modulePublisherCancellable = manager.modulePublisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] module in
                    self?.activeModule = module
                }
            )
    }

    // MARK: - SDK Kurulumu

    func setupSDK(
        identId: String,
        apiUrl: String,
        idLang: IDLang = .TR,
        signLangSupport: Bool = false,
        bigCustomerCam: Bool = false,
        useSSLPinning: Bool = false,
        useNewLiveness: Bool = false,
        selectedModules: [SdkModules] = []
    ) {
        isLoading = true
        sdkError = nil

        // Her yeni oturum için aboneliği yenile
        subscribeToModulePublisher()

        // Modül controller eşleşmelerini kaydet
        registerModuleControllers()

        manager.setupSDK(
            identId: identId,
            baseApiUrl: apiUrl,
            networkOptions: SDKNetworkOptions(
                timeoutIntervalForRequest: 30,
                timeoutIntervalForResource: 30,
                useSslPinning: useSSLPinning
            ),
            kpsData: nil,
            identCardType: [.idCard, .passport, .oldSchool],
            signLangSupport: signLangSupport,
            nfcMaxErrorCount: 3,
            logLevel: .all,
            bigCustomerCam: bigCustomerCam,
            selectedModules: selectedModules,
            turnKey: ""
        ) { [weak self] socketStats, apiResp, webErr in
            guard let self else { return }
            self.isLoading = false

            if let err = webErr, err.errorMessages != "" {
                self.sdkError = err.errorMessages
                return
            }

            if socketStats?.isConnected == true && (apiResp.result ?? false) {
                self.manager.moduleStepOrder = 0
                self.advanceToNextModule()
            } else if socketStats?.isConnected == false {
                self.sdkError = "Socket bağlantısı kurulamadı"
            }
        }
    }

    // MARK: - Modül Geçişi

    func advanceToNextModule() {
        manager.getNextModule { [weak self] nextVC in
            DispatchQueue.main.async {
                self?.nextModuleVC = nextVC
            }
        }
    }

    func skipCurrentModule() {
        manager.skipModule()
        advanceToNextModule()
    }

    /// Ana ekrana dön - oturumu sıfırla
    func resetFlow() {
        nextModuleVC = nil
        activeModule = nil
        sdkError = nil
        isLoading = false
    }

    // MARK: - Private

    private func registerModuleControllers() {
        manager.selfieModuleController        = UIHostingController(rootView: SelfieView().environmentObject(self))
        manager.idCardModuleController        = UIHostingController(rootView: IdCardView().environmentObject(self))
        manager.idCardOVDModuleController     = UIHostingController(rootView: OVDView().environmentObject(self))
        manager.nfcModuleController           = UIHostingController(rootView: NFCView().environmentObject(self))
        manager.signatureModuleController     = UIHostingController(rootView: SignatureView().environmentObject(self))
        manager.videoRecorderModuleController = UIHostingController(rootView: VideoRecorderView().environmentObject(self))
        manager.livenessModuleController      = UIHostingController(rootView: LivenessView().environmentObject(self))
        manager.addressModuleController       = UIHostingController(rootView: AddressConfirmView().environmentObject(self))
        manager.callWaitModuleController      = UIHostingController(rootView: CallScreenView().environmentObject(self))
        manager.speechModuleController        = UIHostingController(rootView: SpeechRecView().environmentObject(self))
        manager.thankYouViewController        = UIHostingController(rootView: ThankYouView().environmentObject(self))
        manager.prepareViewController         = UIHostingController(rootView: PrepareView().environmentObject(self))
        manager.socketMessageListener         = self
    }
}

// MARK: - SDKSocketListener

extension AppStateViewModel: SDKSocketListener {
    func listenSocketMessage(message: SDKCallActions) {
        // Genel socket mesajları burada işlenir.
        // CallScreen aktifken bu delegate CallScreenViewModel'e devredilir.
        switch message {
        case .wrongSocketActionErr(let error):
            sdkError = error
        default:
            break
        }
    }
}
