//
//  CallScreenViewModel.swift
//  NewTest
//
//  Video goruntulu gorusme ViewModel'i.
//  SDK: acceptCall, terminateCallByUser, smsVerification, webRTCClient, startRemoteNFC
//  Socket: SDKSocketListener - tum case'ler karsilanir
//
//  SDK tipler:
//  - acceptCall callback: (Bool?, SDKError?, Bool?) -> ()
//  - terminateCallByUser callback: (Bool) -> ()
//  - smsVerification callback: (Bool) -> ()
//  - SDKCallActions.approveSms(Bool), .updateQueue(String, String), .terminateCall(String?, String?)
//  - SDKCallActions.subrejectedDismiss(String), .networkQuality(String)
//

import Foundation
import UIKit
import IdentifySDK

// MARK: - Gorusme Durumu

enum CallState {
    case waiting, ringing, connected, smsVerification, nfcReading, ended
}

// MARK: - Baglanti Kalitesi

enum NetworkQuality {
    case none, bad, medium, good

    init(raw: String) {
        switch raw {
        case "bad": self = .bad
        case "medium": self = .medium
        case "good": self = .good
        default: self = .none
        }
    }
}

// MARK: - CallScreenViewModel

@MainActor
final class CallScreenViewModel: BaseModuleViewModel {

    // MARK: - Published State

    @Published private(set) var callState: CallState = .waiting
    @Published private(set) var queuePosition: String = ""
    @Published private(set) var estimatedWait: String = ""
    @Published private(set) var networkQuality: NetworkQuality = .none
    @Published var smsCode: String = ""
    @Published private(set) var endCallEnabled: Bool = true
    @Published private(set) var callCompleted: Bool = false
    @Published private(set) var nfcStatusMessage: String = ""
    /// Socket kaynaklı görüşme bitişlerinde ThankYou statüsünü view'a iletir.
    @Published private(set) var socketThankYouStatus: ThankYouStatus? = nil

    // NFC Remote Edit (panel .editNfcProcess komutuyla tetiklenir)
    @Published var showNFCEdit: Bool = false
    @Published var nfcEditSerial: String = ""
    @Published var nfcEditBirth: String = ""
    @Published var nfcEditValid: String = ""

    // Photo Toast
    @Published private(set) var photoTakenToast: String? = nil

    // Sign Language Gate
    @Published var showSignLangGate: Bool = false
    private var checkedSignLang: Bool = false

    // Lost Connection (bağlantı kopması / TURN_DISCONNECTED)
    @Published var showLostConnection: Bool = false
    @Published private(set) var lostConnectionCallCompleted: Bool = false

    // terminateCall işlemi sürerinde gelen diğer socket mesajlarını bloke eder.
    private var isTerminating: Bool = false

    var isSMSCodeValid: Bool { smsCode.count == 6 }

    // MARK: - WebRTC Views

    var remoteVideoView: UIView? { manager.webRTCClient?.remoteVideoView() }
    var localVideoView: UIView? { manager.webRTCClient?.localVideoView() }

    // MARK: - Init

    override init() {
        super.init()
    }

    #if DEBUG
    convenience init(
        previewState: CallState,
        queuePosition: String = "",
        estimatedWait: String = "",
        photoTakenToast: String? = nil,
        networkQuality: NetworkQuality = .none
    ) {
        self.init()
        callState = previewState
        self.queuePosition = queuePosition
        self.estimatedWait = estimatedWait
        self.photoTakenToast = photoTakenToast
        self.networkQuality = networkQuality
    }
    #endif

    // MARK: - Sign Language Gate

    func checkSignLangIfNeeded(appState: AppStateViewModel) {
        guard appState.manager.connectToSignLang, !checkedSignLang else { return }
        showSignLangGate = true
    }

    func signLangCompleted() {
        checkedSignLang = true
        showSignLangGate = false
    }

    // MARK: - Cagriyi Kabul Et

    func acceptCall() {
        isLoading = true
        manager.acceptCall { [weak self] connected, errMsg, sdpConnOk in
            Task { @MainActor in
                guard let self else { return }
                if connected == true {
                    // isLoading ve callState = .connected, .startTransfer socket event'inde set edilir
                    // (SDP answer alındıktan sonra kameralar hazır olur — legacy parity).
                    _ = sdpConnOk
                } else {
                    self.isLoading = false
                    self.errorMessage = errMsg?.errorMessages ?? "Baglanti basarisiz"
                }
            }
        }
    }

    // MARK: - Cagrıyı Sonlandir

    func terminateCall(appState: AppStateViewModel) {
        manager.terminateCallByUser { [weak self] success in
            Task { @MainActor in
                guard let self else { return }
                self.callState = .ended
                appState.pendingThankYouStatus = .notCompleted
                appState.advanceToNextModule()
            }
        }
    }

    // MARK: - SMS Dogrulama

