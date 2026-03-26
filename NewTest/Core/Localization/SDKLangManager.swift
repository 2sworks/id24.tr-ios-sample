//
//  SDKLangManager.swift
//  NewTest
//
//  Lokalizasyon yöneticisi.
//  SDKKeywords enum'u raw value olarak JSON key'ini taşır.
//  translate(_:) çağrısı aktif dile göre JSON'dan okur (önbellekli).
//

import Foundation
import IdentifySDK

// MARK: - SDKKeywords

public enum SDKKeywords: String {
    case connect                                = "Connect"
    case connectInfo                            = "ConnectInfo"
    case scanAgain                              = "ScanAgain"
    case scanInfo                               = "ScanInfo"
    case humanSmile                             = "HumanSmile"
    case humanSmileDescription                  = "HumanSmileDescription"
    case callTitle                              = "CallTitle"
    case callDescription                        = "CallDescription"
    case enterSmsCode                           = "EnterSmsCode"
    case waitingDesc1                           = "WaitingDesc1"
    case waitingDesc2                           = "WaitingDesc2"
    case thankU                                 = "ThankU"
    case board1                                 = "OnPage1"
    case board2                                 = "OnPage2"
    case board3                                 = "OnPage3"
    case board4                                 = "OnPage4"
    case board5                                 = "OnPage5"
    case nextPage                               = "NextPage"
    case backPage                               = "BackPage"
    case skipPage                               = "SkipPage"
    case continuePage                           = "Continue"
    case popSelfie                              = "PopSelfie"
    case popSmiley                              = "PopSmiley"
    case popVideo                               = "PopVideo"
    case popMRZ                                 = "PopMRZ"
    case popNFC                                 = "PopNFC"
    case popIdBackPhoto                         = "PopIdBackPhoto"
    case popIdFrontPhoto                        = "PopIdFrontPhoto"
    case signatureInfo                          = "SignatureInfo"
    case soundRecognitionInfo                   = "SoundRecognitionInfo"
    case coreError                              = "CoreError"
    case coreSuccess                            = "CoreSuccess"
    case wrongSMSCode                           = "WrongSMSCode"
    case coreOk                                 = "CoreOK"
    case newNfcFront                            = "NewNfcFront"
    case newNfcBack                             = "NewNfcBack"
    case newDocumentFront                       = "NewDocumentFront"
    case newDocumentBack                        = "NewDocumentBack"
    case nfcPassportScanInfo                    = "NfcPassportScanInfo"
    case nfcIDScanInfo                          = "NfcIDScanInfo"
    case nfcDocumentScanInfo                    = "NfcDocumentScanInfo"
    case nfcSuccess                             = "NfcSuccess"
    case nfcEditInfoTitle                       = "NfcEditInfoTitle"
    case nfcEditInfoDesc                        = "NfcEditInfoDesc"
    case coreDate                               = "CoreDate"
    case coreScan                               = "CoreScan"
    case coreInputError                         = "CoreInputError"
    case coreNfcDeviceError                     = "CoreNfcDeviceError"
    case soundRecogOk                           = "SoundRecogOk"
    case soundRecogFail                         = "SoundRecogFail"
    case faceNotFound                           = "FaceNotFound"
    case smilingFaceNotFound                    = "SmilingFaceNotFound"
    case coreUploadError                        = "CoreUploadError"
    case nfcInfoTitle                           = "NfcInfoTitle"
    case nfcInfoDesc                            = "NfcInfoDesc"
    case selfieInfoTitle                        = "SelfieInfoTitle"
    case selfieInfoDesc                         = "SelfieInfoDesc"
    case signatureInfoTitle                     = "SignatureInfoTitle"
    case signatureInfoDesc                      = "SignatureInfoDesc"
    case livenessInfoTitle                      = "LivenessInfoTitle"
    case livenessInfoDesc                       = "LivenessInfoDesc"
    case videoRecordInfoTitle                   = "VideoRecordInfoTitle"
    case videoRecordInfoDesc                    = "VideoRecordInfoDesc"
    case idCardInfoTitle                        = "IdCardInfoTitle"
    case idCardInfoDesc                         = "IdCardInfoDesc"
    case speechInfoTitle                        = "SpeechInfoTitle"
    case speechInfoText                         = "SpeechInfoText"
    case newIdCard                              = "NewIdCart"
    case passport                               = "Passport"
    case otherCards                             = "OtherCards"
    case scanType                               = "ScanType"
    case permissions                            = "Permissons"
    case permissionsText                        = "PermissionsText"
    case coreSend                               = "CoreSend"
    case coreCancel                             = "CoreCancel"
    case coreSettings                           = "CoreSettings"
    case corePlsWait                            = "CorePlsWait"
    case coreNoInternet                         = "CoreNoInternet"
    case coreNoInternetDesc                     = "CoreNoInternetDesc"
    case coreReConnect                          = "CoreReconnect"
    case corePermissionAlert                    = "CorePermissionAlert"
    case coreUpdate                             = "CoreUpdate"
    case coreBirthday                           = "CoreBirthday"
    case coreValidDay                           = "CoreValidDay"
    case coreSerialNumber                       = "CoreSerialNumber"
    case livenessStep1                          = "LivenessStep1"
    case livenessStep1Desc                      = "LivenessStep1Desc"
    case livenessStep2                          = "LivenessStep2"
    case livenessStep2Desc                      = "LivenessStep2Desc"
    case livenessStep3                          = "LivenessStep3"
    case livenessStep3Desc                      = "LivenessStep3Desc"
    case livenessStep4                          = "LivenessStep4"
    case livenessStep4Desc                      = "LivenessStep4Desc"
    case coreSkipAll                            = "CoreSkipAll"
    case corePullAgain                          = "CorePullAgain"
    case coreCityBtn                            = "CoreCityBtn"
    case coreCityDesc                           = "CoreCityDesc"
    case coreAddrDesc                           = "CoreAddrDesc"
    case coreInvoicePhoto                       = "CoreInvoicePhoto"
    case corePhotoBtn                           = "CorePhotoBtn"
    case corePhotoBtnPDF                        = "CorePhotoBtnPDF"
    case coreSignLang                           = "CoreSignLang"
    case coreDelSig                             = "CoreDelSig"
    case selfieIdentInfo1                       = "SelfieIdentInfoText"
    case selfieIdentInfo2                       = "SelfieIdentInfo2Text"
    case selfieIdentInfo3                       = "SelfieIdentInfo3Text"
    case recordVideo                            = "RecordVideo"
    case takePhoto                              = "TakePhoto"
    case idCardFrontPhoto                       = "IdCardFrontPhoto"
    case idCardBackPhoto                        = "IdCardBackPhoto"
    case docFrontPhoto                          = "DocFrontPhoto"
    case docBackPhoto                           = "DocBackPhoto"
    case passportPhoto                          = "PassportPhoto"
    case anotherUserInToTheRoom                 = "AnotherUserInToTheRoom"
    case loadingFirstModule                     = "LoadingFirstModule"
    case waitingDesc1Live                       = "WaitingDesc1Live"
    case waitingDesc2Live                       = "WaitingDesc2Live"
    case waitingDesc3Live                       = "WaitingDesc3Live"
    case callScreenWaitRepresentative           = "CallScreenWaitRepresentative"
    case docType                                = "DocType"
    case livenessLookCam                        = "LivenessLookCam"
    case nfcKeyErrTitle                         = "NfcKeyErrTitle"
    case nfcKeyErrSubTitle                      = "NfcKeyErrSubTitle"
    case nfcSerialNo                            = "NfcSerialNo"
    case nfcBirthDate                           = "NfcBirthDate"
    case nfcExpDate                             = "NfcExpDate"
    case nfcStart                               = "NfcStart"
    case coreReconnecting                       = "CoreReconnecting"
    case wrongFrontSide                         = "WrongFrontSide"
    case wrongBackSide                          = "WrongBackSide"
    case missedCallTitle                        = "MissedCallTitle"
    case missedCallSubTitle                     = "MissedCallSubTitle"
    case checkMyConn                            = "CheckMyConn"
    case idNear                                 = "IdNear"
    case ownAuth                                = "OwnAuth"
    case lightSoundCont                         = "LightSoundCont"
    case connectionGood                         = "ConnectionGood"
    case connectionSpeedSuccess                 = "ConnectionSpeedSuccess"
    case prepareCam                             = "PrepareCam"
    case prepareMic                             = "PrepareMic"
    case prepareSpeech                          = "PrepareSpeech"
    case scanHoldOn                             = "ScanHoldOn"
    case scanCloser                             = "ScanCloser"
    case scanGoAway                             = "ScanGoAway"
    case scanPrepareList                        = "ScanPrepareList"
    case identifyFailedTitle                    = "IdentFailedTitle"
    case identifyFailedDesc                     = "IdentFailedDesc"
    case activeSelfieWarn                       = "ActiveSelfieWarn"
    case activeSelfieExit                       = "ActiveSelfieExit"
    case activeNfcWarn                          = "ActiveNfcWarn"
    case activeNfcExit                          = "ActiveNfcExit"
    case activeOcrWarn                          = "ActiveOcrWarn"
    case activeOcrExit                          = "ActiveOcrExit"
    case scanErrDegree                          = "ScanErrDegree"
    case addressPdfErrorTitle                   = "AddressPdfErrorTitle"
    case addressPdfErrorMessage                 = "AddressPdfErrorMessage"
    case livenessRecordingUploading             = "LivenessRecordingUploading"
    case livenessRecordingRetryAction           = "LivenessRecordingRetryAction"
    case livenessRecordingPermissionsMissing    = "LivenessRecordingPermissionsMissing"
    case livenessRecordingPermissionsMissingToast = "LivenessRecordingPermissionsMissingToast"
    case livenessRecordingFailedToStart         = "LivenessRecordingFailedToStart"
    case livenessRecordingFailedToStop          = "LivenessRecordingFailedToStop"
    case livenessRecordingFailedToast           = "LivenessRecordingFailedToast"
    case livenessRecordingFailedToUpload        = "LivenessRecordingFailedToUpload"
    case livenessRecordingSizeTooLarge          = "LivenessRecordingSizeTooLarge"
    case livenessRecordingInterrupted           = "LivenessRecordingInterrupted"
    case ovdScanFrontSide                       = "OvdScanFrontSide"
    case ovdFrontAlignGuide                     = "OvdFrontAlignGuide"
    case ovdFrontRetryAlign                     = "OvdFrontRetryAlign"
    case ovdFrontRetryAlignSpeech               = "OvdFrontRetryAlignSpeech"
    case ovdVerificationCompleted               = "OvdVerificationCompleted"
    case ovdVerificationCompletedSpeech         = "OvdVerificationCompletedSpeech"
    case ovdFlashMoveCard                       = "OvdFlashMoveCard"
    case ovdRotateRainbowSpeech                 = "OvdRotateRainbowSpeech"
    case ovdSavedAlignBack                      = "OvdSavedAlignBack"
    case ovdPhotoTaken                          = "OvdPhotoTaken"
    case ovdScanBackSide                        = "OvdScanBackSide"
    case ovdFrontSavedAlignBack                 = "OvdFrontSavedAlignBack"
    case ovdRetryMoveCard                       = "OvdRetryMoveCard"
    case ovdRotateRainbowRetrySpeech            = "OvdRotateRainbowRetrySpeech"
    case ovdFrontSaved                          = "OvdFrontSaved"
    case ovdFrontChecking                       = "OvdFrontChecking"
    case ovdChecking                            = "OvdChecking"
    case ovdBackChecking                        = "OvdBackChecking"
    case ovdFrontReadyCapturing                 = "OvdFrontReadyCapturing"
    case ovdFrontAlignedHold                    = "OvdFrontAlignedHold"
    case ovdBackAlignGuide                      = "OvdBackAlignGuide"
    case ovdBackMrzNotRead                      = "OvdBackMrzNotRead"
    case ovdBackReadyCapturing                  = "OvdBackReadyCapturing"
    case ovdBackAlignedHold                     = "OvdBackAlignedHold"
    case ovdTooWhiteTilt                        = "OvdTooWhiteTilt"
    case ovdGlareCaptured                       = "OvdGlareCaptured"
}

