//
//  SDKLivenessViewController.swift
//  NewTest
//
//  Created by Emir Beytekin on 14.11.2022.
//

import UIKit
import ARKit
import IdentifySDK

class SDKLivenessViewController: SDKBaseViewController {
    
    var timer: Timer?
    let waitSecs: TimeInterval = 2.0

    @IBOutlet weak var resetCamBtn: IdentifyButton!
    @IBOutlet weak var myCam: ARSCNView!
    let configuration = ARFaceTrackingConfiguration()
    @IBOutlet weak var pauseView: UIView!
    
    var allowBlink = true
    var allowSmile = true
    var allowLeft = true
    var allowRight = true
    
    private var lookCamTxt: String {
        return languageManager.translate(key: .livenessLookCam)
    }
    
    private var blinkEyeTxt: String {
        return languageManager.translate(key: .livenessStep2)
    }
    
    private var headLeftTxt: String {
        return languageManager.translate(key: .livenessStep4)
    }
    
    private var headRightTxt: String {
        return languageManager.translate(key: .livenessStep3)
    }
    
    private var smileTxt: String {
        return languageManager.translate(key: .livenessStep1)
    }
    
    @IBOutlet weak var stepInfoLbl: UILabel!
    var nextStep: LivenessTestStep?
    
    var currentLivenessType: OCRType? = .selfie
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.pauseSession()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if nextStep == nil {
            self.getNextTest()
        } else if nextStep == .completed {
            self.pauseSession()
            self.getNextModule()
        }
        self.resumeSession()
    }
    
    override func appMovedToBackground() {
        self.pauseSession()
    }
    
    override func appMovedToForeground() {
        self.pauseView.isHidden = false
    }
    
    private func appendInfoText(_ text: String?) {
        DispatchQueue.main.async {
            self.stepInfoLbl.text = text
        }
    }
    
    private func pauseSession() {
        if self.nextStep != .completed {
            DispatchQueue.main.async {
                self.myCam.session.pause()
            }
        }
    }
    
    private func resumeSession() {
        if self.nextStep != .completed {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                self.myCam.session.run(self.configuration)
                self.hideLoader()
            })
        }
    }
    
    private func killArSession() {
        myCam?.session.pause()
        myCam?.removeFromSuperview()
        myCam = nil
    }
    
    private func setupUI() {
        if ARFaceTrackingConfiguration.isSupported {
            self.resumeSession()
        } else {
            self.showToast(type:.fail, title: self.translate(text: .coreError), subTitle: "Cihazınız ARFace Desteklemiyor", attachTo: self.view) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                    self.skipModuleAct()
                })
            }
        }
        self.getNextTest()
        myCam.delegate = self
        self.resetCamBtn.onTap = {
            if self.nextStep == nil {
                self.getNextTest()
            }
            self.pauseView.isHidden = true
            self.resumeSession()
        }
        self.appendInfoText(self.lookCamTxt)
        self.resetCamBtn.type = .info
        self.resetCamBtn.populate()
    }
    
    private func getNextTest() {
        manager.getNextLivenessTest { nextStep, completed in
            if completed ?? false {
                self.nextStep = .completed
                self.pauseSession()
                self.getNextModule() 
            } else {
                self.nextStep = nextStep
            }
        }
    }
    
    private func getNextModule() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            self.manager.getNextModule { nextVC in
                self.killArSession()
                self.navigationController?.pushViewController(nextVC, animated: true)
            }
        })
    }
    
    private func sendScreenShot(uploaded: @escaping(Bool) -> ()) {
        let image = myCam.snapshot()
        DispatchQueue.main.async {
            self.showLoader()
        }
        self.pauseSession()
        
        manager.uploadIdPhoto(idPhoto: image, selfieType: self.currentLivenessType ?? .signature) { uploadResp in
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            if uploadResp.result == true {
                uploaded(true)
                if self.nextStep == .completed {
                    self.resumeSession()
                } else {
                    self.timer = Timer.scheduledTimer(withTimeInterval: self.waitSecs, repeats: false) { _ in
                        self.resumeSession()
                        self.timer?.invalidate()
                        self.timer = nil
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.showToast(type:.fail, title: self.translate(text: .coreError), subTitle: self.translate(text: .coreUploadError), attachTo: self.view) {
                        self.oneButtonAlertShow(message: "Fotoğraf yüklenirken hata oluştu, sonraki adıma geçiliyor.", title1: "Tamam") {
                            uploaded(false)
                            self.resumeSession()
                        }
                    }
                }
            }
            
        }
    }
}

