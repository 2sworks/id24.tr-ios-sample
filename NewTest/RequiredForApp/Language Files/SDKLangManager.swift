//
//  SDKLanguageManager.swift
//  NewTest
//
//  Created by Emir Beytekin on 19.01.2023.
//

import Foundation
import IdentifySDK

class SDKLangManager:NSObject {
    
    override init() {}
    
    let sdkManager = IdentifyManager.shared
    public static let shared = SDKLangManager.init()
    
    func readKey(key: String) -> String {
        switch sdkManager.sdkLang {
            case .de:
                return loadJson(filename: "GERMAN")?[key] ?? ""
            case .eng:
                return loadJson(filename: "ENGLISH")?[key] ?? ""
            case .tr:
                return loadJson(filename: "TURKISH")?[key] ?? ""
            case .az:
                return loadJson(filename: "AZERI")?[key] ?? ""
            case .ru:
                return loadJson(filename: "RUSSIAN")?[key] ?? ""
            default:
                return ""
        }
    }
    
    func loadJson(filename fileName: String) -> [String: String]? {
        if let url = Bundle.main.url(forResource: fileName, withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let object = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                if let dictionary = object as? [String: String] {
                    return dictionary
                }
            } catch {
                print("Error!! Unable to parse  \(fileName).json")
            }
        }
        return nil
    }
    
}

extension SDKLangManager {
    
