//
//  SelfieHostViewModel.swift
//  NewTest
//
//  Selfie modülü için HOST tarafı ViewModel (flagship örnek).
//  SDK'nın iş mantığını (SDKSelfieViewModel) sarar ve DIŞARIDAN eklenebilecekleri gösterir:
//    • maxAttempts        → deneme limiti (host config)
//    • customValidation   → SDK'ya gitmeden önce kendi doğrulaman (enjekte)
//    • events / onEvent   → analytics/olay kaydı (enjekte)
//

import SwiftUI
import IdentifySDK

@MainActor
final class SelfieHostViewModel: HostModuleViewModel {

    /// SDK iş mantığı.
    let sdk = SDKSelfieViewModel()

    // MARK: Dışarıdan eklenen yapılandırma / davranış
    var maxAttempts: Int = 3
    var customValidation: ((UIImage) -> Bool)?

    override init() {
        super.init()
        bridge(sdk)                                  // SDK state'ini View'a yansıt
        sdk.onSkipRequested = { [weak self] in self?.log("skip_requested") }
    }

    // MARK: SDK state'ini View'a aç
    var faceDetected: Bool { sdk.faceDetected }
    var canContinue: Bool { sdk.canContinue }
    var resultText: String { sdk.resultText }
    var reachedAttemptLimit: Bool { attemptCount >= maxAttempts }

    // MARK: Host iş akışı (SDK + ekstralar)
    func capture(_ image: UIImage) {
        guard !reachedAttemptLimit else { log("attempt_limit_reached"); return }
        attemptCount += 1
        log("selfie_attempt_\(attemptCount)")
        if let customValidation, customValidation(image) == false {
            log("custom_validation_failed")
            return
        }
        sdk.processSelfie(image: image)              // SDK iş mantığı
    }
}
