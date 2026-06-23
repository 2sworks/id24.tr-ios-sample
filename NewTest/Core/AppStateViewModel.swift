//
//  AppStateViewModel.swift
//  NewTest
//
//  Ana uygulama state'ini yöneten ViewModel.
//  SDK kurulumu, modül geçişleri ve modulePublisher aboneliğini yönetir.
//  Navigasyon AppNavigationCoordinator üzerinden yapılır.
//

import Foundation
import SwiftUI
import Combine
import IdentifySDK

@MainActor
final class AppStateViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var activeModule: SdkModules? = nil
    @Published private(set) var isLoading: Bool = false
    @Published var sdkError: String? = nil

    /// Odada başka bir abone varsa true olur; modül geçişini engeller
    @Published private(set) var subRejected: Bool = false

    /// Progress bar için: geçerli adım ve toplam modül sayısı
    @Published private(set) var progressStep: Int = 0
    @Published private(set) var progressTotal: Int = 0

    // MARK: - Internal

    /// CallScreen'den taşınan ThankYou durumu; advanceToNextModule tüketir.
    var pendingThankYouStatus: ThankYouStatus = .completed

    // MARK: - Private

    let manager = IdentifyManager.shared
    private var modulePublisherCancellable: AnyCancellable?
    private weak var coordinator: AppNavigationCoordinator?

    // MARK: - Init

    init(coordinator: AppNavigationCoordinator? = nil) {
        self.coordinator = coordinator
        subscribeToModulePublisher()
    }

    // MARK: - modulePublisher Aboneliği

    /// Yalnızca activeModule state'ini günceller — navigasyon yapmaz.
    ///
    /// Navigasyonu publisher yerine getNextModule callback'ine taşıdık çünkü
    /// SDK closeSDK() çağrısında PassthroughSubject'e .finished gönderiyor.
    /// Tamamlanan bir subject'e yeni abone olmak hiç değer almadan biter,
    /// bu da ikinci oturumda navigasyonu sessizce kırıyordu.
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
        subscribeToModulePublisher()
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
            logLevel: .online,
            logOnlineSecretKey: "dGhpc19pc19qdXN0X2R1bW15X3NlY3JldF9mb3JfZGVtbw==",
            bigCustomerCam: bigCustomerCam,
            selectedModules: selectedModules,
            idCardLang: idLang,
            turnKey: "AEdHh9OZu1kg+nSBSd2UNMu9y4Kc3xVfgTsvw+PTAic=",
            wsSecretKey: "tgdRmdAABrWf9TCRJZIWoW3Bz0iPJpig5jtOkBN4pvU=",
            showThankYouPage: true,
            showNFCNotFoundPage: true,
            supportU18: true,
            AESKey: "SEATSJ8kk0v8+A1LeQsAMbOgL+fSj9pOaUKI5cDMITU=",
            enableAutoRotateOCR: true
        ) { [weak self] socketStats, apiResp, webErr in
            guard let self else { return }
            self.isLoading = false

            if let err = webErr, err.errorMessages != "" {
                self.sdkError = err.errorMessages
                return
            }

            if socketStats?.isConnected == true && (apiResp.result ?? false) {
                self.manager.moduleStepOrder = 0
                if !self.subRejected {
                    self.advanceToNextModule()
                }
                self.subRejected = false
            } else if socketStats?.isConnected == false {
                self.sdkError = "Socket bağlantısı kurulamadı"
            }
        }
    }

    // MARK: - Modül Geçişi

    /// Bir sonraki modüle geçer ve koordinatöre route push eder.
    ///
    /// UIKit'te moduleStepOrder, SDKViewOptionsController.didMove(toParent:) ile
    /// VC navigation stack'e push edildiğinde otomatik artıyordu.
    /// SwiftUI'da didMove hiç tetiklenmediğinden artırımı callback içinde yapıyoruz.
    ///
    /// Navigasyon da callback'te merkezi olarak yapılır:
    ///  - Normal modüller → sdkModule(for:) VC kimliğini SdkModules'a çevirir
    ///  - Tüm modüller bitti → SDK thankYouViewController döndürür, biz .thankYou push ederiz
    ///    (done branch'te modulePublisher emit etmediğinden publisher yerine callback kullanılır)
    func advanceToNextModule() {
        manager.getNextModule { [weak self] nextVC in
            guard let self else { return }
            Task { @MainActor in
                self.manager.moduleStepOrder += 1
                self.progressStep = self.manager.moduleStepOrder
                self.progressTotal = self.manager.modulesControllersArray.count
                if let module = self.sdkModule(for: nextVC) {
                    self.activeModule = module
                    self.coordinator?.push(module.navigationFlow)
                } else if nextVC === self.manager.thankYouViewController {
                    self.coordinator?.push(.thankYou(self.pendingThankYouStatus))
                    self.pendingThankYouStatus = .completed
                }
            }
        }
    }

    func skipCurrentModule() {
        manager.skipModule()
        advanceToNextModule()
    }

    func popBack() {
        if coordinator?.path.count == 1 {
            manager.exitSDK()
            subscribeToModulePublisher()
        }
        coordinator?.pop()
    }

    /// SDK modül akışını kesmeden önce özel bir ekran gösterir.
    /// moduleStepOrder değişmez — ExternalView'daki "Devam Et" advanceToNextModule() çağırır.
    func showExternalScreen(
        title: String,
        subtitle: String = "Devam etmeden önce lütfen bilgileri okuyun.",
        icon: String = "info.circle.fill"
    ) {
        coordinator?.push(.externalScreen(title: title, subtitle: subtitle, icon: icon))
    }

    func resetFlow() {
        subscribeToModulePublisher()
        coordinator?.popToRoot()
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 350_000_000)
            activeModule = nil
            sdkError = nil
            isLoading = false
            progressStep = 0
            progressTotal = 0
        }
    }

    /// CallScreen tek modül senaryosunda terminateCall sonrası doğrudan ThankYou'ya yönlendirir.
    /// advanceToNextModule()'u bypass eder; SDK state'i bozulmamış olsa bile güvenli çalışır.
    func pushThankYouDirectly(status: ThankYouStatus) {
        pendingThankYouStatus = status
        coordinator?.push(.thankYou(status))
        pendingThankYouStatus = .completed
    }

    // MARK: - Private

    /// getNextModule callback'inden dönen VC'yi SdkModules enum'una eşler.
    /// SDK içindeki sendCurrentScreen switch'iyle birebir örtüşür.
    /// registerModuleControllers() ile atanan placeholder VC'lerin
    /// kimlik (===) karşılaştırması güvenilirdir: her oturumda yeni instance oluşturulur.
    private func sdkModule(for vc: UIViewController) -> SdkModules? {
        switch vc {
        case manager.prepareViewController:          return .prepare
        case manager.idCardModuleController:         return .idCard
        case manager.idCardOVDModuleController:      return .idcard_w_ovd
        case manager.nfcModuleController:            return .nfc
        case manager.livenessModuleController:       return .livenessDetection
        case manager.selfieModuleController:         return .selfie
        case manager.videoRecorderModuleController:  return .videoRecord
        case manager.signatureModuleController:      return .signature
        case manager.speechModuleController:         return .speech
        case manager.addressModuleController:        return .addressConf
        case manager.callWaitModuleController:       return .waitScreen
        default:                                     return nil
        }
    }

    /// Her oturumda yeni placeholder VC'ler oluşturulur ve SDK'ya kaydedilir.
    /// SDK modulesControllersArray'i bu referansları tutar; getNextModule bunları döndürür.
    private func registerModuleControllers() {
        let dummy = { UIViewController() }
        manager.prepareViewController         = dummy()
        manager.idCardModuleController        = dummy()
        manager.idCardOVDModuleController     = dummy()
        manager.nfcModuleController           = dummy()
        manager.selfieModuleController        = dummy()
        manager.livenessModuleController      = dummy()
        manager.videoRecorderModuleController = dummy()
        manager.signatureModuleController     = dummy()
        manager.speechModuleController        = dummy()
        manager.addressModuleController       = dummy()
        manager.callWaitModuleController      = dummy()
        manager.thankYouViewController        = dummy()
        manager.socketMessageListener         = self
    }
}

// MARK: - SDKSocketListener

extension AppStateViewModel: SDKSocketListener {
    func listenSocketMessage(message: SDKCallActions) {
        switch message {
        case .wrongSocketActionErr(let error):
            sdkError = error
        case .subrejectedDismiss:
            subRejected = true
        default:
            break
        }
    }
}
