//
//  SDKSelfieViewController.swift
//  NewTest
//
//  Created by Emir Beytekin on 25.10.2022.
//

import UIKit

class SDKSelfieViewController: SDKBaseViewController {

    @IBOutlet weak var takeSelfieBtn: IdentifyButton!
    @IBOutlet weak var selfieView: UIImageView!
    @IBOutlet weak var submitBtn: IdentifyButton!
    @IBOutlet weak var informationLbl: UILabel!
    let vc = UIImagePickerController()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkCameraPermission()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        self.resetCache()
    }
    
    private func resetCache() {
        self.submitBtn.setTitle(self.translate(text: .continuePage), for: .normal)
        self.selfieView.image = UIImage.init(named: "takeSelfie")
        isEnableSubmit(enabled: false)
    }
    
    func setupUI() {
        self.submitBtn.setTitle(self.translate(text: .continuePage), for: .normal)
        self.submitBtn.onTap = {
            self.manager.getNextModule { nextVC in
                self.navigationController?.pushViewController(nextVC, animated: true)
            }
        }
        self.submitBtn.populate()
        
        takeSelfieBtn.setTitle(self.translate(text: .takePhoto), for: .normal)
        takeSelfieBtn.type = .info
        takeSelfieBtn.onTap = {
            self.openCamera()
        }
        takeSelfieBtn.populate()
        isEnableSubmit(enabled: false)
    }
    
    private func isEnableSubmit(enabled: Bool) {
        if enabled {
            self.submitBtn.alpha = 1
            self.informationLbl.text = self.translate(text: .thankU)
        } else {
            self.submitBtn.alpha = 0.3
            self.informationLbl.text = self.translate(text: .popSelfie)
        }
        self.submitBtn.isUserInteractionEnabled = enabled
    }
    
    private func uploadSelfie(image: UIImage) {
        self.showLoader()
        self.manager.uploadIdPhoto(idPhoto: image , selfieType: .selfie) { webResp in
            
            if webResp.result == true && webResp.data?.comparison == false {
                self.hideLoader()
                let alertMsg = self.translate(text: .activeSelfieWarn)
                let alertExpMsg = self.translate(text: .activeSelfieExit)
                if self.manager.selfieComparisonCount == self.manager.tryedSelfieComparisonCount {
                    self.oneButtonAlertShow(message: alertExpMsg, title1: "Tamam") {
                        self.closeSDK()
                    }
                } else {
                    self.oneButtonAlertShow(message: alertMsg, title1: "Tamam") {
                        self.manager.tryedSelfieComparisonCount += 1
                    }
                }
            } else if webResp.result == true && webResp.data?.comparison == true {
                self.hideLoader()
                self.showToast(title: self.translate(text: .coreSuccess), subTitle: self.translate(text: .coreSuccess), attachTo: self.view) {
                    print("Foto upload tamam")
                    self.vc.delegate = nil
                }
                self.manager.tryedSelfieComparisonCount = 1 // resetliyoruz
                self.isEnableSubmit(enabled: true)
            } else {
                self.showToast(type:.fail, title: self.translate(text: .coreUploadError), attachTo: self.view) {
                    return
                }
                self.hideLoader()
            }
        }
    }

}
extension SDKSelfieViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    func openCamera() {
        self.vc.sourceType = .camera
        self.vc.cameraDevice = .front
        self.vc.cameraFlashMode = .off
        self.vc.allowsEditing = false
        self.vc.delegate = self
        DispatchQueue.main.async {
            self.present(self.vc, animated: true)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        let image: UIImage? = info[.originalImage] as? UIImage
        if image != nil {
            self.manager.detectHumanFace(comingPhoto: image!) { isHuman in
                if isHuman {
                    self.takeSelfieBtn.setTitle(self.translate(text: .takePhoto), for: .normal)
                    let flippedImage = UIImage(cgImage: image!.cgImage!, scale: image!.scale, orientation: .leftMirrored)
                    self.selfieView.image = flippedImage
                    self.uploadSelfie(image: flippedImage)
                    
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                        self.showToast(title: self.translate(text: .coreError), subTitle: self.translate(text: .faceNotFound), attachTo: self.view) {
                            print("fail")
                        }
                    })
                }
            }
        }
        
    }
    
}
