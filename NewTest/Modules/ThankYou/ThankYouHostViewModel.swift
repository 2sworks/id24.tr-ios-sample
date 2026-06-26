//
//  ThankYouHostViewModel.swift
//  NewTest
//
//  Sonuç modülü host VM'i. SDKThankYouViewModel'i sarar (terminal); sonucu loglar.
//

import SwiftUI
import IdentifySDK

@MainActor
final class ThankYouHostViewModel: HostModuleViewModel {
    let sdk: SDKThankYouViewModel

    /// Host, sonuç statüsünü dışarıdan verebilir (örn. görüşme sonucuna göre).
    init(status: ThankYouStatus = .completed) {
        self.sdk = SDKThankYouViewModel(status: status)
        super.init()
        bridge(sdk)
        log("result_shown")
    }

    var kycCompleted: Bool { sdk.kycCompleted }
}
