//
//  SDKPrepareViewController.swift
//  NewTest
//
//  Created by Emir Beytekin on 13.11.2023.
//

import UIKit
import CameraPermission
import SpeechRecognizerPermission
import MicrophonePermission

class SDKPrepareViewController: SDKBaseViewController {

    @IBOutlet weak var submitBtn: IdentifyButton!
    var speedCheckDone = false
    @IBOutlet weak var speedStackView: UIStackView!
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!
    @IBOutlet weak var connectCheckLbl: UILabel!
    @IBOutlet weak var prepareLbl: UILabel!
    
    @IBOutlet weak var micReqBtn: UIButton!
    @IBOutlet weak var camReqBtn: UIButton!
    @IBOutlet weak var speechReqBtn: UIButton!
    
    var authCamera = false
    var authSpeech = false
    var authMic = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.checkPermissions()
        
    }
    
    override func viewDidLayoutSubviews() {
        self.navigationItem.rightBarButtonItem = nil // bu modülün skip edilebilmesini kaldırıyoruz
    }
    
    func checkPermissions() {
        self.camReqBtn.isSelected = camReq.authorized
        self.speechReqBtn.isSelected = speechReq.authorized
        self.micReqBtn.isSelected = micReq.authorized
        self.checkButtonEnabled()
    }
    
    func checkButtonEnabled() {
        if camReq.notDetermined || !camReq.authorized {
            self.camReqBtn.isUserInteractionEnabled = true
        } else {
            self.camReqBtn.isUserInteractionEnabled = false
        }
        
        if speechReq.notDetermined || !speechReq.authorized {
            self.speechReqBtn.isUserInteractionEnabled = true
        } else {
            self.speechReqBtn.isUserInteractionEnabled = false
        }
        
        if micReq.notDetermined || !micReq.authorized {
            self.micReqBtn.isUserInteractionEnabled = true
        } else {
            self.micReqBtn.isUserInteractionEnabled = false
        }
        self.setupUI()
    }
    
    func checkCameraSettings() {
        let cameraCheck = CameraPermission.camera
        if cameraCheck.authorized == false {
            cameraCheck.request {
                if cameraCheck.status == .denied {
                    cameraCheck.openSettingPage()
                } else {
                    self.camReqBtn.isSelected = cameraCheck.authorized
                    self.camReqBtn.isUserInteractionEnabled = false
                    self.reloadSubmitButton()
                }
            }
        } else {
            camReqBtn.isSelected = !camReqBtn.isSelected
            camReqBtn.isUserInteractionEnabled = false
            self.reloadSubmitButton()
        }
    }
    
    func checkMicrophoneSettings() {
        let micCheck = MicrophonePermission.microphone
        if micCheck.authorized == false {
            if micCheck.status == .denied {
                micCheck.openSettingPage()
            } else if micCheck.status == .notDetermined {
                micCheck.request {
                    self.micReqBtn.isSelected = micCheck.authorized
                    self.micReqBtn.isUserInteractionEnabled =  !micCheck.authorized
                }
            } else if micCheck.status == .authorized {
                micReqBtn.isSelected = !micReqBtn.isSelected
                micReqBtn.isUserInteractionEnabled = false
                self.reloadSubmitButton()
            }
        } else {
            micReqBtn.isSelected = !micReqBtn.isSelected
            micReqBtn.isUserInteractionEnabled = false
            self.reloadSubmitButton()
        }
    }
    
    func checkSpeechSettings() {
        let speechCheck = SpeechPermission.speech
        if speechCheck.authorized == false {
            if speechCheck.status == .denied {
                speechCheck.openSettingPage()
            } else if speechCheck.status == .notDetermined {
                speechCheck.request {
                    self.speechReqBtn.isSelected = speechCheck.authorized
                    self.speechReqBtn.isUserInteractionEnabled =  !speechCheck.authorized
                }
            } else if speechCheck.status == .authorized {
                speechReqBtn.isSelected = !speechReqBtn.isSelected
                speechReqBtn.isUserInteractionEnabled = false
                self.reloadSubmitButton()
            }
        } else {
            speechReqBtn.isSelected = !speechReqBtn.isSelected
            speechReqBtn.isUserInteractionEnabled = false
            self.reloadSubmitButton()
        }
    }
    
    func setupUI() {
        self.prepareLbl.text = self.translate(text: .scanPrepareList)
        guard let needSpeedTest = self.manager.needSpeedTest else { return }
        if needSpeedTest {
            self.submitBtn.setTitle(self.translate(text: .checkMyConn), for: .normal)
            self.submitBtn.type = .cancel
        } else {
            self.submitBtn.setTitle(self.translate(text: .continuePage), for: .normal)
            self.submitBtn.type = .submit
        }
        self.submitBtn.onTap = {
            self.startSpeedTest()
        }
        self.submitBtn.alpha = 0.3
        self.submitBtn.isEnabled = false
        self.submitBtn.populate()
        self.setupButtons()
        self.connectCheckLbl.text =  self.translate(text: .connectionGood)
    }
    
    func setupButtons() {
        button1.setTitle(self.translate(text: .idNear), for: .normal)
        button1.setTitle(self.translate(text: .idNear), for: .selected)
        button1.titleLabel?.numberOfLines = 0
        button1.titleLabel?.lineBreakMode = .byWordWrapping
        button1.setImage(UIImage(named: "emptyTick"), for: .normal)
        button1.setImage(UIImage(named: "checkTick"), for: .selected)
        button1.tag = 1
        button1.addTarget(self, action: #selector(checkBoxTapped(_ :)), for: .touchUpInside)
        
        button2.setTitle(self.translate(text: .ownAuth), for: .normal)
        button2.setTitle(self.translate(text: .ownAuth), for: .selected)
        button2.titleLabel?.numberOfLines = 0
        button2.titleLabel?.lineBreakMode = .byWordWrapping
        button2.setImage(UIImage(named: "emptyTick"), for: .normal)
        button2.setImage(UIImage(named: "checkTick"), for: .selected)
        button2.tag = 2
        button2.addTarget(self, action: #selector(checkBoxTapped(_ :)), for: .touchUpInside)
        
        button3.setTitle(self.translate(text: .lightSoundCont), for: .normal)
        button3.setTitle(self.translate(text: .lightSoundCont), for: .selected)
        button3.titleLabel?.numberOfLines = 0
        button3.titleLabel?.lineBreakMode = .byWordWrapping
        button3.setImage(UIImage(named: "emptyTick"), for: .normal)
        button3.setImage(UIImage(named: "checkTick"), for: .selected)
        button3.tag = 3
        button3.addTarget(self, action: #selector(checkBoxTapped(_ :)), for: .touchUpInside)
        
        
        camReqBtn.setTitle(self.translate(text: .prepareCam), for: .normal)
        camReqBtn.setTitle(self.translate(text: .prepareCam), for: .selected)
        camReqBtn.titleLabel?.numberOfLines = 0
        camReqBtn.titleLabel?.lineBreakMode = .byWordWrapping
        camReqBtn.setImage(UIImage(named: "emptyTick"), for: .normal)
        camReqBtn.setImage(UIImage(named: "checkTick"), for: .selected)
        camReqBtn.tag = 4
        camReqBtn.addTarget(self, action: #selector(checkBoxTapped(_ :)), for: .touchUpInside)

        
        micReqBtn.setTitle(self.translate(text: .prepareMic), for: .normal)
        micReqBtn.setTitle(self.translate(text: .prepareMic), for: .selected)
        micReqBtn.titleLabel?.numberOfLines = 0
        micReqBtn.titleLabel?.lineBreakMode = .byWordWrapping
        micReqBtn.setImage(UIImage(named: "emptyTick"), for: .normal)
        micReqBtn.setImage(UIImage(named: "checkTick"), for: .selected)
        micReqBtn.tag = 5
        micReqBtn.addTarget(self, action: #selector(checkBoxTapped(_ :)), for: .touchUpInside)
        
        
        speechReqBtn.setTitle(self.translate(text: .prepareSpeech), for: .normal)
        speechReqBtn.setTitle(self.translate(text: .prepareSpeech), for: .selected)
        speechReqBtn.titleLabel?.numberOfLines = 0
        speechReqBtn.titleLabel?.lineBreakMode = .byWordWrapping
        speechReqBtn.setImage(UIImage(named: "emptyTick"), for: .normal)
        speechReqBtn.setImage(UIImage(named: "checkTick"), for: .selected)
        speechReqBtn.tag = 6
        speechReqBtn.addTarget(self, action: #selector(checkBoxTapped(_ :)), for: .touchUpInside)
    }
    
    @objc func checkBoxTapped(_ sender: UIButton) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        switch sender.tag {
            case 1:
                button1.isSelected = !button1.isSelected
            case 2:
                button2.isSelected = !button2.isSelected
            case 3:
                button3.isSelected = !button3.isSelected
            case 4:
                self.checkCameraSettings()
            case 5:
                self.checkMicrophoneSettings()
            case 6:
                self.checkSpeechSettings()
            default:
                return
        }
        self.reloadSubmitButton()
    }
    
    func reloadSubmitButton() {
        if button1.isSelected && button2.isSelected && button3.isSelected && camReqBtn.isSelected && micReqBtn.isSelected && speechReqBtn.isSelected {
            self.submitBtn.alpha = 1
            self.submitBtn.isEnabled = true
        } else {
            self.submitBtn.alpha = 0.3
            self.submitBtn.isEnabled = false
        }
    }
    
    func startSpeedTest() {
        if manager.needSpeedTest ?? false == true {
            self.showLoader()
            self.submitBtn.type = .loader
            self.manager.startSpeedTest { connectionStatus, kbPerSec in
                print(kbPerSec)
                self.hideLoader()
                if connectionStatus == .good {
                    DispatchQueue.main.async {
                        self.showToast(title: self.translate(text: .connectionSpeedSuccess), attachTo: self.view) {
                                return
                        }
                        self.speedStackView.isHidden = false
                        self.submitBtn.type = .submit
                        self.submitBtn.setTitle(self.translate(text: .continuePage), for: .normal)
                        self.submitBtn.onTap = {
                            self.getNextModule()
                        }
                        self.submitBtn.populate()
                    }
                } else {
                    DispatchQueue.main.async {
                        self.showToast(type:.fail, title: "Bağlantı hızı kötü", attachTo: self.view) {
                            return
                        }
                    }
                    // MARK: Bağlantı kalitesi düşük ise buradan yönlendirmelerinizi yapabilirsiniz
                }
            }
        } else {
            self.getNextModule()
        }
    }
    
    func getNextModule() {
        self.manager.sendPreparetatus(isCompleted: true) // panel tarafına bu modülün tamamlandığını bildiriyoruz.
        self.manager.getNextModule { nextVC in
            self.navigationController?.pushViewController(nextVC, animated: true)
        }
    }

}
