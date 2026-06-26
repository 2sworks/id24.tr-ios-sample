//
//  NfcHostViewModel.swift
//  NewTest
//
//  NFC modülü host VM'i. SDKNfcViewModel'i sarar; MRZ ön-doldurma (host config) + event log.
//

import SwiftUI
import IdentifySDK

@MainActor
final class NfcHostViewModel: HostModuleViewModel {
    let sdk = SDKNfcViewModel()

    override init() {
        super.init()
        bridge(sdk)
        sdk.onCompleted = { [weak self] in self?.log("nfc_completed"); self?.onCompleted?() }
        sdk.onSkipRequested = { [weak self] in self?.log("skip_requested") }
    }

    /// Host, MRZ alanlarını dışarıdan ön-doldurabilir (örn. kullanıcı profilinden).
    func prefill(serial: String, birth: String, valid: String) {
        sdk.serialNo = serial; sdk.birthDate = birth; sdk.validDate = valid
        log("mrz_prefilled")
    }

    var nfcStatus: String { sdk.nfcStatus }
    var nfcCompleted: Bool { sdk.nfcCompleted }
    var canContinue: Bool { sdk.canContinue }

    // TextField binding'leri için iki yönlü erişim:
    var serialNo: String { get { sdk.serialNo } set { sdk.serialNo = newValue } }
    var birthDate: String { get { sdk.birthDate } set { sdk.birthDate = newValue } }
    var validDate: String { get { sdk.validDate } set { sdk.validDate = newValue } }

    func startNFC() { log("start_nfc"); sdk.startNFC() }
}
