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
    // Default: true (OVD aşaması aktif). false yapılırsa FRONT -> BACK akışı kullanılır.
    var isOVDEnabled: Bool = true

    // UI
    private let stepLabel = UILabel()
    private let guideLayer = CAShapeLayer()
    private let dimLayer = CAShapeLayer()

    // Guide geometry
    private var guideRectInView: CGRect = .zero
    private let idAspect: CGFloat = 85.6/54.0 // 1.586 ID-1

    // Motion & capture gates
    private let motionManager = CMMotionManager()
    private var stableDuration: TimeInterval = 0
    private let requiredStableDuration: TimeInterval = 0.6
    private let sharpnessThreshold: Float = 0.006

    // OVD hareket tespiti (gyro/acc tabanlı)
    private var motionMoveScore = 0

    // OVD ek state
    private var ovdBaselineRainbow: Float?
    private var ovdStartTs: CFAbsoluteTime = 0

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

    // UX gating (içerik tabanlı)
    private var mrzProbeInFlight = false
    private var mrzPresence = false
    private var ovdWhiteOut = false
    private var ovdHold = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        self.manager.selectedCardType = .idCard
        view.backgroundColor = .black
        setupPreview()
        setupUI()
        speakInstruction(self.translate(text: .ovdScanFrontSide), delay: 0.2)
        startMotionMonitoring()
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.setupSession()
            self.session.startRunning()
            // Session başladıktan sonra odak noktasını ayarla
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.setFocusPointToCenter()
            }
        }
    }
    // MARK: - Instruction Speaker
    private func speakInstruction(_ text: String, delay: TimeInterval = 0.0) {
        guard !text.isEmpty else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            self.instructionSpeaker.stopSpeaking(at: .immediate)
            let utterance = AVSpeechUtterance(string: text)
            switch self.languageManager.sdkManager.sdkLang {
            case .tr:
                utterance.voice = AVSpeechSynthesisVoice(language: "tr-TR")
            case .eng:
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            case .de:
                utterance.voice = AVSpeechSynthesisVoice(language: "de-DE")
            case .ru:
                utterance.voice = AVSpeechSynthesisVoice(language: "ru-RU")
            case .az:
                utterance.voice = AVSpeechSynthesisVoice(language: "az-AZ")
            case .none, .some(_):
                utterance.voice = AVSpeechSynthesisVoice(language: "tr-TR")
            }
            utterance.rate = 0.6
            self.instructionSpeaker.speak(utterance)
        }
    }

    // MARK: Setup
    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        // Yakın mesafe için en iyi kamerayı seç
        var device: AVCaptureDevice?
        
        // Önce ultra-wide kamera dene (iPhone 11+ için yakın mesafe için daha iyi)
        // iOS 13+ ile ultra-wide kamera desteği var
        if #available(iOS 13.0, *) {
            if let ultraWide = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) {
                device = ultraWide
            }
        }
        
        // Ultra-wide bulunamazsa wide kamera kullan
        if device == nil {
            device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        }
        
        guard let selectedDevice = device,
              let input = try? AVCaptureDeviceInput(device: selectedDevice),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }
        
        session.addInput(input)
        videoDevice = selectedDevice
        
        // Odak ve exposure ayarlarını optimize et
        do {
            try selectedDevice.lockForConfiguration()
            
            // Continuous auto focus (yakın mesafe için daha iyi)
            if selectedDevice.isFocusModeSupported(.continuousAutoFocus) {
                selectedDevice.focusMode = .continuousAutoFocus
            }
            
            // Macro mod aktifleştir (iOS 15+ ve desteklenen cihazlarda)
            if #available(iOS 15.0, *) {
                // Macro mod için özel odak ayarı (sadece desteklenen cihazlarda)
                if selectedDevice.isLockingFocusWithCustomLensPositionSupported {
                    // Minimum odak mesafesi için lens position ayarla
                    // 0.0 = minimum odak mesafesi (yakın mesafe için)
                    selectedDevice.setFocusModeLocked(lensPosition: 0.0) { _ in }
                }
            }
            
            // iPhone 11 gibi eski cihazlar için: Auto focus range restriction
            // Yakın mesafe odak için optimize et
            if #available(iOS 13.0, *) {
                // Auto focus range restriction (yakın mesafe için)
                if selectedDevice.isAutoFocusRangeRestrictionSupported {
                    selectedDevice.autoFocusRangeRestriction = .near
                }
            }
            
            // Exposure ayarları
            if selectedDevice.isExposureModeSupported(.continuousAutoExposure) {
                selectedDevice.exposureMode = .continuousAutoExposure
            }
            
            // Subject area change monitoring (yakın mesafe değişikliklerini algıla)
            selectedDevice.isSubjectAreaChangeMonitoringEnabled = true
            
            selectedDevice.unlockForConfiguration()
        } catch {
            print("⚠️ Kamera konfigürasyon hatası: \(error)")
        }
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
    }

    private func setupUI() {
        stepLabel.textColor = .white
        stepLabel.font = .boldSystemFont(ofSize: 16)
        stepLabel.textAlignment = .center
        stepLabel.text = self.translate(text: .ovdFrontAlignGuide)
        stepLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stepLabel)
        NSLayoutConstraint.activate([
            stepLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 120),
            stepLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func currentCGImageOrientation() -> CGImagePropertyOrientation {
        let av = videoOutput.connections.first?.videoOrientation ?? .portrait
        switch av {
        case .portrait: return .right
        case .portraitUpsideDown: return .left
        case .landscapeRight: return .down
        case .landscapeLeft: return .up
        @unknown default: return .right }
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

    // Odak noktasını guide alanının merkezine ayarla
    private func setFocusPointToCenter() {
        guard let device = videoDevice else { return }
        let focusPoint = CGPoint(x: 0.5, y: 0.5) // Ekranın merkezi
        
        do {
            try device.lockForConfiguration()
            
            if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusPointOfInterest = focusPoint
                device.focusMode = .continuousAutoFocus
            }
            
            if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposurePointOfInterest = focusPoint
                device.exposureMode = .continuousAutoExposure
            }
            
            device.unlockForConfiguration()
        } catch {
            print("⚠️ Odak noktası ayarlama hatası: \(error)")
        }
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
        let isBackStep = (currentStep == .back || captureReason == .back)
        let paddingFactor: CGFloat = isBackStep ? 1.20 : 1.0 // Arka yüz için %20 genişletme
        
        if guideRectInView != .zero {
            let meta = previewLayer.metadataOutputRectConverted(fromLayerRect: guideRectInView)
            var x = meta.origin.x * extent.width + extent.origin.x
            var y = (1.0 - meta.origin.y - meta.size.height) * extent.height + extent.origin.y
            var w = meta.size.width * extent.width
            var h = meta.size.height * extent.height
            
            // Arka yüz için ROI'yi genişlet
            if isBackStep {
                let centerX = x + w / 2
                let centerY = y + h / 2
                w *= paddingFactor
                h *= paddingFactor
                x = centerX - w / 2
                y = centerY - h / 2
                
                // ROI'nin extent sınırlarını aşmamasını sağla
                x = max(extent.origin.x, min(x, extent.origin.x + extent.width - w))
                y = max(extent.origin.y, min(y, extent.origin.y + extent.height - h))
                w = min(w, extent.width - (x - extent.origin.x))
                h = min(h, extent.height - (y - extent.origin.y))
            }
            
            return CGRect(x: x, y: y, width: w, height: h)
        }
        let w = extent.width * 0.6 * paddingFactor
        let h = (w / paddingFactor) / idAspect * paddingFactor
        return CGRect(x: extent.midX - w/2, y: extent.midY - h/2, width: w, height: h)
    }

    // MARK: Capture
    private func capture(reason: CaptureStep) {
        // OCR/upload pipeline devam ederken veya mevcut bir foto işlenirken yeni çekim başlatma
        guard !isCapturing, !isOCRInFlight else {
            //print("❌ capture(\(reason.rawValue)) ignored: isCapturing=\(isCapturing) isOCRInFlight=\(isOCRInFlight)")
            return
        }
        //print("📸 capture(\(reason.rawValue)) called - starting photo capture")
        isCapturing = true
        captureReason = reason
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = photoOutput.isHighResolutionCaptureEnabled
        settings.isAutoStillImageStabilizationEnabled = true
        if #available(iOS 13.0, *) { settings.photoQualityPrioritization = .quality }
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    // MARK: OCR Pipeline
    private func startOCR(ciImage: CIImage) {
        //print("[startOCR] entering step=\(currentStep.rawValue) isOCRInFlight=\(isOCRInFlight)")
        // Tek seferde tek OCR/upload pipeline çalışsın
        if isOCRInFlight {
            //print("startOCR ignored (in-flight) step=\(currentStep.rawValue)")
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
                            self.stepLabel.text = self.translate(text: .ovdFrontRetryAlign)
                            self.speakInstruction(self.translate(text: .ovdFrontRetryAlignSpeech), delay: 0.3)
                            
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
                                    self.stepLabel.text = self.translate(text: .ovdFrontRetryAlign)
                                    self.speakInstruction(self.translate(text: .ovdFrontRetryAlignSpeech), delay: 0.3)

                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    self.setGuideDetected(false)
                                    self.isOCRInFlight = false
                                }
                            }
                        }
                    }
                }
            
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
                                self.stepLabel.text = self.translate(text: .ovdVerificationCompleted)
                                self.speakInstruction(self.translate(text: .ovdVerificationCompletedSpeech), delay: 0.1)
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
        ovdCaptured = false
        mrzPresence = false
        mrzProbeInFlight = false
        ovdStartTs = CFAbsoluteTimeGetCurrent()
        
        currentStep = .ovd
        
        DispatchQueue.main.async {
            self.stepLabel.text = self.translate(text: .ovdFlashMoveCard)
            self.setGuideDetected(false)
            self.speakInstruction(self.translate(text: .ovdRotateRainbowSpeech), delay: 3.0)
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
        stepLabel.text = self.translate(text: .ovdSavedAlignBack)
        speakInstruction(self.translate(text: .ovdPhotoTaken), delay: 0.25)
        speakInstruction(self.translate(text: .ovdScanBackSide), delay: 2.0)
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
        stepLabel.text = self.translate(text: .ovdFrontSavedAlignBack)
        speakInstruction(self.translate(text: .ovdScanBackSide), delay: 0.5)
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

        stepLabel.text = self.translate(text: .ovdRetryMoveCard)
        speakInstruction(self.translate(text: .ovdRotateRainbowRetrySpeech), delay: 0.3)
        setGuideDetected(false)
        setTorch(on: true)
    }
    
    // Gelişmiş: ROI/Orientation ayarlı dikdörtgen tespiti
    private func detectRectangle(in image: CIImage,
                                 useGuideROI: Bool,
                                 orientation: CGImagePropertyOrientation,
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
                //print("VN perform error: \(error)")
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
                    //print("VN2 error: \(error)")
                    completion(nil)
                    return
                }
                result = (req2.results as? [VNRectangleObservation])?.first
            }

            if let r = result {
                let s = self.manager.sideLengths(of: r)
                let ratio = min(s.w, s.h) / max(s.w, s.h)
                //print(String(format: "Rect OK conf=%.2f ROI=%@ orient=%d short/long=%.3f", r.confidence, usedROI.description, orientation.rawValue, ratio))
            }
            completion(result)
        }
    }

    // Eski imza (canlı video için)
    private func detectRectangle(in image: CIImage, completion: @escaping (VNRectangleObservation?) -> Void) {
        detectRectangle(in: image, useGuideROI: true, orientation: currentCGImageOrientation(), completion: completion)
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
            DispatchQueue.main.async {
                self.stepLabel.text = self.translate(text: .ovdFrontSaved)
                self.speakInstruction(self.translate(text: .ovdFrontChecking), delay: 0.25)
            }
            startOCR(ciImage: ciRaw)
        case .ovd:
            setTorch(on: false)
            startOCR(ciImage: ciRaw)
        case .back:
            startOCR(ciImage: ciRaw)
        }
    }
}