// MARK: - SDKLangManager

final class SDKLangManager {

    static let shared = SDKLangManager()
    init() {}

    let sdkManager = IdentifyManager.shared

    // Dil başına JSON önbelleği
    private var cache: [String: [String: String]] = [:]

    // MARK: - Public API

    func translate(_ key: SDKKeywords) -> String {
        let filename = jsonFilename(for: sdkManager.sdkLang ?? .eng)
        let dict = loadJson(filename: filename)
        return dict[key.rawValue] ?? key.rawValue
    }

    /// Eski UIKit çağrı stiliyle uyumluluk (translate(key: .xxx))
    func translate(key: SDKKeywords) -> String {
        return translate(key)
    }

    // MARK: - Private

    private func jsonFilename(for lang: SDKLang) -> String {
        switch lang {
        case .de:  return "GERMAN"
        case .tr:  return "TURKISH"
        case .az:  return "AZERI"
        case .ru:  return "RUSSIAN"
        default:   return "ENGLISH"
        }
    }

    private func loadJson(filename: String) -> [String: String] {
        if let cached = cache[filename] { return cached }
        guard
            let url = Bundle.main.url(forResource: filename, withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String]
        else { return [:] }
        cache[filename] = dict
        return dict
    }
}

// MARK: - SwiftUI Extensions

extension SDKKeywords {
    /// Aktif SDK diline göre lokalize edilmiş metni döndürür.
    /// Kullanım: SDKKeywords.connect.localized
    var localized: String {
        SDKLangManager.shared.translate(self)
    }
}

extension String {
    /// SDKKeywords ile aynı kolaylığı String interpolation için sağlar.
    /// Kullanım: "\(SDKKeywords.connect)"  →  lokalize metin
    init(_ key: SDKKeywords) {
        self = SDKLangManager.shared.translate(key)
    }
}

// MARK: - SwiftUI Text shorthand

import SwiftUI

extension Text {
    /// Lokalize Text oluşturur.
    /// Kullanım: Text(.connect)
    init(_ key: SDKKeywords) {
        self.init(SDKLangManager.shared.translate(key))
    }
}
