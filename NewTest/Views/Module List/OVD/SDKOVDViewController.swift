//
//  SDKOVDViewController.swift
//  NewTest
//
//  Created by Can Aksoy on 23.10.2025.
//

import UIKit
import Foundation
import IdentifySDK
import AVFoundation
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreMotion
import ImageIO

// MARK: - Capture Step
private enum CaptureStep: String { case front = "front", back = "back", ovd = "ovd" }

// MARK: - Capture View Controller
final class SDKOVDViewController: SDKBaseViewController {
    // AV
    private let session = AVCaptureSession()
    private var videoDevice: AVCaptureDevice?
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    // Speech
    private let instructionSpeaker = AVSpeechSynthesizer()

    // Queues
    private let visionQueue = DispatchQueue(label: "vision.queue")
    private let videoQueue = DispatchQueue(label: "video.queue")
    private let sessionQueue = DispatchQueue(label: "session.queue")

    // State
    private var currentStep: CaptureStep = .front
    private var captureReason: CaptureStep = .front
    private var isCapturing = false
    private var isOCRInFlight = false
    private var ovdCaptured = false

    // Flow configuration: OVD step can be enabled/disabled from outside.
    // Default: true (OVD aşaması aktif). Dışarıdan false yapılırsa FRONT -> BACK akışı kullanılır.
    var isOVDEnabled: Bool = true

    // Vision/CI
    private var lastRectObservation: VNRectangleObservation?

    // UI
    private let stepLabel = UILabel()
    private let guideLayer = CAShapeLayer()
    private let dimLayer = CAShapeLayer()
    private let detectedRectLayer = CAShapeLayer()

    // Debug
    private var noRectCounter = 0
    private var lastDebugLogTime: CFAbsoluteTime = 0
    private var debugLogEnabled = true

    // Guide geometry
    private var guideRectInView: CGRect = .zero
    private let idAspect: CGFloat = 85.6/54.0 // 1.586 ID-1

    // Motion & capture gates
    private let motionManager = CMMotionManager()
    private var stableDuration: TimeInterval = 0
    private let requiredStableDuration: TimeInterval = 0.6
    private let sharpnessThreshold: Float = 0.006
    private let movementArmThresholdRatio: CGFloat = 0.015 // daha küçük hareketle arm

    // OVD hareket tespiti (gyro/acc tabanlı)
    private var motionMoveScore = 0
    private var isDeviceMovingOVD: Bool { motionMoveScore >= 3 }

    // OVD ek state
    private var ovdBaselineRainbow: Float?
    private var ovdStartTs: CFAbsoluteTime = 0
    private var isReviewMode = false
    // Helper: stop all pipelines before review
    private func stopPipelinesBeforeReview() {
        // stop torch
        setTorch(on: false)
        // stop motion
        motionManager.stopDeviceMotionUpdates()
        // stop frames
        videoOutput.setSampleBufferDelegate(nil, queue: nil)
        // stop session
        sessionQueue.async { [weak self] in self?.session.stopRunning() }
        // silence logs
        debugLogEnabled = false
        isReviewMode = true
    }

    // Hysteresis & cooldown (frame scoring)
    private var readyScore: Int = 0
    private let readyScoreMax: Int = 15
    private let readyScoreFire: Int = 8
    private var lastReadyFireTs: CFAbsoluteTime = 0

    // Content thresholds
    private let aspectMin: CGFloat = 0.45
    private let aspectMax: CGFloat = 0.78

    /// Otomatik çekim için: dikdörtgenin guide alanını neredeyse tamamen doldurmasını istiyoruz.
    /// coverage = (rect ∩ guide) / guideArea  ≈ 1.0, tolerans ~%2–3
    private let coverageTarget: CGFloat = 1.0
    private let coverageTolerance: CGFloat = 0.30
    private var coverageMin: CGFloat { coverageTarget - coverageTolerance }  // ~0.97
    private var coverageMax: CGFloat { coverageTarget + coverageTolerance }  // ~1.03 (pratikte coverage ≤ 1.0

    private var ovdBaselineGlare: Float?
    private var ovdBaselineChroma: Float?
    private var lastRectDetectTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
    private var rectDetectInFlight = false
    private var stableSharpStart: CFAbsoluteTime? = nil

