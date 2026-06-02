//
//  IdCardViewModel.swift
//  NewTest
//
//  Kimlik karti tarama ekraninin ViewModel'i.
//  SDK: startFrontIdOcr, startBackIdOcr, uploadIdPhoto, startPassportMrzKey
//

import Foundation
import UIKit
import IdentifySDK

enum IdCardSide: Hashable {
    case front, back, passport
}

@MainActor
final class IdCardViewModel: BaseModuleViewModel {

    // MARK: - Published State

    @Published var frontPhoto: UIImage? = nil
    @Published var backPhoto: UIImage? = nil
    @Published var currentSide: IdCardSide = .front
    @Published var resultText: String = ""
    @Published var canContinue: Bool = false

    var allowedCardTypes: [CardType] {
        manager.allowedCardType
    }

    var nfcRetryExceeded: Bool {
        manager.tryedNfcComparisonCount >= 2
    }

    // MARK: - Kart Tipi Seçimi

    func selectCardType(_ type: CardType) {
        manager.selectedCardType = type
    }

    // MARK: - OCR - On Yuz

    func scanFront(image: UIImage, appState: AppStateViewModel) {
        isLoading = true
        resultText = ""
        manager.startFrontIdOcr(frontImg: image) { [weak self] resp, err in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                if let err {
                    self.errorMessage = err.errorMessages ?? "OCR hatasi"
                } else {
                    self.frontPhoto = image
                    if self.manager.selectedCardType == .passport {
                        // Pasaport: startFrontIdOcr sdkFrontInfo'yu doldurur,
                        // ardından MRZ key extraction zinciri başlatılır.
                        self.scanPassport(image: image,
                                          comingData: self.manager.sdkFrontInfo,
                                          appState: appState)
                    } else {
                        self.resultText = "On yuz okundu"
                        self.currentSide = .back
                    }
                }
            }
        }
    }

    // MARK: - OCR - Arka Yuz

    func scanBack(image: UIImage, appState: AppStateViewModel) {
        isLoading = true
        resultText = ""
        manager.startBackIdOcr(frontImg: image) { [weak self] resp, err in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                if let err {
                    self.errorMessage = err.errorMessages ?? "OCR hatasi"
                } else {
                    self.backPhoto = image
                    // resp: BackIdInfo (non-optional) – SDK property is also non-optional
                    self.uploadPhoto(image: image, type: .backId, appState: appState)
                }
            }
        }
    }

    // MARK: - Upload

    func uploadPhoto(image: UIImage, type: OCRType, appState: AppStateViewModel) {
        isLoading = true
        manager.uploadIdPhoto(idPhoto: image, selfieType: type) { [weak self] webResp in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                if webResp.result == true {
                    self.resultText = "Yukleme basarili"
                    self.canContinue = true
                } else {
                    self.manager.tryedOcrComparisonCount += 1
                    if self.manager.tryedOcrComparisonCount >= self.manager.ocrComparisonCount {
                        if self.manager.activeComparisonResultSkipModule == "1" {
                            appState.skipCurrentModule()
                        } else {
                            self.errorMessage = "Karsilastirma basarisiz"
                        }
                    } else {
                        self.errorMessage = "Tekrar deneyin"
                    }
                }
            }
        }
    }

    // MARK: - Pasaport MRZ

    func scanPassport(image: UIImage, comingData: FrontIdInfo, appState: AppStateViewModel) {
        isLoading = true
        manager.startPassportMrzKey(frontImg: image, cominData: comingData) { [weak self] idInfo, err in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                if let err {
                    self.errorMessage = err.errorMessages ?? "Pasaport hatasi"
                } else {
                    self.frontPhoto = image
                    self.resultText = "Pasaport okundu"
                    self.canContinue = true
                }
            }
        }
    }
}
