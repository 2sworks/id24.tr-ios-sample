//
//  SDKLivenessViewController.swift
//  NewTest
//
//  Created by Emir Beytekin on 14.11.2022.
//

import UIKit
import ARKit
import ReplayKit
import IdentifySDK

class SDKLivenessViewController: SDKBaseViewController, RPPreviewViewControllerDelegate {
    
    var timer: Timer?
    let waitSecs: TimeInterval = 2.0

    @IBOutlet weak var resetCamBtn: IdentifyButton!
    @IBOutlet weak var myCam: ARSCNView!
    @IBOutlet weak var pauseView: UIView!

    let configuration = ARFaceTrackingConfiguration()
    
    let recordingFileName = "liveness_recording.mp4"
    // following property is hardcoded on the server. increasing it here will not increase max size on the server.
    let recordingMaxFileSize = 25 // in MB
    var videoWriter: AVAssetWriter?
    var videoInput: AVAssetWriterInput?
    var fileOutputURL: URL?
    var recordingInProgress = false
    var recordingIsInterrupted = false
    
    var allowBlink = true
    var allowSmile = true
    var allowLeft = true
    var allowRight = true
    
    let screenRecorder = RPScreenRecorder.shared()
    
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
        configureScreenRecorder()
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
    
    func configureScreenRecorder() {
        screenRecorder.isMicrophoneEnabled = false
    }
    
    func startRecording(handler: ((Bool, (any Error)?) -> Void)? = nil) {
        guard !recordingInProgress && !screenRecorder.isRecording else {
            handler?(false, nil)
            return
        }
        recordingInProgress = true
        
        print("recording started")
        
        screenRecorder.startRecording() { error in
            if error != nil {
                self.recordingInProgress = false
                handler?(false, error)
            } else {
                handler?(true, nil)
            }
        }
    }
    
    func startCapture(handler: ((Bool, (any Error)?) -> Void)? = nil) {
        guard !recordingInProgress && !screenRecorder.isRecording else {
            handler?(false, nil)
            return
        }
        
        print("start capture called")
        
        recordingInProgress = true
        
        let tempDir = FileManager.default.temporaryDirectory
        fileOutputURL = tempDir.appendingPathComponent(recordingFileName)
        
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: fileOutputURL!.path) {
            do {
                try fileManager.removeItem(at: fileOutputURL!)
                print("Existing file deleted at \(fileOutputURL!)")
            } catch {
                print("Error deleting existing file: \(error)")
                self.recordingInProgress = false
                handler?(false, error)
                return
            }
        }
        