    // Shots
    private var frontShot: CIImage?
    private var ovdShot: CIImage?
    private var backShot: CIImage?
    private var frontUIImage: UIImage?
    private var ovdUIImage: UIImage?
    private var backUIImage: UIImage?

    // UX gating (içerik tabanlı)
    private var ovdArmed = false
    private var ovdMovementAccum: CGFloat = 0
    private var lastRectCenterY: CGFloat?
    private var ovdRectDetectInFlight = false
    private var mrzProbeInFlight = false
    private var mrzPresence = false
    private var ovdWhiteOut = false
    private var ovdHold = 0

    // Still foto için minimum dikdörtgen alan oranı (çok küçükse warp etme)
    private let stillMinRectAreaRatio: CGFloat = 0.05

    override func viewDidLoad() {
        super.viewDidLoad()
        self.manager.selectedCardType = .idCard
        view.backgroundColor = .black
        setupPreview()
        setupUI()
        speakInstruction("Kimlik ön yüzünü okutun", delay: 0.2)
        startMotionMonitoring()
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.setupSession()
            self.session.startRunning()
        }
    }
    // MARK: - Instruction Speaker
    private func speakInstruction(_ text: String, delay: TimeInterval = 0.0) {
        guard !text.isEmpty else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            self.instructionSpeaker.stopSpeaking(at: .immediate)
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "tr-TR")
            utterance.rate = 0.6
            self.instructionSpeaker.speak(utterance)
        }
    }

    // MARK: Setup
    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)
        videoDevice = device
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
            if #available(iOS 17.0, *) { photoOutput.maxPhotoQualityPrioritization = .quality }
        }
        if session.canAddOutput(videoOutput) {
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
            session.addOutput(videoOutput)
            if let con = videoOutput.connections.first {
                con.videoOrientation = .portrait
                if con.isVideoMirroringSupported { con.isVideoMirrored = false }
            }
        }
        session.commitConfiguration()
    }

    private func setupPreview() {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        // Guide layers
        guideLayer.lineWidth = 3
        guideLayer.fillColor = UIColor.clear.cgColor
        guideLayer.strokeColor = UIColor.white.withAlphaComponent(0.9).cgColor
        view.layer.addSublayer(guideLayer)
        dimLayer.fillRule = .evenOdd
        dimLayer.fillColor = UIColor.black.withAlphaComponent(0.8).cgColor
        view.layer.addSublayer(dimLayer)
        updateGuidePath()
        // Debug detected rect overlay
        detectedRectLayer.strokeColor = UIColor.systemYellow.cgColor
        detectedRectLayer.fillColor = UIColor.clear.cgColor
        detectedRectLayer.lineWidth = 2
        view.layer.addSublayer(detectedRectLayer)
    }

    private func setupUI() {
        stepLabel.textColor = .white
        stepLabel.font = .boldSystemFont(ofSize: 16)
        stepLabel.textAlignment = .center
        stepLabel.text = "Ön Yüz – Kılavuz içine hizalayın"
        stepLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stepLabel)
        NSLayoutConstraint.activate([
            stepLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 120),
            stepLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    // MARK: Debug / Helpers
    private func dlog(_ msg: @autoclosure () -> String) { guard debugLogEnabled else { return }
        let now = CFAbsoluteTimeGetCurrent()
        if now - lastDebugLogTime > 0.2 {
            //print("[DBG] " + msg())
            lastDebugLogTime = now } }

    private func currentCGImageOrientation() -> CGImagePropertyOrientation {
        let av = videoOutput.connections.first?.videoOrientation ?? .portrait
        switch av {
        case .portrait: return .right
        case .portraitUpsideDown: return .left
        case .landscapeRight: return .down
        case .landscapeLeft: return .up
        @unknown default: return .right }
    }

    private func showDetectedRect(_ rectObs: VNRectangleObservation?) {
        DispatchQueue.main.async {
            // Artık kullanıcıya sarı çerçeve göstermiyoruz.
            self.detectedRectLayer.path = nil
        }
    }


    private func setTorch(on: Bool, level: Float = 0.6) {
        guard let device = videoDevice, device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            if on {
                try device.setTorchModeOn(level: level)
                if device.isExposureModeSupported(.continuousAutoExposure) { device.exposureMode = .continuousAutoExposure }
                device.setExposureTargetBias(-0.7, completionHandler: nil)
            } else {
                device.torchMode = .off
            }
            device.unlockForConfiguration()
        } catch { print("Torch error: \(error)") }
    }

    private func startMotionMonitoring() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0/60.0
        let queue = OperationQueue()
        motionManager.startDeviceMotionUpdates(to: queue) { [weak self] data, _ in
            guard let self = self, let d = data else { return }
            let rot = d.rotationRate; let acc = d.userAcceleration
            let rotOk = (abs(rot.x) + abs(rot.y) + abs(rot.z)) < 0.5
            let accOk = (abs(acc.x) + abs(acc.y) + abs(acc.z)) < 0.15
            if rotOk && accOk { self.stableDuration += self.motionManager.deviceMotionUpdateInterval } else { self.stableDuration = 0 }
            let movingNow = (abs(rot.x) + abs(rot.y) + abs(rot.z)) > 0.8 || (abs(acc.x) + abs(acc.y) + abs(acc.z)) > 0.08
            self.motionMoveScore = max(0, min(10, self.motionMoveScore + (movingNow ? 1 : -1)))
        }
    }

    // MARK: Guide overlay
    private func updateGuidePath() {
        let horizMargin: CGFloat = 24
        let maxWidth = view.bounds.width - horizMargin * 2
        var width = maxWidth
        var height = width / idAspect
        let maxHeight = view.bounds.height * 0.45
        if height > maxHeight { height = maxHeight
            width = height * idAspect }
        let frameRect = CGRect(x: view.bounds.midX - width/2, y: view.bounds.midY - height/2, width: width, height: height)
        guideRectInView = frameRect
        let cornerRadius: CGFloat = 14
        let rectPath = UIBezierPath(roundedRect: frameRect, cornerRadius: cornerRadius)
        guideLayer.path = rectPath.cgPath
        guideLayer.lineWidth = 3
        guideLayer.fillColor = UIColor.clear.cgColor
        if guideLayer.strokeColor == nil { guideLayer.strokeColor = UIColor.white.withAlphaComponent(0.9).cgColor }
        let outer = UIBezierPath(rect: view.bounds)
        outer.append(rectPath)
        dimLayer.path = outer.cgPath
        dimLayer.fillRule = .evenOdd
        dimLayer.fillColor = UIColor.black.withAlphaComponent(0.8).cgColor
    }
    private func setGuideDetected(_ ok: Bool) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        guideLayer.strokeColor = (ok ? UIColor.systemGreen : UIColor.white.withAlphaComponent(0.9)).cgColor
        CATransaction.commit()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
        updateGuidePath()
    }

    private func docRectROI(in extent: CGRect) -> CGRect {
        if guideRectInView != .zero {
            let meta = previewLayer.metadataOutputRectConverted(fromLayerRect: guideRectInView)
            let x = meta.origin.x * extent.width + extent.origin.x
            let y = (1.0 - meta.origin.y - meta.size.height) * extent.height + extent.origin.y
            let w = meta.size.width * extent.width
            let h = meta.size.height * extent.height
            return CGRect(x: x, y: y, width: w, height: h)
        }
        let w = extent.width * 0.6
        let h = w / idAspect
        return CGRect(x: extent.midX - w/2, y: extent.midY - h/2, width: w, height: h)
    }

    // MARK: Capture
    private func capture(reason: CaptureStep) {
        // OCR/upload pipeline devam ederken veya mevcut bir foto işlenirken yeni çekim başlatma
        guard !isCapturing, !isOCRInFlight else {
            //dlog("capture(\(reason.rawValue)) ignored (isCapturing=\(isCapturing) isOCRInFlight=\(isOCRInFlight))")
            return
        }
        isCapturing = true
        captureReason = reason
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = photoOutput.isHighResolutionCaptureEnabled
        settings.isAutoStillImageStabilizationEnabled = true
        if #available(iOS 13.0, *) { settings.photoQualityPrioritization = .quality }
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    // MARK: OCR Pipeline
    private func processForOCR(ciImage: CIImage) {
        self.startOCR(ciImage: ciImage)
    }
    
    private func startOCR(ciImage: CIImage) {
        //print("[startOCR] entering step=\(currentStep.rawValue) isOCRInFlight=\(isOCRInFlight)")
        // Tek seferde tek OCR/upload pipeline çalışsın
        if isOCRInFlight {
            //dlog("startOCR ignored (in-flight) step=\(currentStep.rawValue)")
            return
        }
        isOCRInFlight = true
        let img = self.manager.makeUIImage(from: ciImage) ?? UIImage(ciImage: ciImage)
        switch self.currentStep {
        case .front:
            self.manager.startFrontIdOcr(frontImg:img) { resp, err in
                    print("[startOCR] startFrontIdOcr callback err=\(err != nil)")
                    if err != nil {
                        DispatchQueue.main.async {
                            
                            
                            // Kullanıcıya tekrar denemesi için rehberlik
                            self.stepLabel.text = "Ön Yüz – Tekrar deneyin, kılavuz içine hizalayın"
                            self.speakInstruction("Kimlik ön yüzünü tekrar kılavuz içine hizalayın ve sabit tutun", delay: 0.3)
                            
                            self.showToast(type: .fail,
                                           title: self.translate(text: .coreError),
                                           subTitle: err?.errorMessages ?? "",
                                           attachTo: self.view) {
                                return
                            }
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            self.setGuideDetected(false)
                            self.isOCRInFlight = false
                        }
                        
                    } else {
                        print(self.manager.sdkFrontInfo.asDictionary())
                        self.manager.uploadIdPhoto(idPhoto: img) { webResp in
                            if webResp.result == true {
                                // Front OCR + upload başarılı -> OVD adımına geç veya OVD devre dışı ise direkt BACK adımına
                                if self.isOVDEnabled {
                                    print("[FrontUpload] success, moving to OVD step")
                                    DispatchQueue.main.async {
                                        self.moveToOVDStep()
                                    }
                                } else {
                                    print("[FrontUpload] success, OVD disabled -> moving directly to Back step")
                                    DispatchQueue.main.async {
                                        self.moveToBackStepSkippingOVD()
                                    }
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    self.setGuideDetected(false)
                                    self.isOCRInFlight = false
                                }
                            } else {
                                // Front başarısız -> FRONT adımında kal, yeniden denemeye izin ver
                                DispatchQueue.main.async {
                                    self.showToast(title: self.translate(text: .coreError),
                                                   subTitle: "\(webResp.messages?.first ?? self.translate(text: .coreUploadError))",
                                                   attachTo: self.view) {
                                                    //self.hideLoader()
                                                   }
                                    // Kullanıcıya tekrar denemesi için rehberlik
                                    self.stepLabel.text = "Ön Yüz – Tekrar deneyin, kılavuz içine hizalayın"
                                    self.speakInstruction("Kimlik ön yüzünü tekrar kılavuz içine hizalayın ve sabit tutun", delay: 0.3)

                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    self.setGuideDetected(false)
                                    self.isOCRInFlight = false
                                }
                            }
                            //self.isOCRInFlight = false
                        }
                    }
                }
            
//            self.manager.uploadIdPhoto(idPhoto: img) { webResp in
//                if webResp.result == true {
//                    print("[FrontUpload] success, moving to OVD step")
//                    DispatchQueue.main.async {
//                        self.moveToOVDStep()
//                    }
//                } else {
//                    DispatchQueue.main.async {
//                        self.showToast(title: self.translate(text: .coreError),
//                                       subTitle: "\(webResp.messages?.first ?? self.translate(text: .coreUploadError))",
//                                       attachTo: self.view) { }
//                        self.stepLabel.text = "Ön Yüz – Tekrar deneyin, kılavuz içine hizalayın"
//                        self.speakInstruction("Kimlik ön yüzünü tekrar kılavuz içine hizalayın ve sabit tutun", delay: 0.3)
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                            self.setGuideDetected(false)
//                        }
//                    }
//                }
//                self.isOCRInFlight = false
//            }
        case .ovd:
            self.manager.uploadIdPhoto(idPhoto: img, selfieType: .frontIdOvd) { webResp in
                if webResp.result == true {
                    print("[FrontOVDUpload] success, moving to Back step")
                    DispatchQueue.main.async {
                        self.moveToBackStepAfterOVDSuccess()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        //self.setGuideDetected(false)
                        self.isOCRInFlight = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.showToast(title: self.translate(text: .coreError),
                                       subTitle: "\(webResp.messages?.first ?? self.translate(text: .coreUploadError))",
                                       attachTo: self.view) { }
                        self.prepareOVDRetry()
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        //self.setGuideDetected(false)
                        self.isOCRInFlight = false
                    }
                }
                //self.isOCRInFlight = false
            }
        case .back:
            self.manager.startBackIdOcr(frontImg: img) { resp, err in
                if err != nil {
                    DispatchQueue.main.async {
                        self.isOCRInFlight = false
                        self.showToast(type: .fail,
                                       title: self.translate(text: .coreError),
                                       subTitle: self.translate(text: .wrongBackSide),
                                       attachTo: self.view) { }
                    }
                } else {
                    print("Front OCR \(self.manager.sdkFrontInfo.asDictionary())")
                    print("Back OCR \(self.manager.sdkBackInfo.asDictionary())")
                    self.manager.uploadIdPhoto(idPhoto: img, selfieType: .backId) { webResp in
                        if webResp.result == true {
                            // Tüm akış başarıyla tamamlandı: capture session ve pipelineları durdur.
                            DispatchQueue.main.async {
                                self.stopPipelinesBeforeReview()
                                self.stepLabel.text = "✅ Kimlik doğrulama tamamlandı"
                                self.speakInstruction("Kimlik doğrulama tamamlandı", delay: 0.1)
                                self.manager.getNextModule { nextVC in
                                    self.navigationController?.pushViewController(nextVC, animated: true)
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.showToast(title: self.translate(text: .coreError),
                                               subTitle: "\(webResp.messages?.first ?? self.translate(text: .coreUploadError))",
                                               attachTo: self.view) { }
                            }
                        }
                        // Her durumda OCR pipeline kilitlenmesin diye en sonda sıfırla.
                        self.isOCRInFlight = false
                    }
                }
            }
        }
    }

    // FRONT başarılı olduktan sonra OVD adımına geçiş
    private func moveToOVDStep() {
        ovdBaselineRainbow = nil
        ovdBaselineGlare = nil
        ovdBaselineChroma = nil
        ovdArmed = false
        ovdMovementAccum = 0
        lastRectCenterY = nil
        ovdCaptured = false
        mrzPresence = false
        mrzProbeInFlight = false
        ovdStartTs = CFAbsoluteTimeGetCurrent()
        
        currentStep = .ovd
        
        DispatchQueue.main.async {
            self.stepLabel.text = "OVD – Flaş açık, kartı hafif yukarı/aşağı hareket ettirin"
            self.setGuideDetected(false)
            self.speakInstruction("Kimliği hafifçe yukarı aşağı döndürerek, gökkuşağı baskının görünmesini sağlayın", delay: 3.0)
            self.setTorch(on: true)
        }
    }

    // OVD sonrası server başarılı dönerse Back adımına geçiş
    private func moveToBackStepAfterOVDSuccess() {
        currentStep = .back
        ovdBaselineGlare = nil
        ovdBaselineChroma = nil
        ovdBaselineRainbow = nil
        ovdHold = 0
        mrzPresence = false
        mrzProbeInFlight = false
        ovdCaptured = true

        setTorch(on: false)
        setGuideDetected(false)
        stepLabel.text = "✅ OVD kaydedildi – Arka yüzü hizalayın"
        speakInstruction("Fotoğraf alındı", delay: 0.25)
        speakInstruction("Kimlik arka yüzü okutun", delay: 2.0)
    }

    // OVD opsiyonel olduğunda, FRONT başarılı olunca doğrudan BACK adımına geçiş
    private func moveToBackStepSkippingOVD() {
        currentStep = .back
        ovdBaselineGlare = nil
        ovdBaselineChroma = nil
        ovdBaselineRainbow = nil
        ovdHold = 0
        mrzPresence = false
        mrzProbeInFlight = false
        ovdCaptured = false

        setTorch(on: false)
        setGuideDetected(false)
        stepLabel.text = "✅ Ön yüz kaydedildi – Arka yüzü hizalayın"
        speakInstruction("Kimlik arka yüzü okutun", delay: 0.5)
    }

    // OVD upload başarısız olduğunda aynı adımda kal ve tekrar denemeye hazırla
    private func prepareOVDRetry() {
        ovdCaptured = false
        ovdBaselineRainbow = nil
        ovdBaselineGlare = nil
        ovdBaselineChroma = nil
        ovdHold = 0
        ovdStartTs = CFAbsoluteTimeGetCurrent()
        ovdWhiteOut = false

        stepLabel.text = "OVD – Tekrar deneyin, kartı hafifçe yukarı/aşağı hareket ettirin"
        speakInstruction("Kimliği hafifçe yukarı aşağı döndürerek, gökkuşağı baskıyı tekrar görünür yapın", delay: 0.3)
        setGuideDetected(false)
        setTorch(on: true)
    }
    

    // Gelişmiş: ROI/Orientation ayarlı dikdörtgen tespiti
    private func detectRectangle(in image: CIImage,
                                 useGuideROI: Bool,
                                 orientation: CGImagePropertyOrientation,
                                 showOverlay: Bool,
                                 completion: @escaping (VNRectangleObservation?) -> Void) {
        visionQueue.async {
            let req = VNDetectRectanglesRequest()
            req.minimumAspectRatio = 0.5
            req.minimumSize = 0.04
            req.quadratureTolerance = 25.0
            req.minimumConfidence = 0.5
            req.maximumObservations = 1

            var usedROI = false
            if useGuideROI, self.guideRectInView != .zero {
                let meta = self.previewLayer.metadataOutputRectConverted(fromLayerRect: self.guideRectInView)
                let roi = CGRect(x: meta.origin.x, y: 1.0 - meta.origin.y - meta.size.height, width: meta.size.width, height: meta.size.height)
                req.regionOfInterest = roi
                usedROI = true
            }

            let handler = VNImageRequestHandler(ciImage: image, orientation: orientation, options: [:])
            do { try handler.perform([req]) } catch {
                self.dlog("VN perform error: \(error)")
                completion(nil)
                return
            }

            var result = (req.results as? [VNRectangleObservation])?.first
            if result == nil && usedROI {
                let req2 = VNDetectRectanglesRequest()
                req2.minimumAspectRatio = 0.5
                req2.minimumSize = 0.04
                req2.quadratureTolerance = 25.0
                req2.minimumConfidence = 0.5
                req2.maximumObservations = 1
                let handler2 = VNImageRequestHandler(ciImage: image, orientation: orientation, options: [:])
                do { try handler2.perform([req2]) } catch {
                    self.dlog("VN2 error: \(error)")
                    completion(nil)
                    return
                }
                result = (req2.results as? [VNRectangleObservation])?.first
            }

            if let r = result {
                let s = self.manager.sideLengths(of: r)
                let ratio = min(s.w, s.h) / max(s.w, s.h)
                self.dlog(String(format: "Rect OK conf=%.2f ROI=%@ orient=%d short/long=%.3f", r.confidence, usedROI.description, orientation.rawValue, ratio))
                if showOverlay { self.showDetectedRect(result) }
            } else {
                self.dlog("Rect NONE ROI=\(usedROI) orient=\(orientation.rawValue)")
                if showOverlay { self.showDetectedRect(nil) }
            }
            completion(result)
        }
    }

    // Eski imza (canlı video için)
    private func detectRectangle(in image: CIImage, completion: @escaping (VNRectangleObservation?) -> Void) {
        detectRectangle(in: image, useGuideROI: true, orientation: currentCGImageOrientation(), showOverlay: true, completion: completion)
    }


    // MARK: - Çekim sonrası işleme


}

// MARK: - AVCapture Delegeleri
extension SDKOVDViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        defer { isCapturing = false }
        guard error == nil else { return }

        // 1) Raw JPEG verisini al
        guard let data = photo.fileDataRepresentation() else { return }

        // 2) CIImage yarat (henüz rotate/mirror etme)
        let originalCI = CIImage(data: data) ?? CIImage()

        // 3) Still foto üzerinde taze dikdörtgen tespiti ve doğru crop/warp
        let extent = originalCI.extent
        let roiInImage = docRectROI(in: extent)
        let ciRaw = manager.processCaptured(originalCI, roiInImage: roiInImage, step: captureReason.rawValue)

        print("[Capture] RAW resolution after rect-based crop: \(ciRaw.extent.size)")

        guard let ui = manager.makeUIImage(from: ciRaw) else { return }
        
        switch captureReason {
        case .front:
            frontShot = ciRaw
            frontUIImage = ui
            DispatchQueue.main.async {
                self.stepLabel.text = "✅ Ön yüz kaydedildi"
                self.speakInstruction("Kimlik ön yüz kontrol ediliyor", delay: 0.25)
            }
            processForOCR(ciImage: ciRaw)
        case .ovd:
            ovdShot = ciRaw
            ovdUIImage = ui
            setTorch(on: false)
            processForOCR(ciImage: ciRaw)
        case .back:
            backShot = ciRaw
            backUIImage = ui
            processForOCR(ciImage: ciRaw)
        }
    }
}


