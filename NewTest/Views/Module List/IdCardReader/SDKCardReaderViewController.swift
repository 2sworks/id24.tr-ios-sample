//
//  SDKCardReaderViewController.swift
//  NewTest
//
//  Created by Emir Beytekin on 25.10.2022.
//

import UIKit
import IdentifySDK
import Vision
import VisionKit
import QKMRZScanner

protocol SDKPassportReaderDelegate {
    func completeReading(info: QKMRZScanResult)
}

class SDKCardReaderViewController: SDKBaseViewController {
    
    @IBOutlet weak var frontIdPhoto: UIImageView!
    @IBOutlet weak var backIdPhoto: UIImageView!
    private var isFrontSide = true
    @IBOutlet weak var frontIdStack: UIStackView!
    @IBOutlet weak var backIdStack: UIStackView!
    
    @IBOutlet weak var resultLbl: UILabel!
    @IBOutlet weak var continueBtn: IdentifyButton!
    @IBOutlet weak var backSideBtn: IdentifyButton!
    @IBOutlet weak var frontSideBtn: IdentifyButton!
    
    @IBOutlet weak var result2Lbl: UILabel!
    
    private var cardSide: OCRType? = .frontId
    private var photoFrontSide = false
    private var photoBackSide = false
    private var passportInfo = FrontIdInfo()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkCameraPermission()
        if self.manager.tryedNfcComparisonCount >= 2 {
            setContinueButton(isActive: false)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    private func resetCache() {
        if self.manager.selectedCardType == .passport {
            self.frontIdPhoto.image = UIImage(named: "passport")
        } else {
            self.frontIdPhoto.image = UIImage(named: "idFront")
        }
        self.backIdPhoto.image = UIImage(named: "idBack")
    }
    
    private func setupUI() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: self.translate(text: .docType), style: .plain, target: self, action: #selector(showOptions))
        self.backIdStack.isHidden = true
        self.frontIdStack.isHidden = true
        self.setContinueButton(isActive: false)
        continueBtn.type = .submit
        continueBtn.setTitle(self.translate(text: .continuePage), for: .normal)
        continueBtn.onTap = {
            self.manager.getNextModule { nextVC in
                self.navigationController?.pushViewController(nextVC, animated: true)
                self.resetCache()
            }
        }
        continueBtn.populate()
        self.showOptions()
    }
    
    @objc func showOptions() {
        let actionSheetController: UIAlertController = UIAlertController(title: self.translate(text: .scanType), message: nil, preferredStyle: .actionSheet)
        
        let firstAction: UIAlertAction = UIAlertAction(title: self.translate(text: .newIdCard), style: .default) { action -> Void in
            self.manager.selectedCardType = .idCard
            self.setForIdCard()
        }
        
        let secondAct: UIAlertAction = UIAlertAction(title: self.translate(text: .passport), style: .default) { action -> Void in
            self.manager.selectedCardType = .passport
            self.setForPassport()
        }
        
        let thirdAct: UIAlertAction = UIAlertAction(title: self.translate(text: .otherCards), style: .default) { action -> Void in
            self.manager.selectedCardType = .oldSchool
            self.setForOldSchoolCard()
        }
        

        for allowedType in self.manager.allowedCardType {
            switch allowedType {
                case .idCard:
                    actionSheetController.addAction(firstAction)
                case .passport:
                    actionSheetController.addAction(secondAct)
                case .oldSchool:
                    actionSheetController.addAction(thirdAct)
                
                default:
                    return
            }
        }
        actionSheetController.popoverPresentationController?.sourceView = self.view
        present(actionSheetController, animated: true)
    }
    
    private func setForIdCard() {
        self.manager.selectedCardType = .idCard
        self.backIdStack.isHidden = false
        self.frontIdStack.isHidden = false
        self.frontIdPhoto.image = UIImage(named: "idFront")
        frontSideBtn.type = .cancel
        frontSideBtn.setTitle(self.translate(text: .idCardFrontPhoto), for: .normal)
        frontSideBtn.onTap = {
            self.cardSide = .frontId
            self.takeCardPhoto()
        }
        
        backSideBtn.type = .cancel
        backSideBtn.setTitle(self.translate(text: .idCardBackPhoto), for: .normal)
        backSideBtn.onTap = {
            self.cardSide = .backId
            self.takeCardPhoto()
        }
        frontSideBtn.populate()
        backSideBtn.populate()
    }
    
    private func setForPassport() {
        self.manager.selectedCardType = .passport
        self.backIdStack.isHidden = true
        self.frontIdStack.isHidden = false
        self.frontIdPhoto.image = UIImage(named: "passport")
        self.frontSideBtn.setTitle(self.translate(text: .passportPhoto), for: .normal)
        frontSideBtn.type = .info
        frontSideBtn.onTap = {
            self.cardSide = .passport
            self.openPassportScanner()
        }
        frontSideBtn.populate()
    }
    
