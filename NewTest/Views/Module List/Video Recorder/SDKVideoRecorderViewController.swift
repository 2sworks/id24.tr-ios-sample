//
//  SDKVideoRecorderViewController.swift
//  NewTest
//
//  Created by Emir Beytekin on 14.11.2022.
//

import UIKit
import AVKit
import AVFoundation
import MobileCoreServices

class SDKVideoRecorderViewController: SDKBaseViewController {
    
    let videoTimeLimit = 5.0
    @IBOutlet weak var videoView: UIView!
    var videoData = Data()
    @IBOutlet weak var infoImgView: UIImageView!
    @IBOutlet weak var takeVideoBtn: IdentifyButton!
    @IBOutlet weak var submitBtn: IdentifyButton!
    @IBOutlet weak var desc1Lbl: UILabel!
    var player = AVPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.resetCache()
    }
    
    private func resetCache() {
        setupUI()
        infoImgView.image = UIImage()
    }
    
    private func setupUI() {
        takeVideoBtn.setTitle(self.translate(text: .recordVideo), for: .normal)
        takeVideoBtn.type = .info
        takeVideoBtn.onTap = {
            self.openCamera()
        }
        takeVideoBtn.populate()
        
        submitBtn.setTitle(self.translate(text: .continuePage), for: .normal)
        submitBtn.type = .submit
        setNextBtn(isEnabled: false)
        submitBtn.onTap = {
            self.sendVideo()
        }
        submitBtn.populate()
        
        self.desc1Lbl.text = self.translate(text: .popVideo)
    }
    
    private func setNextBtn(isEnabled: Bool) {
        if isEnabled {
            self.submitBtn.alpha = 1
            self.submitBtn.isUserInteractionEnabled = true
        } else {
            self.submitBtn.alpha = 0.3
            self.submitBtn.isUserInteractionEnabled = false
        }
    }
    
    private func openCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.allowsEditing = false
        vc.delegate = self
        vc.mediaTypes = [kUTTypeMovie as String]
        vc.cameraCaptureMode = .video
        vc.cameraDevice = .front
        vc.videoMaximumDuration = videoTimeLimit
        DispatchQueue.main.async {
            self.present(vc, animated: false)
        }
    }
    
    private func sendVideo() {
        self.showLoader()
        manager.upload5SecVideo(videoData: self.videoData) { resp, webErr in
            self.hideLoader()
            if let err = webErr, err.errorMessages != "" {
                self.showToast(title: self.translate(text: .coreError), subTitle: err.errorMessages, attachTo: self.view) {
                    return
                }
            } else {
                self.showToast(title: self.translate(text: .coreSuccess), subTitle: self.translate(text: .coreSuccess), attachTo: self.view) {
                    self.manager.getNextModule { nextVC in
                        self.player.pause()
                        self.navigationController?.pushViewController(nextVC, animated: true)
                    }
                }
            }
        }
    }

}

extension SDKVideoRecorderViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let videoUrl = info[UIImagePickerController.InfoKey.mediaURL] as? URL else {
            return
        }
            do {
                let data = try Data(contentsOf: videoUrl, options: .mappedIfSafe)
                self.videoData = data
                self.player = AVPlayer(url: videoUrl)
                let playerLayer = AVPlayerLayer(player: player)
                playerLayer.frame = videoView.bounds
                infoImgView.image = nil
                videoView.layer.addSublayer(playerLayer)
                DispatchQueue.main.async {
                    self.player.play()
                }
                self.setNextBtn(isEnabled: true)
            } catch let error {
                print("error : \(error.localizedDescription)")
                self.setNextBtn(isEnabled: false)
            }
        

    }
}
