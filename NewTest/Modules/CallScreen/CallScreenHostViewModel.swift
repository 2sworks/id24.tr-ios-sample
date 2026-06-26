//
//  CallScreenHostViewModel.swift
//  NewTest
//
//  Görüşme modülü host VM'i. SDKCallScreenViewModel'i sarar; çağrı olaylarını loglar.
//

import SwiftUI
import IdentifySDK

@MainActor
final class CallScreenHostViewModel: HostModuleViewModel {
    let sdk = SDKCallScreenViewModel()

    override init() {
        super.init()
        bridge(sdk)
    }

    var callStateText: String {
        switch sdk.callState {
        case .waiting:         return "bekliyor"
        case .ringing:         return "çalıyor"
        case .connected:       return "görüşmede"
        case .smsVerification: return "SMS doğrulama"
        case .nfcReading:      return "NFC okuma"
        case .ended:           return "bitti"
        }
    }
    var queuePosition: String { sdk.queuePosition }
    var isSMSCodeValid: Bool { sdk.isSMSCodeValid }
    var smsCode: String { get { sdk.smsCode } set { sdk.smsCode = newValue } }

    func acceptCall() { log("accept_call"); sdk.acceptCall() }
    func verifySMS() { log("verify_sms"); sdk.verifySMS() }
    func terminate(_ coordinator: SDKFlowCoordinator) { log("terminate_call"); sdk.terminateCall(coordinator: coordinator) }
}
