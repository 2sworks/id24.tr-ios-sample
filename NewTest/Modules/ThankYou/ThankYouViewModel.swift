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

    @Published private(set) var kycCompleted: Bool = false
    @Published private(set) var isSelfieIdentification: Bool = false
    @Published private(set) var completeStatus: ThankYouStatus = .completed

    // MARK: - Init

    init(status: ThankYouStatus = .completed) {
        super.init()
        completeStatus = status
        kycCompleted = manager.kycIsCompleted
        isSelfieIdentification = manager.isSelfieIdent
        manager.kycIsCompleted = true
    }
}

// MARK: - ThankYouStatus

enum ThankYouStatus: Hashable {
    case completed      // Basarili tamamlama
    case missedCall     // Cagri cevapsiz
    case notCompleted   // Tamamlanamadi
}