extension SDKOVDViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if isReviewMode { return }
        guard let buf = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ci = CIImage(cvImageBuffer: buf)
        switch currentStep {
        case .front, .back:
            let now = CFAbsoluteTimeGetCurrent()
            if !rectDetectInFlight && (now - lastRectDetectTime) > 0.18 {
                rectDetectInFlight = true
                lastRectDetectTime = now
                detectRectangle(in: ci) { [weak self] rectObs in
                    guard let self = self else { return }
                    self.lastRectObservation = rectObs
                    self.rectDetectInFlight = false
                    let extent = ci.extent
                    let roi = self.docRectROI(in: extent)
                    let sharp = self.manager.ovdTextureMean(ciImage: ci, roi: roi)
                    let stableOK = self.stableDuration >= self.requiredStableDuration
                    let hasRect = (rectObs != nil)

                    let nowTs = CFAbsoluteTimeGetCurrent()
                    if stableOK && (sharp >= self.sharpnessThreshold) {
                        if self.stableSharpStart == nil { self.stableSharpStart = nowTs }
                    } else { self.stableSharpStart = nil }

                    if self.currentStep == .back && hasRect && !self.mrzPresence && !self.mrzProbeInFlight {
                        self.mrzProbeInFlight = true
                        self.manager.probeMRZPresence(in: ci, roi: roi) { [weak self] ok in
                            guard let self = self else { return }
                            self.mrzPresence = ok
                            self.mrzProbeInFlight = false
                            self.dlog("MRZ presence=\(ok)")
                        }
                    }

                    var coverage: CGFloat = 0
                    var ratio: CGFloat = 0
                    var rectTooSmall = true
                    if let ro = rectObs {
                        let bb = self.manager.toImageRect(observation: ro, imageRect: ci.extent)
                        coverage = bb.intersection(roi).area / max(roi.area, 1)
                        let s = self.manager.sideLengths(of: ro)
                        ratio = min(s.w, s.h) / max(s.w, s.h)
                        let rectArea = bb.area
                        let minAcceptableArea = roi.area * 0.50
                        rectTooSmall = (rectArea < minAcceptableArea)
                        if rectTooSmall {
                            self.dlog("Rect too small: \(Int(bb.width))x\(Int(bb.height)) area=\(Int(rectArea)) minReq=\(Int(minAcceptableArea))")
                        }
                    }

                    let (_, _, whiteOutFB) = self.manager.ovdColorMetrics(ciImage: ci, roi: roi)
                    let glareBlock = whiteOutFB

                    let covf = Float(max(0, min(1, coverage)))
                    let sharpMin: Float = max(0.0035, 0.0035 + 0.001 * (0.8 - min(covf, 0.8)))
                    let sharpOk = (sharp >= sharpMin)

                    let aspectOk = (ratio >= self.aspectMin && ratio <= self.aspectMax)
                    let coverageOk = (coverage >= self.coverageMin && coverage <= self.coverageMax)
                    let stableOk = (self.stableDuration >= self.requiredStableDuration)

                    let allOk = hasRect && aspectOk && coverageOk && sharpOk && stableOk && !glareBlock

                    if allOk { self.readyScore = min(self.readyScore + 1, self.readyScoreMax) } else { self.readyScore = max(self.readyScore - 1, 0) }
                    if self.currentStep == .back && self.mrzPresence { self.readyScore = min(self.readyScore + 2, self.readyScoreMax) }

                    let mrzGateOK = (self.currentStep != .back) || self.mrzPresence
                    let canFire = mrzGateOK && (self.readyScore >= self.readyScoreFire) && ((now - self.lastReadyFireTs) > 1.0)

                    self.dlog(String(format: "why: AOK=%d COV=%d SHP=%d STB=%d MRZ=%d GLR=%d thr(shp)=%.4f ratio=%.3f cov=%.2f score=%d",
                                     aspectOk ? 1 : 0, coverageOk ? 1 : 0, sharpOk ? 1 : 0, stableOk ? 1 : 0, self.mrzPresence ? 1 : 0, glareBlock ? 1 : 0,
                                     sharpMin, ratio, coverage, self.readyScore))

                    DispatchQueue.main.async {
                        switch self.currentStep {
                        case .front:
                            if !hasRect { self.stepLabel.text = "Ön Yüz – Kılavuz içine hizalayın" }
                            else if coverage < self.coverageMin { self.stepLabel.text = "Ön Yüz – Biraz yaklaştırın" }
                            else { self.stepLabel.text = canFire ? "Ön Yüz – Hazır, çekiliyor…" : "Ön Yüz – Hizalandı, sabitleyin" }
                        case .back:
                            if !hasRect { self.stepLabel.text = "Arka Yüz – Kılavuz içine hizalayın" }
                            else if coverage < self.coverageMin { self.stepLabel.text = "Arka Yüz – Biraz yaklaştırın" }
                            else if !mrzGateOK { self.stepLabel.text = "Arka Yüz – MRZ (<<<) okunmadı, alt banda yaklaştırın" }
                            else { self.stepLabel.text = canFire ? "Arka Yüz – Hazır, çekiliyor…" : "Arka Yüz – Hizalandı, sabitleyin" }
                        case .ovd: break
                        }
                        self.setGuideDetected(canFire)
                    }

                    if canFire && !self.isCapturing && !self.isOCRInFlight {
                        self.lastReadyFireTs = now
                        self.readyScore = 0
                        self.capture(reason: self.currentStep)
                    }
                }
            }
        case .ovd:
            let extent = ci.extent
            let base = extent.insetBy(dx: extent.width*0.10, dy: extent.height*0.18)

            let g = self.manager.ovdGlareScore(ciImage: ci, roi: base)
            if self.ovdBaselineGlare == nil { self.ovdBaselineGlare = g }
            let (_, chroma, whiteOut) = self.manager.ovdColorMetrics(ciImage: ci, roi: base)
            if self.ovdBaselineChroma == nil { self.ovdBaselineChroma = chroma }
            let (rainbow, bins) = self.manager.ovdRainbowMaxScoreDetailed(in: ci, baseROI: base)
            if self.ovdBaselineRainbow == nil { self.ovdBaselineRainbow = rainbow }
            let deltaRainbow = rainbow - (self.ovdBaselineRainbow ?? rainbow)
            self.ovdWhiteOut = whiteOut

            let rainbowThr: Float = 0.055
            let deltaThr:   Float = 0.030
            let minBins     = 4
            let chromaRise: Float = 0.006
            let chromaOKAbs = chroma > 0.022
            let chromaOKRise = (chroma - (self.ovdBaselineChroma ?? chroma)) >= chromaRise
            let chromaOK = chromaOKAbs || chromaOKRise

            let binsOK = (bins >= minBins)
            let rainbowOK = (rainbow >= rainbowThr) || (deltaRainbow >= deltaThr)
            let pass = (!whiteOut) && binsOK && chromaOK && rainbowOK
            if pass { self.ovdHold = min(self.ovdHold + 1, 12) } else { self.ovdHold = max(self.ovdHold - 1, 0) }
            let minOvdTimeOk = (CFAbsoluteTimeGetCurrent() - self.ovdStartTs) > 0.8
            let hit = minOvdTimeOk && (self.ovdHold >= 4)

            self.dlog("OVD pass=\(pass) bins=\(bins) rnb=\(String(format: "%.3f", rainbow)) Δr=\(String(format: "%.3f", deltaRainbow)) whiteOut=\(whiteOut) hold=\(self.ovdHold)")

            DispatchQueue.main.async {
                if whiteOut { self.stepLabel.text = "OVD – Çok beyaz, kartı hafifçe açılı tutun" }
                self.setGuideDetected(hit)
            }

            if hit && !self.isCapturing && !self.ovdCaptured && !self.isOCRInFlight {
                self.ovdCaptured = true
                DispatchQueue.main.async { self.stepLabel.text = "OVD – Parlama yakalandı, çekiliyor…" }
                self.capture(reason: .ovd)
            }
        }
    }
}

// MARK: - Vision/Geometry yardımcıları
private extension CGPoint { func toImagePoint(_ rect: CGRect) -> CGPoint { CGPoint(x: x*rect.width + rect.origin.x, y: (1-y)*rect.height + rect.origin.y) } }
private extension CGRect { var area: CGFloat { width * height } }
