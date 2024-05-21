//
//  SDKPassportReaderViewController.swift
//  NewTest
//
//  Created by Emir Beytekin on 12.12.2022.
//

import UIKit
import QKMRZScanner
import IdentifySDK

class SDKPassportReaderViewController: SDKBaseViewController {

    @IBOutlet weak var mrzScannerView: QKMRZScannerView!
    
    var delegate: SDKPassportReaderDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mrzScannerView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mrzScannerView.startScanning()
        mrzScannerView.vibrateOnResult = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mrzScannerView.stopScanning()
    }

}

extension SDKPassportReaderViewController: QKMRZScannerViewDelegate {
    
    func mrzScannerView(_ mrzScannerView: QKMRZScannerView, didFind scanResult: QKMRZScanResult) {
        self.dismiss(animated: true) {
            mrzScannerView.stopScanning()
            let frontInfo = FrontIdInfo()
            frontInfo.idTcknOcr = scanResult.personalNumber
            frontInfo.idNameOcr = scanResult.givenNames
            frontInfo.idSurnameOcr = scanResult.surnames
            frontInfo.idSerialNoOcr = scanResult.documentNumber
            frontInfo.idBirthDateOcr = "\(scanResult.birthdate?.description.toPassportMrzDate() ?? "not found")"
            frontInfo.idValidUntilOcr = "\(scanResult.expiryDate?.description.toPassportMrzDate() ?? "not found")"
            self.manager.sdkFrontInfo = frontInfo
            
            
            let backInfo = self.manager.sdkBackInfo
            backInfo.idNameMRZ = scanResult.givenNames
            backInfo.idSurnameMRZ = scanResult.surnames
            backInfo.idTcknMRZ = scanResult.personalNumber
            backInfo.idDocumentNumberMRZ = scanResult.documentNumber
            backInfo.idBirthDateMRZ = "\(scanResult.birthdate?.description.toPassportMrzDate() ?? "not found")"
            backInfo.idValidDateMRZ = "\(scanResult.expiryDate?.description.toPassportMrzDate() ?? "not found")"
            self.manager.sdkBackInfo = backInfo
            
            self.delegate?.completeReading(info: scanResult)
        }
    }
}