    public func translate(key: SDKKeywords) -> String {
        switch key {
            case .connect:
                return self.readKey(key: "Connect")
            case .connectInfo:
                return self.readKey(key: "ConnectInfo")
            case .scanAgain:
                return self.readKey(key: "ScanAgain")
            case .scanInfo:
                return self.readKey(key: "ScanInfo")
            case .humanSmile:
                return self.readKey(key: "HumanSmile")
            case .humanSmileDescription:
                return self.readKey(key: "HumanSmileDescription")
            case .callTitle:
                return self.readKey(key: "CallTitle")
            case .callDescription:
                return self.readKey(key: "CallDescription")
            case .enterSmsCode:
                return self.readKey(key: "EnterSmsCode")
            case .waitingDesc1:
                return self.readKey(key: "WaitingDesc1")
            case .waitingDesc2:
                return self.readKey(key: "WaitingDesc2")
            case .thankU:
                return self.readKey(key: "ThankU")
            case .board1:
                return self.readKey(key: "OnPage1")
            case .board2:
                return self.readKey(key: "OnPage2")
            case .board3:
                return self.readKey(key: "OnPage3")
            case .board4:
                return self.readKey(key: "OnPage4")
            case .board5:
                return self.readKey(key: "OnPage5")
            case .nextPage:
                return self.readKey(key: "NextPage")
            case .backPage:
                return self.readKey(key: "BackPage")
            case .skipPage:
                return self.readKey(key: "SkipPage")
            case .continuePage:
                return self.readKey(key: "Continue")
            case .popSelfie:
                return self.readKey(key: "PopSelfie")
            case .popSmiley:
                return self.readKey(key: "PopSmiley")
            case .popVideo:
                return self.readKey(key: "PopVideo")
            case .popMRZ:
                return self.readKey(key: "PopMRZ")
            case .popNFC:
                return self.readKey(key: "PopNFC")
            case .popIdBackPhoto:
                return self.readKey(key: "PopIdBackPhoto")
            case .popIdFrontPhoto:
                return self.readKey(key: "PopIdFrontPhoto")
            case .signatureInfo:
                return self.readKey(key: "SignatureInfo")
            case .soundRecognitionInfo:
                return self.readKey(key: "SoundRecognitionInfo")
            case .coreError:
                return self.readKey(key: "CoreError")
            case .coreSuccess:
                return self.readKey(key: "CoreSuccess")
            case .wrongSMSCode:
                return self.readKey(key: "WrongSMSCode")
            case .coreOk:
                return self.readKey(key: "CoreOK")
            case .newNfcFront:
                return self.readKey(key: "NewNfcFront")
            case .newNfcBack:
                return self.readKey(key: "NewNfcBack")
            case .newDocumentFront:
                return self.readKey(key: "NewDocumentFront")
            case .newDocumentBack:
                return self.readKey(key: "NewDocumentBack")
            case .nfcPassportScanInfo:
                return self.readKey(key: "NfcPassportScanInfo")
            case .nfcIDScanInfo:
                return self.readKey(key: "NfcIDScanInfo")
            case .nfcDocumentScanInfo:
                return self.readKey(key: "NfcDocumentScanInfo")
            case .nfcSuccess:
                return self.readKey(key: "NfcSuccess")
            case .nfcEditInfoTitle:
                return self.readKey(key: "NfcEditInfoTitle")
            case .nfcEditInfoDesc:
                return self.readKey(key: "NfcEditInfoDesc")
            case .coreDate:
                return self.readKey(key: "CoreDate")
            case .coreScan:
                return self.readKey(key: "CoreScan")
            case .coreInputError:
                return self.readKey(key: "CoreInputError")
            case .coreNfcDeviceError:
                return self.readKey(key: "CoreNfcDeviceError")
            case .soundRecogOk:
                return self.readKey(key: "SoundRecogOk")
            case .soundRecogFail:
                return self.readKey(key: "SoundRecogFail")
            case .faceNotFound:
                return self.readKey(key: "FaceNotFound")
            case .smilingFaceNotFound:
                return self.readKey(key: "SmilingFaceNotFound")
            case .coreUploadError:
                return self.readKey(key: "CoreUploadError")
            case .nfcInfoTitle:
                return self.readKey(key: "NfcInfoTitle")
            case .nfcInfoDesc:
                return self.readKey(key: "NfcInfoDesc")
            case .selfieInfoTitle:
                return self.readKey(key: "SelfieInfoTitle")
            case .selfieInfoDesc:
                return self.readKey(key: "SelfieInfoDesc")
            case .signatureInfoTitle:
                return self.readKey(key: "SignatureInfoTitle")
            case .signatureInfoDesc:
                return self.readKey(key: "SignatureInfoDesc")
            case .livenessInfoTitle:
                return self.readKey(key: "LivenessInfoTitle")
            case .livenessInfoDesc:
                return self.readKey(key: "LivenessInfoDesc")
            case .videoRecordInfoTitle:
                return self.readKey(key: "VideoRecordInfoTitle")
            case .videoRecordInfoDesc:
                return self.readKey(key: "VideoRecordInfoDesc")
            case .idCardInfoTitle:
                return self.readKey(key: "IdCardInfoTitle")
            case .idCardInfoDesc:
                return self.readKey(key: "IdCardInfoDesc")
            case .speechInfoTitle:
                return self.readKey(key: "SpeechInfoTitle")
            case .speechInfoText:
                return self.readKey(key: "SpeechInfoText")
            case .newIdCard:
                return self.readKey(key: "NewIdCart")
            case .passport:
                return self.readKey(key: "Passport")
            case .otherCards:
                return self.readKey(key: "OtherCards")
            case .scanType:
                return self.readKey(key: "ScanType")
            case .permissions:
                return self.readKey(key: "Permissons")
            case .permissionsText:
                return self.readKey(key: "PermissionsText")
            case .coreSend:
                return self.readKey(key: "CoreSend")
            case .coreCancel:
                return self.readKey(key: "CoreCancel")
            case .coreSettings:
                return self.readKey(key: "CoreSettings")
            case .corePlsWait:
                return self.readKey(key: "CorePlsWait")
            case .coreNoInternet:
                return self.readKey(key: "CoreNoInternet")
            case .coreNoInternetDesc:
                return self.readKey(key: "CoreNoInternetDesc")
            case .coreReConnect:
                return self.readKey(key: "CoreReconnect")
            case .corePermissionAlert:
                return self.readKey(key: "CorePermissionAlert")
            case .coreUpdate:
                return self.readKey(key: "CoreUpdate")
            case .coreBirthday:
                return self.readKey(key: "CoreBirthday")
            case .coreValidDay:
                return self.readKey(key: "CoreValidDay")
            case .coreSerialNumber:
                return self.readKey(key: "CoreSerialNumber")
            case .livenessStep1:
                return self.readKey(key: "LivenessStep1")
            case .livenessStep1Desc:
                return self.readKey(key: "LivenessStep1Desc")
            case .livenessStep2:
                return self.readKey(key: "LivenessStep2")
            case .livenessStep2Desc:
                return self.readKey(key: "LivenessStep2Desc")
            case .livenessStep3:
                return self.readKey(key: "LivenessStep3")
            case .livenessStep3Desc:
                return self.readKey(key: "LivenessStep3Desc")
            case .livenessStep4:
                return self.readKey(key: "LivenessStep4")
            case .livenessStep4Desc:
                return self.readKey(key: "LivenessStep4Desc")
            case .coreSkipAll:
                return self.readKey(key: "CoreSkipAll")
            case .corePullAgain:
                return self.readKey(key: "CorePullAgain")
            case .coreCityBtn:
                return self.readKey(key: "CoreCityBtn")
            case .coreCityDesc:
                return self.readKey(key: "CoreCityDesc")
            case .coreAddrDesc:
                return self.readKey(key: "CoreAddrDesc")
            case .coreInvoicePhoto:
                return self.readKey(key: "CoreInvoicePhoto")
            case .corePhotoBtn:
                return self.readKey(key: "CorePhotoBtn")
            case .coreSignLang:
                return self.readKey(key: "CoreSignLang")
            case .coreDelSig:
                return self.readKey(key: "CoreDelSig")
            case .selfieIdentInfo1:
                return self.readKey(key: "SelfieIdentInfoText")
            case .selfieIdentInfo2:
                return self.readKey(key: "SelfieIdentInfo2Text")
            case .selfieIdentInfo3:
                return self.readKey(key: "SelfieIdentInfo3Text")
            case .recordVideo:
                return self.readKey(key: "RecordVideo")
            case .takePhoto:
                return self.readKey(key: "TakePhoto")
            case .idCardFrontPhoto:
                return self.readKey(key: "IdCardFrontPhoto")
            case .idCardBackPhoto:
                return self.readKey(key: "IdCardBackPhoto")
            case .docFrontPhoto:
                return self.readKey(key: "DocFrontPhoto")
            case .docBackPhoto:
                return self.readKey(key: "DocBackPhoto")
            case .passportPhoto:
                return self.readKey(key: "PassportPhoto")
            case .anotherUserInToTheRoom:
                return self.readKey(key: "AnotherUserInToTheRoom")
            case .loadingFirstModule:
                return self.readKey(key: "LoadingFirstModule")
            case .waitingDesc1Live:
                return self.readKey(key: "WaitingDesc1Live")
            case .waitingDesc2Live:
                return self.readKey(key: "WaitingDesc2Live")
            case .waitingDesc3Live:
                return self.readKey(key: "WaitingDesc3Live")
            case .docType:
                return self.readKey(key: "DocType")
            case .livenessLookCam:
                return self.readKey(key: "LivenessLookCam")
            case .nfcKeyErrTitle:
                return self.readKey(key: "NfcKeyErrTitle")
            case .nfcKeyErrSubTitle:
                return self.readKey(key: "NfcKeyErrSubTitle")
            case .nfcSerialNo:
                return self.readKey(key: "NfcSerialNo")
            case .nfcBirthDate:
                return self.readKey(key: "NfcBirthDate")
            case .nfcExpDate:
                return self.readKey(key: "NfcExpDate")
            case .nfcStart:
                return self.readKey(key: "NfcStart")
            case .coreReconnecting:
                return self.readKey(key: "CoreReconnecting")
            case .wrongFrontSide:
                return self.readKey(key: "WrongFrontSide")
            case .wrongBackSide:
                return self.readKey(key: "WrongBackSide")
            case .missedCallTitle:
                return self.readKey(key: "MissedCallTitle")
            case .missedCallSubTitle:
                return self.readKey(key: "MissedCallSubTitle")
            case .checkMyConn:
                return self.readKey(key: "CheckMyConn")
            case .idNear:
                return self.readKey(key: "IdNear")
            case .ownAuth:
                return self.readKey(key: "OwnAuth")
            case .lightSoundCont:
                return self.readKey(key: "LightSoundCont")
            case .connectionGood:
                return self.readKey(key: "ConnectionGood")
            case .connectionSpeedSuccess:
                return self.readKey(key: "ConnectionSpeedSuccess")
            case .prepareCam:
                return self.readKey(key: "PrepareCam")
            case .prepareMic:
                return self.readKey(key: "PrepareMic")
            case .prepareSpeech:
                return self.readKey(key: "PrepareSpeech")
            case .scanHoldOn:
                return self.readKey(key: "ScanHoldOn")
            case .scanCloser:
                return self.readKey(key: "ScanCloser")
            case .scanGoAway:
                return self.readKey(key: "ScanGoAway")
            case .scanPrepareList:
                return self.readKey(key: "ScanPrepareList")
            case .identifyFailedTitle:
                return self.readKey(key: "IdentFailedTitle")
            case .identifyFailedDesc:
                return self.readKey(key: "IdentFailedDesc")
            case .activeNfcWarn:
                return self.readKey(key: "ActiveNfcWarn")
            case .activeNfcExit:
                return self.readKey(key: "ActiveNfcExit")
            case .activeSelfieWarn:
                return self.readKey(key: "ActiveSelfieWarn")
            case .activeSelfieExit:
                return self.readKey(key: "ActiveSelfieExit")
            case .scanErrDegree:
                return self.readKey(key: "ScanErrDegree")
        }
    }
}

