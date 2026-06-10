//
//  IdentifyNavigationFlow.swift
//  NewTest
//
//  Tüm navigasyon rotalarını tanımlar.
//  AppNavigationCoordinator bu enum üzerinden push/pop yapar.
//

import Foundation
import IdentifySDK

// MARK: - IdentifyNavigationFlow

enum IdentifyNavigationFlow: Hashable {
    case login
    case prepare
    case selfie
    case idCard
    case idCardOVD
    case nfc
    case liveness
    case speech
    case addressConfirm
    case signature
    case videoRecorder
    case callScreen
    case thankYou
    case idCardScanner(IdCardSide)
}

// MARK: - SdkModules → IdentifyNavigationFlow

extension SdkModules {
    /// SDK modülünü navigasyon rotasına dönüştürür.
    var navigationFlow: IdentifyNavigationFlow {
        switch self {
        case .login:             return .login
        case .prepare:           return .prepare
        case .idCard:            return .idCard
        case .idcard_w_ovd:      return .idCardOVD
        case .nfc:               return .nfc
        case .livenessDetection: return .liveness
        case .speech:            return .speech
        case .addressConf:       return .addressConfirm
        case .signature:         return .signature
        case .videoRecord:       return .videoRecorder
        case .selfie:                return .selfie
        case .selfieWithLiveness:    return .selfie
        case .waitScreen:            return .callScreen
        case .thankU:                return .thankYou
        }
    }
}
