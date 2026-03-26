//
//  LivenessViewModel.swift
//  NewTest
//
//  Canlilik testi ViewModel'i.
//  SDK: getNextLivenessTest, uploadIdPhoto (OCRType), uploadLivenessVideo, resetLivenessTest
//
//  LivenessTestStep cases: .turnLeft, .turnRight, .blinkEyes, .smile, .completed
//  uploadIdPhoto selfieType: OCRType (.selfie, .headToLeft, .headToRight, .blinking, .smiling)
//

import Foundation
import UIKit
import IdentifySDK

@MainActor
final class LivenessViewModel: BaseModuleViewModel {

    // MARK: - Published State

    @Published private(set) var currentStep: LivenessTestStep? = nil
    @Published private(set) var stepInstruction: String = ""
    @Published private(set) var allStepsCompleted: Bool = false

    var isRecordingEnabled: Bool { manager.livenessRecordingEnabled }
    var maxVideoSize: Int { manager.requestMaxBodySize }

    // MARK: - Adim Bayraklari (ARSCNViewDelegate icin)

    var allowBlink:  Bool = false
    var allowSmile:  Bool = false
    var allowLeft:   Bool = false
    var allowRight:  Bool = false

    // MARK: - Init

    override init() {
        super.init()
        fetchNextStep()
    }

    // MARK: - Adim Yonetimi

    func fetchNextStep() {
        manager.getNextLivenessTest { [weak self] nextStep, completed in
            Task { @MainActor in
                guard let self else { return }
                if completed == true {
                    self.allStepsCompleted = true
                    self.stepInstruction = "Canlilik testi tamamlandi"
                } else {
                    self.currentStep = nextStep
                    self.updateStepFlags(nextStep)
                    self.updateInstruction(nextStep)
                }
            }
        }
    }

    private func updateStepFlags(_ step: LivenessTestStep?) {
        allowBlink = step == .blinkEyes
        allowSmile = step == .smile
        allowLeft  = step == .turnLeft
        allowRight = step == .turnRight
    }

    private func updateInstruction(_ step: LivenessTestStep?) {
        switch step {
        case .blinkEyes:  stepInstruction = "Gozlerinizi kirpin"
        case .smile:      stepInstruction = "Gumseyiniz"
        case .turnLeft:   stepInstruction = "Basini sola cevirin"
        case .turnRight:  stepInstruction = "Basini saga cevirin"
        default:          stepInstruction = ""
        }
    }

    // MARK: - Frame Yukleme

    func uploadFrame(image: UIImage, appState: AppStateViewModel) {
        guard let step = currentStep else { return }
        let selfieType: OCRType
        switch step {
        case .blinkEyes:  selfieType = .blinking
        case .smile:      selfieType = .smiling
        case .turnLeft:   selfieType = .headToLeft
        case .turnRight:  selfieType = .headToRight
        default:          selfieType = .selfie
        }
        manager.uploadIdPhoto(idPhoto: image, selfieType: selfieType) { [weak self] resp in
            Task { @MainActor in
                guard let self else { return }
                if resp.result == true {
                    self.fetchNextStep()
                } else {
                    self.errorMessage = "Adim basarisiz, yeniden denenecek"
                    self.manager.resetLivenessTest()
                    self.fetchNextStep()
                }
            }
        }
    }

    // MARK: - Video Yukleme

    func uploadVideo(videoData: Data, appState: AppStateViewModel) {
        guard isRecordingEnabled else {
            appState.advanceToNextModule()
            return
        }
        isLoading = true
        manager.uploadLivenessVideo(videoData: videoData) { [weak self] response, error in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                if let error {
                    self.errorMessage = error.errorMessages ?? "Video yukleme hatasi"
                } else {
                    appState.advanceToNextModule()
                }
            }
        }
    }

    // MARK: - Sifirlama

    func resetTest() {
        manager.resetLivenessTest()
        allStepsCompleted = false
        fetchNextStep()
    }
}