extension SDKLivenessViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let faceMesh = ARSCNFaceGeometry(device: myCam.device!)
        let node = SCNNode(geometry: faceMesh)
        node.geometry?.firstMaterial?.fillMode = .lines
        node.geometry?.firstMaterial?.transparency = 0
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let faceAnchor = anchor as? ARFaceAnchor, let faceGeometry = node.geometry as? ARSCNFaceGeometry {
            faceGeometry.update(from: faceAnchor.geometry)
            expression(anchor: faceAnchor, node: node)
        }
    }
    
    func checkTurnLeft(jawVal:Decimal) {
        appendInfoText(self.headLeftTxt)
        hideLoader()
        self.currentLivenessType = .headToLeft
        if abs(jawVal) > 0.15 {
            self.pauseSession()
            self.allowLeft = false
            sendScreenShot(uploaded: { resp in
                self.getNextTest()
            })
        }
    }
    
    func checkTurnRight(jawVal:Decimal) {
        appendInfoText(self.headRightTxt)
        hideLoader()
        self.currentLivenessType = .headToRight
        if abs(jawVal) > 0.15 {
            self.pauseSession()
            self.allowRight = false
            sendScreenShot(uploaded: { resp in
                self.getNextTest()
            })
        }
    }
    
    func blinkEyes(leftEye: Decimal, rightEye: Decimal, jawLeft: Decimal, jawRight: Decimal) {
        appendInfoText(self.blinkEyeTxt)
        hideLoader()
        self.currentLivenessType = .blinking
        if abs(leftEye) > 0.35 && abs(rightEye) > 0.35 && abs(jawLeft) < 0.03 && abs(jawRight) < 0.03 {
            self.pauseSession()
            self.allowBlink = false
            sendScreenShot(uploaded: { resp in
                self.getNextTest()
            })
        }
    }
    
    func detectSmile(smileLeft: Decimal, smileRight: Decimal, jawLeft: Decimal, jawRight: Decimal) {
        appendInfoText(self.smileTxt)
        hideLoader()
        self.currentLivenessType = .smiling
        if smileLeft + smileRight > 1.2 && abs(jawLeft) < 0.03 && abs(jawRight) < 0.03 {
            self.pauseSession()
            self.allowSmile = false
            sendScreenShot(uploaded: { resp in
                self.getNextTest()
            })
        }
    }
    
    func expression(anchor: ARFaceAnchor, node: SCNNode) {
        let smileLeft = anchor.blendShapes[.mouthSmileLeft]?.decimalValue
        let smileRight = anchor.blendShapes[.mouthSmileRight]?.decimalValue
        let jawLeft = anchor.blendShapes[.jawLeft]?.decimalValue
        let jawRight = anchor.blendShapes[.jawRight]?.decimalValue
        let leftEyeOpen = anchor.blendShapes[.eyeBlinkLeft]?.decimalValue
        let rightEyeOpen = anchor.blendShapes[.eyeBlinkRight]?.decimalValue
       
        
        switch self.nextStep {
            case .turnLeft:
                if allowLeft {
                    self.checkTurnLeft(jawVal: jawLeft ?? 0)
                }
                break
            case .turnRight:
                if allowRight {
                    self.checkTurnRight(jawVal: jawRight ?? 0)
                }
                break
            case .smile:
                if allowSmile {
                    self.detectSmile(smileLeft: smileLeft ?? 0, smileRight: smileRight ?? 0, jawLeft: jawLeft ?? 0, jawRight: jawRight ?? 0)
                }
                break
            case .blinkEyes:
                if allowBlink {
                    self.blinkEyes(leftEye: leftEyeOpen ?? 0, rightEye: rightEyeOpen ?? 0, jawLeft: jawLeft ?? 0, jawRight: jawRight ?? 0)
                }
                break
            default:
                return
        }
    }
    
}
