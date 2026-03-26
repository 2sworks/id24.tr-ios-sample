//
//  SelfieViewModel.swift
//  NewTest
//
//  Selfie ekraninin ViewModel'i.
//  SDK: detectHumanFace, uploadIdPhoto(.selfie) -> OCRType
//

import Foundation
import UIKit
import IdentifySDK

@MainActor
final class SelfieViewModel: BaseModuleViewModel {

    // MARK: - Published State

    @Published var selfieImage: UIImage? = nil
    @Published private(set) var faceDetected: Bool = false
    @Published private(set) var canContinue: Bool = false
    @Published private(set) var resultText: String = ""

    // MARK: - Selfie Isle

    func processSelfie(image: UIImage, appState: AppStateViewModel) {
        selfieImage = image
        isLoading = true
        resultText = ""

        manager.detectHumanFace(comingPhoto: image) { [weak self] isHuman in
            Task { @MainActor in
                guard let self else { return }
                if isHuman {
                    self.faceDetected = true
                    self.uploadSelfie(image: image, appState: appState)
                } else {
                    self.isLoading = false
                    self.errorMessage = "Yuz tespit edilemedi, tekrar deneyin"
                }
            }
        }
    }

    private func uploadSelfie(image: UIImage, appState: AppStateViewModel) {
        manager.uploadIdPhoto(idPhoto: image, selfieType: .selfie) { [weak self] webResp in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                if webResp.result == true {
                    self.canContinue = true
                    self.resultText = "Selfie yuklendi"
                } else {
                    self.manager.tryedSelfieComparisonCount += 1
                    if self.manager.tryedSelfieComparisonCount >= self.manager.selfieComparisonCount {
                        if self.manager.activeComparisonResultSkipModule == "1" {
                            appState.skipCurrentModule()
                        } else {
                            self.errorMessage = "Karsilastirma basarisiz"
                        }
                    } else {
                        self.errorMessage = "Tekrar deneyin (\(self.manager.tryedSelfieComparisonCount)/\(self.manager.selfieComparisonCount))"
                    }
                }
            }
        }
    }
}