    private func openPassportScanner() {
        let nextVC = SDKPassportReaderViewController()
        nextVC.delegate = self
        self.present(nextVC, animated: true)
    }
    
    private func setForOldSchoolCard() {
        self.manager.selectedCardType = .oldSchool
        self.backIdStack.isHidden = false
        self.frontIdStack.isHidden = false
        self.frontIdPhoto.image = UIImage(named: "idFront")
        frontSideBtn.type = .cancel
        frontSideBtn.setTitle(self.translate(text: .idCardFrontPhoto), for: .normal)
        frontSideBtn.onTap = {
            self.cardSide = .frontId
            self.takeCardPhoto()
        }
        
        backSideBtn.type = .cancel
        backSideBtn.setTitle(self.translate(text: .idCardBackPhoto), for: .normal)
        backSideBtn.onTap = {
            self.cardSide = .backId
            self.takeCardPhoto()
        }
        
        frontSideBtn.populate()
        backSideBtn.populate()
    }
    
    private func setContinueButton(isActive: Bool) {
        if isActive {
            self.continueBtn.alpha = 1
        } else {
            self.continueBtn.alpha = 0.3
        }
        self.continueBtn.isUserInteractionEnabled = isActive
    }
    
    private func changeViewForPassport() {
        self.backIdStack.removeFullyAllArrangedSubviews()
        self.frontSideBtn.setTitle(self.translate(text: .passportPhoto), for: .normal)
        frontSideBtn.type = .info
        frontSideBtn.onTap = {
            self.cardSide = .passport
            self.takeCardPhoto()
        }
    }
    
    func takeCardPhoto() {
        let scannerViewController = ImageScannerController(enabledAutoCapture: true, scannerMode: .idCard)
        scannerViewController.imageScannerDelegate = self
        scannerViewController.navigationBar.backgroundColor = IdentifyTheme.blueColor
        scannerViewController.navigationBar.tintColor = IdentifyTheme.whiteColor
        scannerViewController.toolbar.backgroundColor = IdentifyTheme.grayColor
        scannerViewController.toolbar.tintColor = IdentifyTheme.grayColor
        
        DispatchQueue.main.async {
            scannerViewController.view.backgroundColor = IdentifyTheme.blackBack
            scannerViewController.modalPresentationStyle = .fullScreen
            scannerViewController.isModalInPresentation = true
            self.present(scannerViewController, animated: true)
        }
    }
    
