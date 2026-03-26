//
//  OVDViewModel.swift
//  NewTest
//
//  OVD ekraninin ViewModel'i.
//  SDK: startFrontIdOcr, startBackIdOcr, uploadIdPhoto (OCRType kullanir)
//

import Foundation
import UIKit
import IdentifySDK

@MainActor
final class OVDViewModel: BaseModuleViewModel {

    // MARK: - Published State

    @Published var frontPhoto: UIImage? = nil
    @Published var backPhoto: UIImage? = nil
    @Published var ovdCaptured: Bool = false
    @Published var ocrResultText: String = ""
    @Published var canContinue: Bool = false

    // MARK: - OCR - On Yuz

    func processFrontOCR(image: UIImage, appState: AppStateViewModel) {
        isLoading = true
        manager.startFrontIdOcr(frontImg: image) { [weak self] resp, err in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                if let err {
                    self.errorMessage = err.errorMessages ?? "OCR hatasi"
                } else {
                    self.frontPhoto = image
                    // resp: FrontIdInfo (non-optional) – SDK property is also non-optional
                    self.ocrResultText = "On yuz okundu"
                    self.uploadFront(image: image, appState: appState)
                }
            }
        }
    }

    // MARK: - OCR - Arka Yuz

    func processBackOCR(image: UIImage, appState: AppStateViewModel) {
        isLoading = true
        manager.startBackIdOcr(frontImg: image) { [weak self] resp, err in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                if let err {
                    self.errorMessage = err.errorMessages ?? "OCR hatasi"
                } else {
                    self.backPhoto = image
                    // resp: BackIdInfo (non-optional) – SDK property is also non-optional
                    self.ocrResultText = "Arka yuz okundu"
                    self.uploadBack(image: image, appState: appState)
                }
            }
        }
    }

    // MARK: - Upload

    func uploadFront(image: UIImage, appState: AppStateViewModel) {
        manager.uploadIdPhoto(idPhoto: image, selfieType: .frontId) { [weak self] resp in
            Task { @MainActor in
                guard let self else { return }
                if resp.result == true {
                    self.ocrResultText = "On yukleme tamam"
                } else {
                    self.errorMessage = "On yukleme basarisiz"
                }
            }
        }
    }

    func uploadFrontOVD(image: UIImage, appState: AppStateViewModel) {
        manager.uploadIdPhoto(idPhoto: image, selfieType: .frontIdOvd) { [weak self] resp in
            Task { @MainActor in
                guard let self else { return }
                if resp.result == true {
                    self.ovdCaptured = true
                    self.ocrResultText = "OVD yakalama tamam"
                } else {
                    self.errorMessage = "OVD yukleme basarisiz"
                }
            }
        }
    }

    func uploadBack(image: UIImage, appState: AppStateViewModel) {
        manager.uploadIdPhoto(idPhoto: image, selfieType: .backId) { [weak self] resp in
            Task { @MainActor in
                guard let self else { return }
                if resp.result == true {
                    self.canContinue = true
                    self.ocrResultText = "Arka yukleme tamam"
                } else {
                    self.errorMessage = "Arka yukleme basarisiz"
                }
            }
        }
    }
}