extension SDKOVDViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

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
                    self.rectDetectInFlight = false
                    let extent = ci.extent
                    let roi = self.docRectROI(in: extent)
                    let sharp = self.manager.ovdTextureMean(ciImage: ci, roi: roi)
                    let stableOK = self.stableDuration >= self.requiredStableDuration
                    let hasRect = (rectObs != nil)


                    if self.currentStep == .back && hasRect && !self.mrzPresence && !self.mrzProbeInFlight {
                        self.mrzProbeInFlight = true
                        self.manager.probeMRZPresence(in: ci, roi: roi) { [weak self] ok in
                            guard let self = self else { return }
                            self.mrzPresence = ok
                            self.mrzProbeInFlight = false
                            //print("MRZ presence=\(ok)")
                        }
                    }

                    var coverage: CGFloat = 0
                    var ratio: CGFloat = 0
                    if let ro = rectObs {
                        let bb = self.manager.toImageRect(observation: ro, imageRect: ci.extent)
                        coverage = bb.intersection(roi).area / max(roi.area, 1)
                        let s = self.manager.sideLengths(of: ro)
                        ratio = min(s.w, s.h) / max(s.w, s.h)
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

                    //print(String(format: "why: AOK=%d COV=%d SHP=%d STB=%d MRZ=%d GLR=%d thr(shp)=%.4f ratio=%.3f cov=%.2f score=%d", aspectOk ? 1 : 0, coverageOk ? 1 : 0, sharpOk ? 1 : 0, stableOk ? 1 : 0, self.mrzPresence ? 1 : 0, glareBlock ? 1 : 0, sharpMin, ratio, coverage, self.readyScore))

                    DispatchQueue.main.async {
                        switch self.currentStep {
                        case .front:
                            if !hasRect { self.stepLabel.text = self.translate(text: .ovdFrontAlignGuide) }
                            else if coverage < self.coverageMin { self.stepLabel.text = self.translate(text: .ovdFrontMoveCloser) }
                            else { self.stepLabel.text = canFire ? self.translate(text: .ovdFrontReadyCapturing) : self.translate(text: .ovdFrontAlignedHold) }
                        case .back:
                            if !hasRect { self.stepLabel.text = self.translate(text: .ovdBackAlignGuide) }
                            else if coverage < self.coverageMin { self.stepLabel.text = self.translate(text: .ovdBackMoveCloser) }
                            else if !mrzGateOK { self.stepLabel.text = self.translate(text: .ovdBackMrzNotRead) }
                            else { self.stepLabel.text = canFire ? self.translate(text: .ovdBackReadyCapturing) : self.translate(text: .ovdBackAlignedHold) }
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

            let (_, chroma, whiteOut) = self.manager.ovdColorMetrics(ciImage: ci, roi: base)
            if self.ovdBaselineChroma == nil { self.ovdBaselineChroma = chroma }
            let (rainbow, bins) = self.manager.ovdRainbowMaxScoreDetailed(in: ci, baseROI: base)
            if self.ovdBaselineRainbow == nil { self.ovdBaselineRainbow = rainbow }
            let deltaRainbow = rainbow - (self.ovdBaselineRainbow ?? rainbow)
            self.ovdWhiteOut = whiteOut

            // Agresif threshold'lar: belirgin rainbow göründüğünde hemen capture
            let rainbowThr: Float = 0.025  // Mutlak rainbow threshold
            let deltaThr:   Float = 0.015   // Delta threshold (baseline'dan artış)
            let minBins     = 2             // Minimum 2 farklı renk
            
            // Rainbow kontrolü: mutlak değer veya delta yeterliyse OK
            let binsOK = (bins >= minBins)
            let rainbowOK = (rainbow >= rainbowThr) || (deltaRainbow >= deltaThr)
            
            // Basit mantık: beyaz patlama yoksa ve rainbow belirginse capture
            // Netlik kontrolünü kaldırdık çünkü OVD adımında sharp değeri 0 dönüyor
            let pass = (!whiteOut) && binsOK && rainbowOK
            
            // Hysteresis: pass ise hızlıca artır, değilse yavaşça azalt
            if pass { 
                self.ovdHold = min(self.ovdHold + 2, 10) // Daha hızlı artış
            } else { 
                self.ovdHold = max(self.ovdHold - 1, 0) 
            }
            
            // Çok kısa bekleme: sadece 0.3 saniye ve 2 frame yeterli
            let minOvdTimeOk = (CFAbsoluteTimeGetCurrent() - self.ovdStartTs) > 0.3
            let hit = minOvdTimeOk && (self.ovdHold >= 2)

            // Detaylı debug logları (kapalı)
            //print("🔍 OVD DEBUG:")
            //print("  rainbow=\(String(format: "%.4f", rainbow)) (thr=\(rainbowThr)) | delta=\(String(format: "%.4f", deltaRainbow)) (thr=\(deltaThr))")
            //print("  bins=\(bins) (min=\(minBins)) | whiteOut=\(whiteOut) | chroma=\(String(format: "%.4f", chroma))")
            //print("  binsOK=\(binsOK) | rainbowOK=\(rainbowOK)")
            //print("  pass=\(pass) | hold=\(self.ovdHold) | minTimeOk=\(minOvdTimeOk) | hit=\(hit)")
            //print("  baselineRainbow=\(String(format: "%.4f", self.ovdBaselineRainbow ?? 0))")
            //print("---")

            DispatchQueue.main.async {
                if whiteOut { 
                    self.stepLabel.text = self.translate(text: .ovdTooWhiteTilt) 
                } else if !rainbowOK {
                    self.stepLabel.text = self.translate(text: .ovdFlashMoveCard)
                } else {
                    self.stepLabel.text = hit ? self.translate(text: .ovdGlareCaptured) : self.translate(text: .ovdFlashMoveCard)
                }
                self.setGuideDetected(hit)
            }

            if hit && !self.isCapturing && !self.ovdCaptured && !self.isOCRInFlight {
                //print("✅ OVD CAPTURE TRIGGERED! hit=\(hit) isCapturing=\(self.isCapturing) ovdCaptured=\(self.ovdCaptured) isOCRInFlight=\(self.isOCRInFlight)")
                self.ovdCaptured = true
                DispatchQueue.main.async { self.stepLabel.text = self.translate(text: .ovdGlareCaptured) }
                self.capture(reason: .ovd)
            } else if hit {
                //print("⚠️ OVD hit=\(hit) but blocked: isCapturing=\(self.isCapturing) ovdCaptured=\(self.ovdCaptured) isOCRInFlight=\(self.isOCRInFlight)")
            }
        }
    }
}

// MARK: - Vision/Geometry yardımcıları
private extension CGPoint { func toImagePoint(_ rect: CGRect) -> CGPoint { CGPoint(x: x*rect.width + rect.origin.x, y: (1-y)*rect.height + rect.origin.y) } }
private extension CGRect { var area: CGFloat { width * height } }
