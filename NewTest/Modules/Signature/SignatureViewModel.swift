//
//  SignatureViewModel.swift
//  NewTest
//
//  Imza ekraninin ViewModel'i.
//  SDK: uploadIdPhoto(.signature) -> OCRType
//

import Foundation
import UIKit
import IdentifySDK

@MainActor
final class SignatureViewModel: BaseModuleViewModel {

    // MARK: - Published State

    @Published var signatureDrawn: Bool = false
    @Published private(set) var uploadCompleted: Bool = false

    // MARK: - Imza Olaylari

    func signatureDidDraw() {
        signatureDrawn = true
    }

    func clearSignature() {
        signatureDrawn = false
        uploadCompleted = false
        errorMessage = nil
    }

    // MARK: - Upload

    func uploadSignature(image: UIImage, appState: AppStateViewModel) {
        isLoading = true
        manager.uploadIdPhoto(idPhoto: image, selfieType: .signature) { [weak self] webResp in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                if webResp.result == true {
                    self.uploadCompleted = true
                    appState.advanceToNextModule()
                } else {
                    self.errorMessage = "Imza yuklenemedi"
                }
            }
        }
    }
}
