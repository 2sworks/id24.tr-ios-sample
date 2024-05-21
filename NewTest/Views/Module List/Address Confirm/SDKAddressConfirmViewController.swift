//
//  SDKAddressConfirmViewController.swift
//  NewTest
//
//  Created by Emir Beytekin on 15.11.2022.
//

import UIKit
import MobileCoreServices

class SDKAddressConfirmViewController: SDKBaseViewController {

    @IBOutlet weak var submitBtn: IdentifyButton!
    @IBOutlet weak var photoBtn: IdentifyButton!
    @IBOutlet weak var docPhoto: UIImageView!
    var imagePicker = UIImagePickerController()
    var idPhoto = ""
    var docImg = UIImage()
    @IBOutlet weak var addressTxt: UITextView!
    var addressOk = false
    @IBOutlet weak var desc1Lbl: UILabel!
    
    @IBOutlet weak var desc2Lbl: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        self.resetCache()
    }
    
    private func resetCache() {
        self.addressTxt.text = ""
        self.addressOk = false
        self.docImg = UIImage()
        self.docPhoto.image = UIImage()
        self.idPhoto = ""
        self.checkSubmitAvailablity()
    }
    
    private func setupUI() {
        addressTxt.delegate = self
        photoBtn.type = .cancel
        photoBtn.setTitle(self.translate(text: .corePhotoBtn), for: .normal)
        photoBtn.onTap = {
            self.showOptions()
        }
        photoBtn.populate()
        submitBtn.type = .submit
        submitBtn.setTitle(self.translate(text: .continuePage), for: .normal)
        submitBtn.onTap = {
            self.submitForm()
        }
        submitBtn.populate()
        self.checkSubmitAvailablity()
        
        self.desc1Lbl.text = self.translate(text: .coreAddrDesc)
        self.desc2Lbl.text = self.translate(text: .coreInvoicePhoto)
    }
    
    private func showOptions() {
        // create an actionSheet
        let actionSheetController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        // create an action
        let firstAction: UIAlertAction = UIAlertAction(title: "Fotoğraf Çek", style: .default) { action -> Void in
            self.openScanner()
        }

        let secondAction: UIAlertAction = UIAlertAction(title: "Fotoğraf Seç", style: .default) { action -> Void in
            self.openGallery()
        }

        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in }
        
        actionSheetController.addAction(firstAction)
        actionSheetController.addAction(secondAction)
        actionSheetController.addAction(cancelAction)

        actionSheetController.popoverPresentationController?.sourceView = self.view
        present(actionSheetController, animated: true) {
        }
    }
    
    private func attachDocument() {
        let types = [kUTTypePDF]
        let importMenu = UIDocumentPickerViewController(documentTypes: types as [String], in: .import)

        if #available(iOS 11.0, *) {
            importMenu.allowsMultipleSelection = true
        }

        importMenu.delegate = self
        importMenu.modalPresentationStyle = .formSheet

        present(importMenu, animated: true)
    }
    
    private func openScanner() {
        DispatchQueue.main.async {
            let scannerViewController = ImageScannerController(enabledAutoCapture: false, scannerMode: .addressScan)
            scannerViewController.imageScannerDelegate = self
            scannerViewController.navigationBar.backgroundColor = IdentifyTheme.grayColor
            scannerViewController.navigationBar.tintColor = IdentifyTheme.whiteColor
            scannerViewController.toolbar.backgroundColor = IdentifyTheme.grayColor
            scannerViewController.toolbar.tintColor = IdentifyTheme.grayColor
            scannerViewController.modalPresentationStyle = .fullScreen
            scannerViewController.isModalInPresentation = true
            self.present(scannerViewController, animated: true)
        }
    }
    
    private func openGallery() {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            imagePicker.delegate = self
            imagePicker.sourceType = .savedPhotosAlbum
            imagePicker.allowsEditing = false
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    @discardableResult func checkSubmitAvailablity() -> Bool {
        if idPhoto != "" && addressOk == true {
            submitBtn.isUserInteractionEnabled = true
            UIView.animate(withDuration: 0.3) {
                self.submitBtn.alpha = 1
            }
            return true
        } else {
            submitBtn.isUserInteractionEnabled = false
            UIView.animate(withDuration: 0.3) {
                self.submitBtn.alpha = 0.6
            }
            return false
        }
    }
    
    private func submitForm() {
        self.showLoader()
        self.manager.uploadAddressInfo(invoicePhoto: docImg, addressText: self.addressTxt.text) { webResp, sdkError in
            self.hideLoader()
            if webResp {
                self.manager.getNextModule { nextVC in
                    self.navigationController?.pushViewController(nextVC, animated: true)
                }
            } else {
                if let err = sdkError {
                    self.showToast(type: .fail, title: self.translate(text: .coreError), subTitle: err.errorMessages, attachTo: self.view) {
                        return
                    }
                }
            }
        }
    }

}

extension SDKAddressConfirmViewController: UIDocumentPickerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        docPhoto.image = UIImage(named: "pdf")
    }

     func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        let image: UIImage? = info[.originalImage] as? UIImage
        
        if image != nil {
            docPhoto.image = image
            docImg = image!
            self.idPhoto = image?.jpegData(compressionQuality: 0.5)?.base64EncodedString() ?? ""
            checkSubmitAvailablity()
        }
    }
}


extension SDKAddressConfirmViewController: ImageScannerControllerDelegate {
    func imageScannerController(_ scanner: ImageScannerController, didFinishScanningWithResults results: ImageScannerResults) {
        docPhoto.image = results.croppedScan.image
        docImg = results.croppedScan.image
        self.idPhoto = results.croppedScan.image.jpegData(compressionQuality: 0.5)?.base64EncodedString() ?? ""
        checkSubmitAvailablity()
        scanner.dismiss(animated: true)
    }
    
    func imageScannerControllerDidCancel(_ scanner: ImageScannerController) {
        scanner.dismiss(animated: true)
    }
    
    func imageScannerController(_ scanner: ImageScannerController, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
}

extension SDKAddressConfirmViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.count > 0 {
            addressOk = true
            checkSubmitAvailablity()
        } else {
            addressOk = false
            checkSubmitAvailablity()
        }
    }
    
}