        do {
            videoWriter = try AVAssetWriter(outputURL: fileOutputURL!, fileType: .mp4)
            
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: UIScreen.main.bounds.width,
                AVVideoHeightKey: UIScreen.main.bounds.height,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 1_000_000
                ]
            ]
            
            videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            videoInput!.expectsMediaDataInRealTime = true
            videoWriter!.add(videoInput!)
        } catch {
            self.recordingInProgress = false
            print("Error setting up video writer: \(error.localizedDescription)")
            handler?(false, error)
            return
        }
                
        screenRecorder.startCapture(handler: { (sampleBuffer, sampleType, error) in
            guard error == nil else {
                print("error during capture: \(error!)")
                // most likely we can ignore this
                return
            }
            
            switch sampleType {
            case .video:
                guard CMSampleBufferDataIsReady(sampleBuffer) else {
                    return
                }

                if self.videoWriter!.status == .unknown {
                    let startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                    self.videoWriter!.startWriting()
                    self.videoWriter!.startSession(atSourceTime: startTime)
                }

                if let input = self.videoInput, input.isReadyForMoreMediaData {
                    input.append(sampleBuffer)
                } else {
                    // ignore, too many frames
                }

            default:
                // ignore
                break
            }
        }, completionHandler: { error in
            if let error = error {
                print("Error starting capture: \(error.localizedDescription)")
                self.recordingInProgress = false
                handler?(false, error)
            } else {
                print("Capture started successfully.")
                handler?(true, nil)
            }
        })
    }
    
    func stopCapture() {
        print("capture stopped")
        
        recordingInProgress = false

        screenRecorder.stopCapture { error in
            guard error == nil else {
                self.handleRecordingStopError(error)
                return
            }
            
            self.videoInput?.markAsFinished()
            self.videoWriter?.finishWriting {
                let fileManager = FileManager.default
                guard fileManager.fileExists(atPath: self.fileOutputURL!.path) else {
                    self.handleRecordingStopError(nil)
                    return
                }
                
                // do additional video compressing here if needed
                
                guard !self.isFileLargerThanMaxSize(fileURL: self.fileOutputURL!) else {
                    self.handleRecordingFileTooLarge()
                    return
                }
                
                do {
                    let data = try Data(contentsOf: self.fileOutputURL!, options: .mappedIfSafe)
                    self.uploadRecordingVideo(data: data)
                } catch {
                    self.handleRecordingStopError(error)
                }
            }
        }
    }
    
    func uploadRecordingVideo(data: Data, attempt: Int = 0) {
        if attempt == 3 {
            self.handleRecordindUploadError()
            return
        }
        self.manager.uploadLivenessVideo(videoData: data) { response, error in
            guard error == nil else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    self.uploadRecordingVideo(data: data, attempt: attempt + 1)
                    print("error upload: \(error!)")
                    return
                })
                return
            }
            self.getNextModule()
        }
    }
    
    func isFileLargerThanMaxSize(fileURL: URL) -> Bool {
        let fileManager = FileManager.default
        do {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            if let fileSize = attributes[.size] as? Int64 {
                // File size is in bytes
                print("FILE SIZE IS: \(Double(fileSize) / 1048576.0)")
                return fileSize > recordingMaxFileSize * 1024 * 1024
            }
        } catch {
            print("Error getting file attributes: \(error.localizedDescription)")
        }
        return false
    }
    
    func resetLiveness() {
        self.manager.resetLivenessTest()
        nextStep = nil
        self.pauseView.isHidden = true
        resumeSession()
        allowLeft = true
        allowRight = true
        allowBlink = true
        allowSmile = true
        getNextTest()
    }
    
    func handleRecordingStartError(_ error: Error) {
        let nsError = error as NSError
        let errorText: String
        let toastText: String
        if nsError.domain == RPRecordingErrorDomain && nsError.code == RPRecordingErrorCode.userDeclined.rawValue {
            errorText = self.translate(text: .livenessRecordingPermissionsMissing)
            toastText = self.translate(text: .livenessRecordingPermissionsMissingToast)
        } else {
            errorText = self.translate(text: .livenessRecordingFailedToStart)
            toastText = self.translate(text: .livenessRecordingFailedToast)
        }
        DispatchQueue.main.async {
            self.showToast(type:.fail, title: self.translate(text: .coreError), subTitle: toastText, attachTo: self.view) {
                self.oneButtonAlertShow(message: errorText, title1: self.translate(text: .livenessRecordingRetryAction)) {
                    self.resumeSession()
                }
            }
        }
    }
    
    func handleRecordingStopError(_ error: Error?) {
        if let error = error {
            print("error when stopping: \(error)")
        } else {
            print("error when stopping")
        }
        DispatchQueue.main.async {
            self.showToast(type:.fail, title: self.translate(text: .coreError), subTitle: self.translate(text: .livenessRecordingFailedToast), attachTo: self.view) {
                self.oneButtonAlertShow(message: self.translate(text: .livenessRecordingFailedToStop), title1: self.translate(text: .coreOk)) {
                    self.resetLiveness()
                }
            }
        }
    }
    
    func handleRecordingInterruptedError() {
        print("Recording interrupted error")
        DispatchQueue.main.async {
            self.showToast(type:.fail, title: self.translate(text: .coreError), subTitle: self.translate(text: .livenessRecordingFailedToast), attachTo: self.view) {
                self.oneButtonAlertShow(message: self.translate(text: .livenessRecordingInterrupted), title1: self.translate(text: .coreOk)) {
                    self.resetLiveness()
                }
            }
        }
    }
    
    func handleRecordingFileTooLarge() {
        print("Recording file too large")
        DispatchQueue.main.async {
            self.showToast(type:.fail, title: self.translate(text: .coreError), subTitle: self.translate(text: .livenessRecordingFailedToast), attachTo: self.view) {
                self.oneButtonAlertShow(message: self.translate(text: .livenessRecordingSizeTooLarge), title1: self.translate(text: .coreOk)) {
                    self.resetLiveness()
                }
            }
        }
    }
    
    func handleRecordindUploadError() {
        print("Recording upload error")
        DispatchQueue.main.async {
            self.showToast(type:.fail, title: self.translate(text: .coreError), subTitle: self.translate(text: .livenessRecordingFailedToast), attachTo: self.view) {
                self.oneButtonAlertShow(message: self.translate(text: .livenessRecordingFailedToUpload), title1: self.translate(text: .coreOk)) {
                    self.resetLiveness()
                }
            }
        }
    }
    
    
//    func shareVideo(_ videoURL: URL) {
//        let activityViewController = UIActivityViewController(activityItems: [videoURL], applicationActivities: nil)
//        
//        activityViewController.excludedActivityTypes = [
//            .assignToContact,
//            .print
//        ]
//
//        DispatchQueue.main.async {
//            self.present(activityViewController, animated: true, completion: nil)
//        }
//    }
    
    override func appMovedToBackground() {
        self.pauseSession()
        self.recordingIsInterrupted = true
    }
    
    override func appMovedToForeground() {
        if recordingIsInterrupted {
            self.handleRecordingInterruptedError()
        } else {
            self.pauseView.isHidden = false
        }
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
        startCapture() { started, error in
            guard error == nil else {
                self.handleRecordingStartError(error!)
                return
            }
            if self.nextStep != .completed {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    self.myCam.session.run(self.configuration)
                    self.hideLoader()
                })
            }
        }
//        startRecording() { started, error in
//            guard error == nil else {
//                self.handleRecordingStartError(error!)
//                return
//            }
//            if self.nextStep != .completed {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
//                    self.myCam.session.run(self.configuration)
//                    self.hideLoader()
//                })
//            }
//        }
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
                
//                self.stopRecording()
                self.stopCapture()
                
//                self.getNextModule()
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
