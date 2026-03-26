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
    case waiting, ringing, connected, smsVerification, ended
}

// MARK: - CallScreenViewModel

@MainActor
final class CallScreenViewModel: BaseModuleViewModel {

    // MARK: - Published State

    @Published private(set) var callState: CallState = .waiting
    @Published private(set) var queuePosition: String = ""
    @Published private(set) var estimatedWait: String = ""
    @Published private(set) var networkQualityText: String = ""
    @Published var smsCode: String = ""
    @Published private(set) var endCallEnabled: Bool = true
    @Published private(set) var callCompleted: Bool = false

    var isSMSCodeValid: Bool { smsCode.count == 6 }

    // MARK: - WebRTC Views

    var remoteVideoView: UIView? { manager.webRTCClient?.remoteVideoView() }
    var localVideoView: UIView? { manager.webRTCClient?.localVideoView() }

    // MARK: - Init

    override init() {
        super.init()
    }

    // MARK: - Cagriyi Kabul Et

    func acceptCall() {
        manager.acceptCall { [weak self] connected, errMsg, sdpConnOk in
            Task { @MainActor in
                guard let self else { return }
                if connected == true {
                    self.callState = .connected
                } else {
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
        manager.startRemoteNFC(birthDate: birthDate, validDate: validDate, docNo: docNo)
    }
}

// MARK: - SDKSocketListener

extension CallScreenViewModel: SDKSocketListener {
    nonisolated func listenSocketMessage(message: SDKCallActions) {
        Task { @MainActor in
            switch message {

            case .incomingCall:
                callState = .ringing

            case .comingSms:
                callState = .smsVerification

            case .endCall:
                callState = .ended

            case .approveSms(let tan):
                // SDK Bool donduruyor, tan kodu AppState'den alinmali
                // tan parametresi burada Bool tipindedir
                _ = tan

            case .terminateCall(_, _):
                callState = .ended
                callCompleted = true

            case .imOffline:
                errorMessage = "Temsilci cevrimdisi"

            case .updateQueue(let order, let minutes):
                queuePosition = order
                estimatedWait = minutes

            case .disableEndCallButton:
                endCallEnabled = false

            case .networkQuality(let quality):
                networkQualityText = quality

            case .missedCall:
                callState = .ended
                errorMessage = "Cagri cevapsiz kaldi"

            case .connectionErr:
                errorMessage = "Baglanti hatasi"

            case .wrongSocketActionErr(let err):
                errorMessage = err

            case .subrejectedDismiss(let msg):
                _ = msg
                callState = .ended

            case .openNfcRemote(let birthDate, let validDate, let serialNo):
                startRemoteNFC(birthDate: birthDate, validDate: validDate, docNo: serialNo)

            default:
                break
            }
        }
    }
}