    func verifySMS(appState: AppStateViewModel) {
        guard isSMSCodeValid else { return }
        isLoading = true
        manager.smsVerification(tan: smsCode) { [weak self] success in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                if success {
                    self.callState = .connected
                } else {
                    self.errorMessage = "Hatali SMS kodu"
                }
            }
        }
    }

    // MARK: - Uzaktan NFC

    func startRemoteNFC(birthDate: String, validDate: String, docNo: String) {
        callState = .nfcReading
        nfcStatusMessage = "Kimliğinizi okutunuz"

        // nfcMsgHandler NFC okuma thread'inden çağrılır; UI güncellemeleri MainActor'a taşınır.
        // WebRTC PeerConnection bu süre boyunca açık kalır — hiçbir şey kapatılmaz.
        manager.nfcMsgHandler = { [weak self] displayMessage in
            let msg: String
            let isTerminal: Bool

            switch displayMessage {
            case .requestPresentPassport:
                msg = "Kimliğinizi okutunuz"
                isTerminal = false
            case .authenticatingWithPassport(let progress):
                msg = "Doğrulanıyor... %\(progress)"
                isTerminal = false
            case .readingDataGroupProgress(_, let progress):
                msg = "Okunuyor... %\(progress)"
                isTerminal = false
            case .successfulRead:
                msg = "Okuma tamamlandı"
                isTerminal = true
            case .error:
                msg = "Okuma başarısız, lütfen tekrar deneyin"
                isTerminal = true
            default:
                msg = ""
                isTerminal = false
            }

            Task { @MainActor [weak self] in
                guard let self else { return }
                if !msg.isEmpty { self.nfcStatusMessage = msg }
                if isTerminal {
                    self.callState = .connected
                    self.nfcStatusMessage = ""
                }
            }

            return msg
        }

        manager.startRemoteNFC(birthDate: birthDate, validDate: validDate, docNo: docNo)
    }

    // MARK: - NFC Remote Edit (panel .editNfcProcess sonrası kaydet + yeniden başlat)

    func saveAndRestartRemoteNFC(serial: String, birth: String, valid: String) {
        manager.sdkBackInfo.idDocumentNumberMRZ = serial
        manager.sdkBackInfo.idBirthDateMRZ = birth.toMrzDate()
        manager.sdkBackInfo.idValidDateMRZ = valid.toMrzDate()
        showNFCEdit = false
        startRemoteNFC(
            birthDate: birth.toMrzDate(),
            validDate: valid.toMrzDate(),
            docNo: serial
        )
    }

    // MARK: - Reconnect Callbacks (LostConnectionView'dan dönen)

    func handleReconnectCompleted() {
        showLostConnection = false
        isTerminating = false
    }

    func handleReconnectCompletedWithStatus(
        isWaitingRoom: Bool,
        statusType: String?,
        appState: AppStateViewModel
    ) {
        showLostConnection = false
        isTerminating = false
        if isWaitingRoom {
            callState = .waiting
        } else {
            appState.pendingThankYouStatus = (statusType == "positive") ? .completed : .notCompleted
            callState = .ended
            appState.advanceToNextModule()
        }
    }

    // MARK: - Cleanup

    func cleanup() {
        manager.nfcMsgHandler = nil
    }
}

// MARK: - SDKSocketListener

extension CallScreenViewModel: SDKSocketListener {
    nonisolated func listenSocketMessage(message: SDKCallActions) {
        Task { @MainActor in
            // terminateCall işlemi devam ederken gelen diğer mesajlar görmezden gelinir.
            guard !isTerminating else { return }

            switch message {

            case .incomingCall:
                if manager.hideCallAnswerScreen {
                    acceptCall()
                } else {
                    callState = .ringing
                }

            case .comingSms:
                callState = .smsVerification

            case .startTransfer:
                // SDP answer alındı; 0.4s bekleyip kameraları göster (UIKit parity — RTCEAGLVideoView frame hesabının tamamlanması için gerekli).
                Task {
                    try? await Task.sleep(nanoseconds: 400_000_000)
                    await MainActor.run {
                        self.isLoading = false
                        self.callState = .connected
                    }
                }

            case .endCall:
                callState = .ended
                socketThankYouStatus = .notCompleted

            case .approveSms(let tan):
                _ = tan

            case .terminateCall(let reason, let statusType):
                isTerminating = true

                if reason == "TURN_DISCONNECTED" {
                    // ICE/TURN bağlantısı koptu; reconnect ekranı göster, ended'e geçme.
                    lostConnectionCallCompleted = false
                    showLostConnection = true
                    isTerminating = false
                } else {
                    let hasStatus: Bool = {
                        guard let type = statusType else { return false }
                        return type == "positive" || type == "negative" || type == "neutral"
                    }()

                    if hasStatus {
                        socketThankYouStatus = (statusType == "positive") ? .completed : .notCompleted
                        callState = .ended
                        callCompleted = true
                        isTerminating = false
                    } else {
                        // Bilinmeyen durum — reconnect dene.
                        lostConnectionCallCompleted = false
                        showLostConnection = true
                        isTerminating = false
                    }
                }

            case .imOffline:
                callState = .waiting
                errorMessage = "Temsilci cevrimdisi"

            case .updateQueue(let order, let minutes):
                queuePosition = order
                estimatedWait = minutes

            case .disableEndCallButton:
                endCallEnabled = false

            case .networkQuality(let quality):
                networkQuality = NetworkQuality(raw: quality)

            case .missedCall:
                callState = .ended
                socketThankYouStatus = .missedCall

            case .connectionErr:
                lostConnectionCallCompleted = false
                showLostConnection = true

            case .wrongSocketActionErr(let err):
                errorMessage = err

            case .subrejectedDismiss(let msg):
                _ = msg
                callState = .ended
                socketThankYouStatus = .notCompleted

            case .openNfcRemote(let birthDate, let validDate, let serialNo):
                startRemoteNFC(birthDate: birthDate, validDate: validDate, docNo: serialNo)

            case .editNfcProcess:
                nfcEditSerial = manager.sdkBackInfo.idDocumentNumberMRZ ?? ""
                nfcEditBirth = (manager.sdkBackInfo.idBirthDateMRZ ?? "").mrzToNormalDate()
                nfcEditValid = (manager.sdkBackInfo.idValidDateMRZ ?? "").mrzToNormalDate()
                showNFCEdit = true

            case .photoTaken(let msg):
                photoTakenToast = msg
                Task {
                    try? await Task.sleep(nanoseconds: 2_500_000_000)
                    await MainActor.run { self.photoTakenToast = nil }
                }

            default:
                break
            }
        }
    }
}