    private func startOCR() {
        switch self.cardSide {
            case .frontId:
                self.showLoader()
                if self.manager.selectedCardType == .oldSchool {
                    self.manager.uploadIdPhoto(idPhoto: self.frontIdPhoto.image ?? UIImage(), selfieType: .frontId) { webResp in
                        if webResp.result == true {
                            self.photoFrontSide = true
                            self.cardSide = .backId
                            self.hideLoader()
                            self.checkButtonStatus()
                        } else {
                            self.showToast(title: self.translate(text: .coreError), subTitle: "\(webResp.messages?.first ?? self.translate(text: .coreUploadError))", attachTo: self.view) {
                                self.hideLoader()
                            }
                        }
                    }
                    return
                } else {
                    self.manager.startFrontIdOcr(frontImg:self.frontIdPhoto.image ?? UIImage()) { resp, err in
                        if err != nil {
                            self.showToast(type: .fail, title: self.translate(text: .coreError), subTitle: err?.errorMessages ?? "", attachTo: self.view) {
                                if self.manager.selectedCardType == .passport {
                                    self.frontIdPhoto.image = UIImage(named: "passport")
                                } else {
                                    self.frontIdPhoto.image = UIImage(named: "idFront")
                                }
                                self.hideLoader()
                                return
                            }
                        } else {
                            print(self.manager.sdkFrontInfo.asDictionary())
                            self.manager.uploadIdPhoto(idPhoto: self.frontIdPhoto.image ?? UIImage()) { webResp in
                                if webResp.result == true {
                                    self.photoFrontSide = true
                                    self.cardSide = .backId
                                    self.hideLoader()
                                    self.checkButtonStatus()
                                } else {
                                    self.showToast(title: self.translate(text: .coreError), subTitle: "\(webResp.messages?.first ?? self.translate(text: .coreUploadError))", attachTo: self.view) {
                                        self.hideLoader()
                                    }
                                }
                            }
                        }
                    }
                }
                
            case .backId:
                self.showLoader()
                if self.manager.selectedCardType == .oldSchool {
                    self.manager.uploadIdPhoto(idPhoto: self.backIdPhoto.image ?? UIImage(), selfieType: .backId) { webResp in
                        if webResp.result == true {
                            self.photoBackSide = true
                            self.cardSide = .backId
                            self.hideLoader()
                            self.checkButtonStatus()
                        } else {
                            self.showToast(title: self.translate(text: .coreError), subTitle: "\(webResp.messages?.first ?? self.translate(text: .coreUploadError))", attachTo: self.view) {
                                self.hideLoader()
                            }
                        }
                    }
                    return
                } else {
                    self.manager.startBackIdOcr(frontImg: self.backIdPhoto.image ?? UIImage()) { resp, err in
                        if err != nil {
                            self.showToast(type: .fail, title: self.translate(text: .coreError), subTitle: self.translate(text: .wrongBackSide), attachTo: self.view) {
                                self.backIdPhoto.image = UIImage(named: "idBack")
                                self.hideLoader()
                                return
                            }
                        } else {
                            print("Front OCR \(self.manager.sdkFrontInfo.asDictionary())")
                            print("Back OCR \(self.manager.sdkBackInfo.asDictionary())")
                            self.manager.uploadIdPhoto(idPhoto: self.backIdPhoto.image ?? UIImage(), selfieType: .backId) { webResp in
                                if webResp.result == true && webResp.data?.comparison == true {
                                    self.photoBackSide = true
                                    self.hideLoader()
                                    self.manager.tryedOcrComparisonCount = 1 // resetliyoruz
                                    self.checkButtonStatus()
                                } else if webResp.result == true && webResp.data?.comparison == false {
                                    self.hideLoader()
                                    let alertMsg = self.translate(text: .activeOcrWarn)
                                    let alertExpMsg = self.translate(text: .activeOcrExit)
                                    if self.manager.ocrComparisonCount == self.manager.tryedOcrComparisonCount {
                                        self.oneButtonAlertShow(message: alertExpMsg, title1: "Tamam") {
                                            self.closeSDK()
                                        }
                                    } else {
                                        self.manager.tryedOcrComparisonCount += 1
                                        self.oneButtonAlertShow(message: alertMsg, title1: "Tamam") {
                                            
                                        }
                                    }
                                } else {
                                    self.showToast(title: self.translate(text: .coreError), subTitle: "\(webResp.messages?.first ?? self.translate(text: .coreUploadError))", attachTo: self.view) {
                                        self.hideLoader()
                                    }
                                }
                                
                            }
                        }
                    }
                }
                
        case .passport:
            self.showLoader()
            self.manager.startPassportMrzKey(frontImg: self.frontIdPhoto.image ?? UIImage(), cominData: self.passportInfo) { idInfo, err in
                if err == nil {
                    self.manager.uploadIdPhoto(idPhoto: self.frontIdPhoto.image ?? UIImage(), selfieType: .frontId) { webResp in
                        if webResp.result == true {
                            self.photoFrontSide = true
                            self.hideLoader()
                            self.checkButtonStatus()
                        } else {
                            self.showToast(title: self.translate(text: .coreError), subTitle: "\(webResp.messages?.first ?? self.translate(text: .coreUploadError))", attachTo: self.view) {
                                self.hideLoader()
                            }
                        }
                    }
                } else {
                    self.showToast(title: self.translate(text: .coreError), subTitle: "\(err?.errorMessages ?? self.translate(text: .coreUploadError))", attachTo: self.view) {
                        self.hideLoader()
                    }
                    print("error")
                }
            }
            
            default:
                return
        }
    }
    
    func checkButtonStatus() {
        switch cardSide {
            case .passport:
                let status = photoFrontSide
                self.setContinueButton(isActive: status)
            case .frontId, .backId:
                let status = photoFrontSide && photoBackSide
                self.setContinueButton(isActive: status)
            default:
                return
        }
        
    }

}

extension SDKCardReaderViewController: ImageScannerControllerDelegate {
    
    func imageScannerController(_ scanner: ImageScannerController, didFinishScanningWithResults results: ImageScannerResults) {
        scanner.dismiss(animated: true) {
            switch self.cardSide {
                case .frontId:
                    self.frontIdPhoto.image = results.croppedScan.image
                case .backId:
                    self.backIdPhoto.image = results.croppedScan.image
                case .passport:
                    self.frontIdPhoto.image = results.croppedScan.image
                default:
                    return
            }
            DispatchQueue.main.async {
                self.startOCR()
            }
            
        }
        
    }
    
    func imageScannerControllerDidCancel(_ scanner: ImageScannerController) {
        scanner.dismiss(animated: true)
        print("canceled")
    }
    
    func imageScannerController(_ scanner: ImageScannerController, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
    
}

extension SDKCardReaderViewController: SDKPassportReaderDelegate {
    func completeReading(info: QKMRZScanner.QKMRZScanResult) {
        self.frontIdPhoto.image = info.documentImage
        self.photoFrontSide = true
        self.manager.mrzDocNo = info.documentNumber
        self.manager.mrzBirthDay = info.birthdate!.description.toPassportMrzDate()
        self.manager.mrzValidDate = info.expiryDate!.debugDescription.toPassportMrzDate()
        self.startOCR()
    }
}