public enum SDKKeywords {
    case connect
    case connectInfo
    case scanAgain
    case scanInfo
    case humanSmile
    case humanSmileDescription
    case callTitle
    case callDescription
    case enterSmsCode
    case waitingDesc1
    case waitingDesc2
    case thankU
    case board1
    case board2
    case board3
    case board4
    case board5
    case nextPage
    case backPage
    case skipPage
    case continuePage
    case popSelfie
    case popSmiley
    case popVideo
    case popMRZ
    case popNFC
    case popIdBackPhoto
    case popIdFrontPhoto
    case signatureInfo
    case soundRecognitionInfo
    case coreError
    case coreSuccess
    case wrongSMSCode
    case coreOk
    case newNfcFront
    case newNfcBack
    case newDocumentFront
    case newDocumentBack
    case nfcPassportScanInfo
    case nfcIDScanInfo
    case nfcDocumentScanInfo
    case nfcSuccess
    case nfcEditInfoTitle
    case nfcEditInfoDesc
    case coreDate
    case coreScan
    case coreInputError
    case coreNfcDeviceError
    case soundRecogOk
    case soundRecogFail
    case faceNotFound
    case smilingFaceNotFound
    case coreUploadError
    case nfcInfoTitle
    case nfcInfoDesc
    case selfieInfoTitle
    case selfieInfoDesc
    case signatureInfoTitle
    case signatureInfoDesc
    case livenessInfoTitle
    case livenessInfoDesc
    case videoRecordInfoTitle
    case videoRecordInfoDesc
    case idCardInfoTitle
    case idCardInfoDesc
    case speechInfoTitle
    case speechInfoText
    case newIdCard
    case passport
    case otherCards
    case scanType
    case permissions
    case permissionsText
    case coreSend
    case coreCancel
    case coreSettings
    case corePlsWait
    case coreNoInternet
    case coreNoInternetDesc
    case coreReConnect
    case corePermissionAlert
    case coreUpdate
    case coreBirthday
    case coreValidDay
    case coreSerialNumber
    case livenessStep1
    case livenessStep1Desc
    case livenessStep2
    case livenessStep2Desc
    case livenessStep3
    case livenessStep3Desc
    case livenessStep4
    case livenessStep4Desc
    case coreSkipAll
    case corePullAgain
    case coreCityBtn
    case coreCityDesc
    case coreAddrDesc
    case coreInvoicePhoto
    case corePhotoBtn
    case coreSignLang
    case coreDelSig
    case selfieIdentInfo1
    case selfieIdentInfo2
    case selfieIdentInfo3
    case recordVideo
    case takePhoto
    case idCardFrontPhoto
    case idCardBackPhoto
    case docFrontPhoto
    case docBackPhoto
    case passportPhoto
    case anotherUserInToTheRoom
    case loadingFirstModule
    case waitingDesc1Live
    case waitingDesc2Live
    case waitingDesc3Live
    case docType
    case livenessLookCam
    case nfcKeyErrTitle
    case nfcKeyErrSubTitle
    case nfcSerialNo
    case nfcBirthDate
    case nfcExpDate
    case nfcStart
    case coreReconnecting
    case wrongFrontSide
    case wrongBackSide
    case missedCallTitle
    case missedCallSubTitle
    case checkMyConn
    case idNear
    case ownAuth
    case lightSoundCont
    case connectionGood
    case connectionSpeedSuccess
    case prepareCam
    case prepareMic
    case prepareSpeech
    case scanHoldOn
    case scanCloser
    case scanGoAway
    case scanPrepareList
    case identifyFailedTitle
    case identifyFailedDesc
    case activeSelfieWarn
    case activeSelfieExit
    case activeNfcWarn
    case activeNfcExit
    case scanErrDegree
}
