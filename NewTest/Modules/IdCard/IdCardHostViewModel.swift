//
//  IdCardHostViewModel.swift
//  NewTest
//
//  Kimlik modülü host VM'i. SDKIdCardViewModel'i sarar; tarama olaylarını loglar.
//

import SwiftUI
import IdentifySDK

@MainActor
final class IdCardHostViewModel: HostModuleViewModel {
    
    let sdk = SDKIdCardViewModel()

    override init() {
        super.init()
        bridge(sdk)
        sdk.onSkipRequested = { [weak self] in self?.log("skip_requested") }
    }

    var currentSideText: String { sdk.currentSide == .front ? "ön" : "arka" }
    var resultText: String { sdk.resultText }
    var canContinue: Bool { sdk.canContinue }

    func scanFront(_ image: UIImage) { log("scan_front"); sdk.scanFront(image: image) }
    func scanBack(_ image: UIImage)  { log("scan_back");  sdk.scanBack(image: image) }
}
