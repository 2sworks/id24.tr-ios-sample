//
//  ThankYouViewModel.swift
//  NewTest
//
//  Tamamlanma ekraninin ViewModel'i.
//  SDK: kycIsCompleted, isSelfieIdent
//

import Foundation
import IdentifySDK

@MainActor
final class ThankYouViewModel: BaseModuleViewModel {

    // MARK: - Published State

    /// KYC tamamlandi mi
    @Published private(set) var kycCompleted: Bool = false

    /// Selfie identification mi (kamera ile mi gerceklesti)
    @Published private(set) var isSelfieIdentification: Bool = false

    /// Tamamlanma durumu (UIKit CallStatusEnum karsiligi)
    @Published var completeStatus: ThankYouStatus = .completed

    // MARK: - Init

    override init() {
        super.init()
        kycCompleted = manager.kycIsCompleted
        isSelfieIdentification = manager.isSelfieIdent
        // SDK kycIsCompleted = true olarak isaretle (UIKit tarafi ile ayni)
        manager.kycIsCompleted = true
    }
}

// MARK: - ThankYouStatus (UIKit CallStatus karsiligi)

enum ThankYouStatus {
    case completed      // Basarili tamamlama
    case missedCall     // Cagri cevapsiz
    case notCompleted   // Tamamlanamadi
}
