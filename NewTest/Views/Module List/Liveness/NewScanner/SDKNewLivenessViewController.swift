//
//  SDKNewLivenessViewController.swift
//  NewTest
//
//  Created by Emir Beytekin on 27.02.2024.
//

import UIKit
import ARKit
import IdentifySDK

class SDKNewLivenessViewController: SDKBaseViewController {

    @IBOutlet weak var myCam: ARSCNView!
    var timer: Timer?
    let waitSecs: TimeInterval = 2.0
    let configuration = ARFaceTrackingConfiguration()
    var allowBlink = true
    var allowSmile = true
    var allowLeft = true
    var allowRight = true
    @IBOutlet weak var stepInfoLbl: UILabel!
    var nextStep: LivenessTestStep?
    var currentLivenessType: OCRType? = .selfie
    @IBOutlet weak var pauseView: UIView!
    @IBOutlet weak var resetCamBtn: IdentifyButton!
    let progressBar = IdentifyProgressBar()
    let maskedView = MaskedView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
    var currentBackColor = UIColor.black.withAlphaComponent(0.8)
    var counter: Double = 0
    var runCounter = 0
    
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
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
                DispatchQueue.main.async {
                    self.maskedView.backgroundColor = self.currentBackColor
                }
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

}


extension SDKNewLivenessViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        DispatchQueue.main.async {
            self.setupProgressBar()
        }
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
    
    private func sendScreenShot(uploaded: @escaping(Bool) -> ()) {
        let image = myCam.snapshot()
        DispatchQueue.main.async {
            self.showLoader()
        }
        self.pauseSession()
        
        runCounter += 1
        self.setPercent(percent: Double(runCounter) * 0.25)
        DispatchQueue.main.async {
            self.maskedView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.8)
        }
        
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

extension SDKNewLivenessViewController { // yeni tasarım için
    
    func setupProgressBar() {
        let screenSize = UIScreen.main.bounds
        progressBar.frame = CGRect(x: 0, y: (screenSize.width / 2) - 48, width: screenSize.width, height: screenSize.width)
        progressBar.trackColor = #colorLiteral(red: 0.1977782398, green: 0.1977782398, blue: 0.1977782398, alpha: 0.5)
        progressBar.gradients = [#colorLiteral(red: 0, green: 0.6588235294, blue: 0.7725490196, alpha: 1), #colorLiteral(red: 1, green: 1, blue: 0.4941176471, alpha: 1)]
        progressBar.lineDashPattern = [10, 10]
        progressBar.font = .systemFont(ofSize: 0)
        progressBar.textColor = .white
        progressBar.lineHeight = 10
        self.myCam.addSubview(self.progressBar)
        
        self.maskedView.alpha = 0
        self.maskedView.backgroundColor = self.currentBackColor
        
        maskedView.transform = CGAffineTransform(scaleX: 10, y:10)
        
        UIView.animate(withDuration: 1, delay: 0, options: .curveEaseIn, animations: {
            self.maskedView.alpha = 1
            self.maskedView.transform = .identity
            self.myCam.addSubview(self.maskedView)
        }, completion: nil)
        
    }
    
    func setPercent(percent: Double) {
        counter = percent
        let totalSteps = Int(percent * 100)
        for _ in 0..<totalSteps {
            counter += 0.01
            DispatchQueue.main.async {
                self.progressBar.progress = Double(Float(percent))
            }
        }
    }
    
}



class MaskedView: UIView {
    
    let maskLayer = CAShapeLayer()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let screenSize = UIScreen.main.bounds
        let maskPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height))
        let ovalPath = UIBezierPath(ovalIn: CGRect(x: 0, y: (screenSize.width / 2) - 48, width: bounds.width, height: bounds.width))
        maskPath.append(ovalPath.reversing())
        maskLayer.path = maskPath.cgPath
        layer.mask = maskLayer
    }
}
