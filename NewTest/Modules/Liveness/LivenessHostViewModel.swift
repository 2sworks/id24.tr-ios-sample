//
//  LivenessHostViewModel.swift
//  NewTest
//
//  Canlılık modülü host VM'i. SDKLivenessViewModel'i sarar; adım olaylarını loglar.
//

import SwiftUI
import IdentifySDK

@MainActor
final class LivenessHostViewModel: HostModuleViewModel {
    let sdk = SDKLivenessViewModel()

    override init() {
        super.init()
        bridge(sdk)
        sdk.onCompleted = { [weak self] in self?.log("liveness_completed"); self?.onCompleted?() }
    }

    var stepInstruction: String { sdk.stepInstruction }
    var allStepsCompleted: Bool { sdk.allStepsCompleted }

    func start() { log("fetch_first_step"); sdk.fetchNextStep() }
    func nextStep() { log("fetch_next_step"); sdk.fetchNextStep() }
    func sendFrame(_ image: UIImage) { log("upload_frame"); sdk.uploadFrame(image: image) }
}
