//
//  CaptureViewController.swift
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

// MARK: - Basit Modeller
struct OCRFields {
    var name: String?
    var surname: String?
    var idNumber: String?
    var birthDate: String?
}

struct MRZResult {
    let rawLines: [String]
    let documentNumber: String?   // Seri No
    let birthDate: String?        // YYMMDD
    let expiryDate: String?       // YYMMDD
    let nationality: String?      // Örn: "TUR"
    let surname: String?
    let givenNames: String?
    let tckn: String?             // 11 haneli
    let isValid: Bool
}

// MARK: - MRZ Parser (basit)
final class MRZParser {
    func parse(lines: [String]) -> MRZResult? {
        let cleaned = lines.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() }
        guard cleaned.count >= 2 else { return nil }
        if cleaned.count >= 3 { return parseTD1(cleaned) }
        if cleaned[0].count > 40 { return parseTD3(cleaned) } else { return parseTD2(cleaned) }
    }
    private func parseTD1(_ L: [String]) -> MRZResult? {
        guard L.count >= 3 else { return nil }
        let l1 = L[0], l2 = L[1], l3 = L[2]
        let (surname, given) = splitNameFromLine(l1)
        let documentNumber = takeUntil(l2, stop: "<")
        let birthDate = extractDateYYMMDD(in: l2)
        let expiryDate = extractSecondDateYYMMDD(in: l2)
        let nationality = extractNationality(in: l2)
        let all = L.joined()
        let tckn = extractTCKN(in: all)
        return MRZResult(rawLines: [l1,l2,l3], documentNumber: documentNumber, birthDate: birthDate, expiryDate: expiryDate, nationality: nationality, surname: surname, givenNames: given, tckn: tckn, isValid: true)
    }
    private func parseTD2(_ L: [String]) -> MRZResult? {
        guard L.count >= 2 else { return nil }
        let l1 = L[0], l2 = L[1]
        let (surname, given) = splitNameFromLine(l1)
        let documentNumber = takeUntil(l2, stop: "<")
        let birthDate = extractDateYYMMDD(in: l2)
        let expiryDate = extractSecondDateYYMMDD(in: l2)
        let nationality = extractNationality(in: l2)
        let all = L.joined()
        let tckn = extractTCKN(in: all)
        return MRZResult(rawLines: [l1,l2], documentNumber: documentNumber, birthDate: birthDate, expiryDate: expiryDate, nationality: nationality, surname: surname, givenNames: given, tckn: tckn, isValid: true)
    }
    private func parseTD3(_ L: [String]) -> MRZResult? {
        guard L.count >= 2 else { return nil }
        let l1 = L[0], l2 = L[1]
        let (surname, given) = splitNameFromLine(l1)
        let documentNumber = takeUntil(l2, stop: "<")
        let birthDate = extractDateYYMMDD(in: l2)
        let expiryDate = extractSecondDateYYMMDD(in: l2)
        let nationality = extractNationality(in: l2)
        let all = L.joined()
        let tckn = extractTCKN(in: all)
        return MRZResult(rawLines: [l1,l2], documentNumber: documentNumber, birthDate: birthDate, expiryDate: expiryDate, nationality: nationality, surname: surname, givenNames: given, tckn: tckn, isValid: true)
    }
    private func splitNameFromLine(_ line: String) -> (String?, String?) {
        guard let range = line.range(of: "<<") else { return (nil, nil) }
        let left = String(line[..<range.lowerBound])
        let right = String(line[range.upperBound...])
        let surname = left.components(separatedBy: "<").last
        let given = right.replacingOccurrences(of: "<", with: " ").trimmingCharacters(in: .whitespaces)
        return (surname, given)
    }
    private func takeUntil(_ s: String, stop: Character) -> String? { var out = ""
        for ch in s { if ch == stop { break }
            out.append(ch) }
        return out.isEmpty ? nil : out }
    private func extractDateYYMMDD(in s: String) -> String? { if let r = s.range(of: #"\d{6}"#, options: .regularExpression) { return String(s[r]) }
        return nil }
    private func extractSecondDateYYMMDD(in s: String) -> String? {
        let matches = s.matches(for: #"\d{6}"#)
        return matches.count >= 2 ? matches[1] : nil }
    private func extractNationality(in s: String) -> String? { if let r = s.range(of: #"[A-Z<]{3}"#, options: .regularExpression) { return String(s[r]).replacingOccurrences(of: "<", with: "") }
        return nil }
    private func extractTCKN(in s: String) -> String? {
        if let r = s.range(of: #"\b\d{11}\b"#, options: .regularExpression) { return String(s[r]) }
        return nil
    }
}
private extension String {
    func matches(for regex: String) -> [String] {
        (try? NSRegularExpression(pattern: regex))?
            .matches(in: self, range: NSRange(location: 0, length: (self as NSString).length))
            .map { (self as NSString).substring(with: $0.range) } ?? []
    }
}

// MARK: - OVD / Parlama Analizörü
final class OVDAnalyzer {
    private let context = CIContext(options: [.useSoftwareRenderer: false])
    private let conv = CIFilter.convolution3X3()
    init() {
        conv.weights = CIVector(values: [ -1,-1,-1, -1,8,-1, -1,-1,-1 ], count: 9)
        conv.bias = 0
    }
    /// Parlama tespiti: çok parlak piksel oranı (yaklaşık)
    func glareScore(ciImage: CIImage, roi: CGRect) -> Float {
        let crop = ciImage.cropped(to: roi)
        let hist = CIFilter.areaHistogram()
        hist.inputImage = crop
        hist.extent = crop.extent
        hist.scale = 1
        hist.count = 256
        guard let out = hist.outputImage,
              let cg = context.createCGImage(out, from: CGRect(x: 0, y: 0, width: 256, height: 1)),
              let provider = cg.dataProvider, let raw = provider.data else { return 0 }
        let ptr = CFDataGetBytePtr(raw)!
        var bright: Float = 0
        var total: Float = 0
        let width = cg.width
        let step = cg.bitsPerPixel/8
        for x in 0..<width {
            let off = x*step
            let v = Float(ptr[off])
            total += v
            if x >= 240 { bright += v } }
        return total <= 0 ? 0 : min(1, bright/total)
    }
    /// Texture (kenar) enerjisi ~ Laplacian ortalaması (yaklaşık netlik)
    func textureMean(ciImage: CIImage, roi: CGRect) -> Float {
        let crop = ciImage.cropped(to: roi)
        conv.inputImage = crop
        guard let edged = conv.outputImage else { return 0 }
        let avg = CIFilter.areaAverage()
        avg.inputImage = edged
        avg.extent = crop.extent
        guard let out = avg.outputImage, let px = context.renderPixel(out) else { return 0 }
        return Float((px.r + px.g + px.b)/3.0)
    }
    /// Renk metrikleri: beyaz patlama ve renk canlılığı
    func colorMetrics(ciImage: CIImage, roi: CGRect) -> (brightness: Float, chroma: Float, whiteOut: Bool) {
        let crop = ciImage.cropped(to: roi)
        let avg = CIFilter.areaAverage()
        avg.inputImage = crop
        avg.extent = crop.extent
        guard let out = avg.outputImage, let px = context.renderPixel(out) else { return (0,0,false) }
        let r = max(0.0, min(1.0, px.r)), g = max(0.0, min(1.0, px.g)), b = max(0.0, min(1.0, px.b))
        let v = Float(max(r, max(g, b)))
        let minc = Float(min(r, min(g, b)))
        let s: Float = v == 0 ? 0 : (v - minc) / v
        let mean = Float((r + g + b) / 3.0)
        let varRGB = (powf(Float(r) - mean, 2) + powf(Float(g) - mean, 2) + powf(Float(b) - mean, 2)) / 3.0
        let chroma = sqrtf(max(0, varRGB))
        let whiteOut = (v > 0.85 && s < 0.12)
        return (v, chroma, whiteOut)
    }
    /// Gökkuşağı benzeri renkli parlama skoru (detaylı): score + görülen renk kovası sayısı + coverage
    func rainbowScoreDetailed(ciImage: CIImage, roi: CGRect) -> (score: Float, binsPresent: Int, coverage: Float) {
        let crop = ciImage.cropped(to: roi)
        guard let cg = context.createCGImage(crop, from: crop.extent) else { return (0,0,0) }
        let w = 48, h = 48
        let cs = CGColorSpaceCreateDeviceRGB()
        var buf = [UInt8](repeating: 0, count: w*h*4)
        guard let ctx = CGContext(data: &buf, width: w, height: h, bitsPerComponent: 8,
                                  bytesPerRow: w*4, space: cs,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return (0,0,0) }
        ctx.interpolationQuality = .low
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        var bins = [Int](repeating: 0, count: 6)
        var hits = 0
        for i in 0..<(w*h) {
            let r = Float(buf[i*4+0]) / 255.0
            let g = Float(buf[i*4+1]) / 255.0
            let b = Float(buf[i*4+2]) / 255.0
            let maxv = max(r, max(g, b))
            let minv = min(r, min(g, b))
            let v = maxv
            let s: Float = maxv == 0 ? 0 : (maxv - minv) / maxv
            if v > 0.6 && s > 0.3 {
                let d = maxv - minv
                var hdeg: Float = 0
                if d == 0 { hdeg = 0 }
                else if maxv == r { hdeg = 60 * fmodf(((g - b) / d), 6) }
                else if maxv == g { hdeg = 60 * (((b - r) / d) + 2) }
                else { hdeg = 60 * (((r - g) / d) + 4) }
                if hdeg < 0 { hdeg += 360 }
                let bin: Int
                switch hdeg {
                case 0..<30, 330..<360: bin = 0
                case 30..<90:           bin = 1
                case 90..<150:          bin = 2
                case 150..<210:         bin = 3
                case 210..<270:         bin = 4
                default:                bin = 5
                }
                bins[bin] += 1
                hits += 1
            }
        }
        let present = bins.filter { $0 > 0 }.count
        let coverage = Float(hits) / Float(w*h)
        let score = coverage * (Float(present) / 6.0)
        return (score, present, coverage)
    }
    /// Geriye dönük uyum için eski imza
    func rainbowScore(ciImage: CIImage, roi: CGRect) -> Float { rainbowScoreDetailed(ciImage: ciImage, roi: roi).score }
}
private extension CIContext {
    func renderPixel(_ image: CIImage) -> (r: Double,g: Double,b: Double,a: Double)? {
        guard let cg = createCGImage(image, from: CGRect(x: 0, y: 0, width: 1, height: 1)) else { return nil }
        let cs = CGColorSpaceCreateDeviceRGB()
        var buf = [UInt8](repeating: 0, count: 4)
        let ctx = CGContext(data: &buf, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        ctx?.draw(cg, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        return (Double(buf[0])/255.0, Double(buf[1])/255.0, Double(buf[2])/255.0, Double(buf[3])/255.0)
    }
}

// MARK: - Capture View Controller
final class CaptureViewController: SDKBaseViewController {
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
    private var isOCRInFlight = false {
        didSet {
            print(">> isOCRInFlight: \(isOCRInFlight)")
        }
    }
    private var ovdCaptured = false

    // Vision/CI
    private let context = CIContext()
    private let mrzParser = MRZParser()
    private let ovd = OVDAnalyzer()
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
    private let stillMinRectAreaRatio: CGFloat = 0.08

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
        if now - lastDebugLogTime > 0.2 { print("[DBG] " + msg())
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
            guard let r = rectObs else {
                self.detectedRectLayer.path = nil
                return }
            let bb = r.boundingBox
            let meta = CGRect(x: bb.origin.x, y: 1 - bb.origin.y - bb.size.height, width: bb.size.width, height: bb.size.height)
            let uiRect = self.previewLayer.layerRectConverted(fromMetadataOutputRect: meta)
            let path = UIBezierPath(roundedRect: uiRect, cornerRadius: 8)
            self.detectedRectLayer.path = path.cgPath
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
            dlog("capture(\(reason.rawValue)) ignored (isCapturing=\(isCapturing) isOCRInFlight=\(isOCRInFlight))")
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
        self.dlog("> processForOCR")
        self.startOCR(ciImage: ciImage)
//        // Still foto: ROI kullanma, orientation .up, overlay gösterme
//        detectRectangle(in: ciImage, useGuideROI: false, orientation: .up, showOverlay: false) { [weak self] rectObs in
//            self?.dlog("> processForOCR - detectRectangle (still)")
//            guard let self = self else { return }
//            self.dlog("processForOCR step=\(self.currentStep.rawValue) rectFound=\(rectObs != nil)")
//            self.lastRectObservation = rectObs
//
//            var finalImage = ciImage
//            if let r = rectObs {
//                let bb = r.toImageRect(imageRect: ciImage.extent)
//                let areaRatio = bb.area / max(ciImage.extent.area, 1)
//                if areaRatio >= self.stillMinRectAreaRatio {
//                    if let warped = self.perspectiveCorrect(image: ciImage, rect: r) {
//                        finalImage = warped
//                    }
//                } else {
//                    self.dlog(String(format: "Skip warp: small rect (%.1f%% of image)", areaRatio*100))
//                }
//            } else {
//                self.dlog("No rect on still; using original image")
//            }
//
//            self.startOCR(ciImage: ciImage)
//        }
    }
    
    private func startOCR(ciImage: CIImage) {
        print("[startOCR] entering step=\(currentStep.rawValue) isOCRInFlight=\(isOCRInFlight)")
        // Tek seferde tek OCR/upload pipeline çalışsın
        if isOCRInFlight {
            dlog("startOCR ignored (in-flight) step=\(currentStep.rawValue)")
            return
        }
        isOCRInFlight = true
        let img = self.makeUIImage(from: ciImage) ?? UIImage(ciImage: ciImage)
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
                                // Front OCR + upload başarılı -> OVD adımına geç
                                print("[FrontUpload] success, moving to OVD step")
                                DispatchQueue.main.async {
                                    self.moveToOVDStep()
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
    
    // MRZ-dedicated OCR for better chevron capture
    private func runMRZOCR(on ciImage: CIImage, completion: @escaping ([String]) -> Void) {
        let roi = docRectROI(in: ciImage.extent)
        let mrzH = roi.height * 0.45
        let mrzROI = CGRect(x: roi.origin.x + roi.width * 0.05,
                            y: roi.origin.y,
                            width: roi.width * 0.90,
                            height: mrzH)
        let cropped = ciImage.cropped(to: mrzROI)
        let req = VNRecognizeTextRequest { req, _ in
            let texts = (req.results as? [VNRecognizedTextObservation])?.compactMap { $0.topCandidates(1).first?.string } ?? []
            completion(texts)
        }
        req.recognitionLevel = .accurate
        req.usesLanguageCorrection = false
        req.minimumTextHeight = 0.0045
        let handler = VNImageRequestHandler(ciImage: cropped, options: [:])
        do { try handler.perform([req]) } catch { completion([]) }
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
                let s = self.sideLengths(of: r)
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

    private func perspectiveCorrect(image: CIImage, rect: VNRectangleObservation?) -> CIImage? {
        guard let r = rect else { return nil }
        let f = CIFilter.perspectiveCorrection()
        f.inputImage = image
        f.topLeft = r.topLeft.toImagePoint(image.extent)
        f.topRight = r.topRight.toImagePoint(image.extent)
        f.bottomLeft = r.bottomLeft.toImagePoint(image.extent)
        f.bottomRight = r.bottomRight.toImagePoint(image.extent)
        return f.outputImage
    }

    private func runOCR(on ciImage: CIImage, completion: @escaping ([String]) -> Void) {
        let req = VNRecognizeTextRequest { req, _ in
            let texts = (req.results as? [VNRecognizedTextObservation])?.compactMap { $0.topCandidates(1).first?.string } ?? []
            completion(texts)
        }
        req.recognitionLevel = .accurate
        req.usesLanguageCorrection = true
        req.recognitionLanguages = ["tr-TR","en-US"]
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        do { try handler.perform([req]) } catch { completion([]) }
    }

    private func extractMRZ(from texts: [String]) -> MRZResult? {
        var mrzLines = texts.filter { $0.contains("<") }
        if mrzLines.isEmpty {
            mrzLines = texts.filter { line in
                let u = line.uppercased()
                return u.contains("TUR")
                    || (line.matches(for: #"\b\d{11}\b"#).count > 0)
                    || (line.matches(for: #"\b\d{6}\b"#).count >= 2)
                    || (line.count >= 20)
            }
        }
        guard !mrzLines.isEmpty else { return nil }
        return mrzParser.parse(lines: mrzLines)
    }

    private func extractFields(from text: String) -> OCRFields {
        var out = OCRFields()
        if let tckn = text.matches(for: #"\b\d{11}\b"#).first { out.idNumber = tckn }
        if let range = text.range(of: "SOYADI") { let sub = text[range.upperBound...]
            out.surname = sub.split(separator: " ").first.map(String.init) }
        if let r2 = text.range(of: "ADI") { let sub = text[r2.upperBound...]
            out.name = sub.split(separator: " ").first.map(String.init) }
        if let d = text.matches(for: #"\b(\d{2}[./-]\d{2}[./-]\d{4}|\d{6})\b"#).first { out.birthDate = d }
        return out
    }

    private func sideLengths(of r: VNRectangleObservation) -> (w: CGFloat, h: CGFloat) {
        func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat { let dx = a.x - b.x, dy = a.y - b.y
            return sqrt(dx*dx + dy*dy) }
        let w = (dist(r.topLeft, r.topRight) + dist(r.bottomLeft, r.bottomRight)) / 2.0
        let h = (dist(r.topLeft, r.bottomLeft) + dist(r.topRight, r.bottomRight)) / 2.0
        return (w, h)
    }

    // MARK: - İçerik tabanlı yardımcılar
    private func rectCenterY(_ rectObs: VNRectangleObservation?, extent: CGRect) -> CGFloat {
        if let r = rectObs {
            let bb = r.boundingBox
            let normCenterY = 1.0 - (bb.origin.y + bb.size.height/2.0)
            return normCenterY * extent.height + extent.origin.y
        } else {
            let roi = self.docRectROI(in: extent)
            return roi.midY
        }
    }

    private func probeMRZPresence(in ciImage: CIImage, roi: CGRect, completion: @escaping (Bool) -> Void) {
        let mrzH = roi.height * 0.45
        let mrzROI = CGRect(x: roi.origin.x + roi.width * 0.05,
                            y: roi.origin.y,
                            width: roi.width * 0.90,
                            height: mrzH)
        let cropped = ciImage.cropped(to: mrzROI)
        let req = VNRecognizeTextRequest { req, _ in
            let lines = (req.results as? [VNRecognizedTextObservation])?.compactMap { $0.topCandidates(1).first?.string } ?? []
            let joined = lines.joined(separator: " ")
            let chevrons = joined.filter { $0 == "<" }.count
            let longLines = lines.filter { $0.count >= 18 }.count
            let hasTUR = joined.uppercased().contains("TUR")
            let hasYYMMDD = (joined.range(of: #"\b\d{6}\b"#, options: .regularExpression) != nil)
            let has11 = (joined.range(of: #"\b\d{11}\b"#, options: .regularExpression) != nil)
            let mrzLike = (chevrons >= 10)
                       || (chevrons >= 6 && hasTUR && hasYYMMDD)
                       || (has11 && hasYYMMDD)
            print("[MRZprobe] chevrons=\(chevrons) longLines=\(longLines) hasTUR=\(hasTUR) hasYYMMDD=\(hasYYMMDD) has11=\(has11) mrzLike=\(mrzLike)")
            completion(mrzLike)
        }
        req.recognitionLevel = .fast
        req.usesLanguageCorrection = false
        req.minimumTextHeight = 0.006
        let handler = VNImageRequestHandler(ciImage: cropped, options: [:])
        DispatchQueue.global(qos: .userInitiated).async { do { try handler.perform([req]) } catch { completion(false) } }
    }

    /// EXIF orientation değerini ayna (mirror) varyantlarından arındırıp temel yönüne indirger.
    /// Böylece düz çekimde gereksiz mirror ve 180° sapmaları engelleriz.
    private func normalizedExifOrientation(from metadata: [String: Any]) -> Int32 {
        let raw = (metadata[kCGImagePropertyOrientation as String] as? NSNumber)?.int32Value ?? 1
        switch raw {
        case 2: return 1   // upMirrored -> up
        case 4: return 3   // downMirrored -> down
        case 5: return 6   // leftMirrored -> right
        case 7: return 8   // rightMirrored -> left
        default: return raw
        }
    }

    // Görüntüyü mutlaka yatay yap
    private func forceLandscape(_ ci: CIImage) -> CIImage {
        return ci.extent.width >= ci.extent.height ? ci : ci.oriented(.right)
    }

    // MARK: - Çekim sonrası işleme

    /// ID kartı için, canlı kılavuz alanına benzer merkezlenmiş bir ROI üretir.
    /// Still fotolarda preview-layer koordinatları ile birebir eşleşme garantisi olmadığı için
    /// burada sadece oran olarak benzer bir alan kullanıyoruz ki tüm görüntü gitmesin.
    private func centeredDocRectROI(in extent: CGRect) -> CGRect {
        // Genişliğin %60'ı kadar al, ID oranına göre yükseklik hesapla ve merkeze yerleştir
        var width = extent.width * 0.6
        var height = width / idAspect

        // Çok yüksekse biraz kıs
        let maxHeight = extent.height * 0.7
        if height > maxHeight {
            height = maxHeight
            width = height * idAspect
        }

        let x = extent.midX - width / 2.0
        let y = extent.midY - height / 2.0
        let roi = CGRect(x: x, y: y, width: width, height: height)
        return roi.intersection(extent)
    }

    private func processCaptured(_ ci: CIImage, step: CaptureStep) -> CIImage {
        // *** Always force landscape before ANY crop logic ***
        //let ci = forceLandscape(ci)

        let extent = ci.extent
        let roi = centeredDocRectROI(in: extent)

        // 1) OVD: aynı davranış, her zaman guide benzeri alan
//        if case .ovd = step {
//            return ci.cropped(to: roi)
//        }

        // FRONT/BACK:
        // Önce canlı sarı çerçeve (lastRectObservation) büyük ve ID oranına uygunsa
        // doğrudan o bounding box'a crop et.
        if let liveRect = lastRectObservation {
            let bb = liveRect.toImageRect(imageRect: extent)
            let areaRatio = bb.area / max(extent.area, 1)
            let sides = sideLengths(of: liveRect)
            let ratio = min(sides.w, sides.h) / max(sides.w, sides.h)

            let sizeOK = areaRatio >= stillMinRectAreaRatio
            let aspectOK = (ratio >= aspectMin && ratio <= aspectMax)

            if sizeOK && aspectOK {
                let clipped = bb.intersection(extent)
                if !clipped.isNull && clipped.area > 0 {
                    return ci.cropped(to: clipped)
                }
            }
        }

        // Sonra still frame üzerinde yeni bir dikdörtgen bulmayı dene.
        if let rect = detectRectangleSync(in: ci) {
            let bb = rect.toImageRect(imageRect: extent)
            let areaRatio = bb.area / max(extent.area, 1)
            let sides = sideLengths(of: rect)
            let ratio = min(sides.w, sides.h) / max(sides.w, sides.h)

            let sizeOK = areaRatio >= stillMinRectAreaRatio
            let aspectOK = (ratio >= aspectMin && ratio <= aspectMax)

            if sizeOK && aspectOK {
                let clipped = bb.intersection(extent)
                if !clipped.isNull && clipped.area > 0 {
                    return ci.cropped(to: clipped)
                }
            }
        }

        // Hiç düzgün dikdörtgen yoksa, guide benzeri alana crop et (fallback)
        return ci.cropped(to: roi)
    }
    private func detectRectangleSync(in ci: CIImage) -> VNRectangleObservation? {
        let req = VNDetectRectanglesRequest()
        req.minimumAspectRatio = 0.5
        req.minimumSize = 0.04
        req.quadratureTolerance = 25.0
        req.minimumConfidence = 0.5
        req.maximumObservations = 1
        let handler = VNImageRequestHandler(ciImage: ci, orientation: .up, options: [:])
        do { try handler.perform([req]) } catch { return nil }
        return (req.results as? [VNRectangleObservation])?.first
    }

    private func mrzChevronScore(ciImage: CIImage, roi: CGRect) -> Int {
        let cropped = ciImage.cropped(to: roi)
        let req = VNRecognizeTextRequest()
        req.recognitionLevel = .fast
        req.usesLanguageCorrection = false
        let handler = VNImageRequestHandler(ciImage: cropped, options: [:])
        do { try handler.perform([req]) } catch { return 0 }
        let lines = (req.results as? [VNRecognizedTextObservation])?.compactMap { $0.topCandidates(1).first?.string } ?? []
        return lines.reduce(0) { $0 + $1.filter { $0 == "<" }.count }
    }
    private func textAlphaNumScore(ciImage: CIImage, roi: CGRect) -> Int {
        let cropped = ciImage.cropped(to: roi)
        let req = VNRecognizeTextRequest()
        req.recognitionLevel = .fast
        req.usesLanguageCorrection = false
        let handler = VNImageRequestHandler(ciImage: cropped, options: [:])
        do { try handler.perform([req]) } catch { return 0 }
        let lines = (req.results as? [VNRecognizedTextObservation])?.compactMap { $0.topCandidates(1).first?.string } ?? []
        return lines.reduce(0) { $0 + $1.filter { $0.isLetter || $0.isNumber }.count }
    }
    private func flipBackIfNeeded(_ ci: CIImage) -> CIImage {
        let h = ci.extent.height, w = ci.extent.width
        let bandH = h * 0.35
        let x = ci.extent.origin.x + w * 0.05
        let bandW = w * 0.90

        let bottom = CGRect(x: x, y: ci.extent.origin.y, width: bandW, height: bandH)
        let top = CGRect(x: x, y: ci.extent.maxY - bandH, width: bandW, height: bandH)

        let topScore = mrzChevronScore(ciImage: ci, roi: top)
        let bottomScore = mrzChevronScore(ciImage: ci, roi: bottom)
        return (topScore >= bottomScore + 12) ? ci.oriented(.down) : ci
    }
    private func flipFrontIfNeeded(_ ci: CIImage) -> CIImage {
        return ci
    }

    private func textScoreWhole(_ ci: CIImage) -> Int {
        let e = ci.extent
        let roi = CGRect(x: e.origin.x + e.width * 0.08,
                         y: e.origin.y + e.height * 0.15,
                         width: e.width * 0.84,
                         height: e.height * 0.70)
        return textAlphaNumScore(ciImage: ci, roi: roi)
    }
    private func unMirrorIfNeeded(_ ci: CIImage) -> CIImage {
        let s0 = textScoreWhole(ci)
        let mirrored = ci.oriented(.upMirrored)
        let s1 = textScoreWhole(mirrored)
        return (s1 > s0 + 8) ? mirrored : ci
    }

    private func makeUIImage(from ci: CIImage) -> UIImage? {
        guard let cg = context.createCGImage(ci, from: ci.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}

// MARK: - AVCapture Delegeleri
extension CaptureViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        defer { isCapturing = false }
        guard error == nil else { return }

        // 1) Raw JPEG verisini al
        guard let data = photo.fileDataRepresentation() else { return }

        // 2) CIImage yarat (henüz rotate etme)
        let originalCI = CIImage(data: data) ?? CIImage()

        // 3) RAW orientation ile crop yap (guide & sarı rect doğru alansın diye)
        let croppedCI = self.processCaptured(originalCI, step: captureReason)

        // 4) Crop sonrası tek tip dön → sağa 90°
        let ciRaw = croppedCI.oriented(.right)

        print("[Capture] RAW resolution after pre-rotation crop: \(ciRaw.extent.size)")

        guard let ui = self.makeUIImage(from: ciRaw) else { return }
        
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

private extension CaptureViewController {
    func rainbowMaxScoreDetailed(in ciImage: CIImage, baseROI: CGRect) -> (score: Float, bins: Int) {
        func clamp(_ r: CGRect, in bounds: CGRect) -> CGRect { r.intersection(bounds) }
        let bx = baseROI.origin.x, by = baseROI.origin.y, bw = baseROI.size.width, bh = baseROI.size.height
        var bestScore: Float = 0
        var bestBins: Int = 0
        for yi in 0..<4 {
            for xi in 0..<4 {
                let sub = CGRect(x: bx + bw*(0.05 + CGFloat(xi)*0.18),
                                 y: by + bh*(0.05 + CGFloat(yi)*0.18),
                                 width: bw*0.45, height: bh*0.45)
                let roi = clamp(sub, in: ciImage.extent)
                let det = self.ovd.rainbowScoreDetailed(ciImage: ciImage, roi: roi)
                if det.score > bestScore {
                    bestScore = det.score
                    bestBins = det.binsPresent
                }
            }
        }
        return (bestScore, bestBins)
    }
}

extension CaptureViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
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
                    let sharp = self.ovd.textureMean(ciImage: ci, roi: roi)
                    let stableOK = self.stableDuration >= self.requiredStableDuration
                    let hasRect = (rectObs != nil)

                    let nowTs = CFAbsoluteTimeGetCurrent()
                    if stableOK && (sharp >= self.sharpnessThreshold) {
                        if self.stableSharpStart == nil { self.stableSharpStart = nowTs }
                    } else { self.stableSharpStart = nil }

                    if self.currentStep == .back && hasRect && !self.mrzPresence && !self.mrzProbeInFlight {
                        self.mrzProbeInFlight = true
                        self.probeMRZPresence(in: ci, roi: roi) { [weak self] ok in
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
                        let bb = ro.toImageRect(imageRect: ci.extent)
                        coverage = bb.intersection(roi).area / max(roi.area, 1)
                        let s = self.sideLengths(of: ro)
                        ratio = min(s.w, s.h) / max(s.w, s.h)
                        let rectArea = bb.area
                        let minAcceptableArea = roi.area * 0.50
                        rectTooSmall = (rectArea < minAcceptableArea)
                        if rectTooSmall {
                            self.dlog("Rect too small: \(Int(bb.width))x\(Int(bb.height)) area=\(Int(rectArea)) minReq=\(Int(minAcceptableArea))")
                        }
                    }

                    let (_, _, whiteOutFB) = self.ovd.colorMetrics(ciImage: ci, roi: roi)
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

            let g = self.ovd.glareScore(ciImage: ci, roi: base)
            if self.ovdBaselineGlare == nil { self.ovdBaselineGlare = g }
            let (_, chroma, whiteOut) = self.ovd.colorMetrics(ciImage: ci, roi: base)
            if self.ovdBaselineChroma == nil { self.ovdBaselineChroma = chroma }
            let (rainbow, bins) = self.rainbowMaxScoreDetailed(in: ci, baseROI: base)
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
private extension VNRectangleObservation {
    func toImageRect(imageRect: CGRect) -> CGRect {
        let tl = topLeft.toImagePoint(imageRect)
        let tr = topRight.toImagePoint(imageRect)
        let bl = bottomLeft.toImagePoint(imageRect)
        let br = bottomRight.toImagePoint(imageRect)
        let xs = [tl.x,tr.x,bl.x,br.x]
        let ys = [tl.y,tr.y,bl.y,br.y]
        return CGRect(x: xs.min()!, y: ys.min()!, width: xs.max()! - xs.min()!, height: ys.max()! - ys.min()!)
    }
}
private extension CGPoint { func toImagePoint(_ rect: CGRect) -> CGPoint { CGPoint(x: x*rect.width + rect.origin.x, y: (1-y)*rect.height + rect.origin.y) } }
private extension CGRect { var area: CGFloat { width * height } }


// UILabel subclass that speaks when text changes, only if new and not the same as last spoken, with debouncing and cancellation
private final class SpeakingLabel: UILabel {
    private let speech = AVSpeechSynthesizer()
    private var speakToken: Int = 0
    private var lastSpokenText: String?

    override var text: String? {
        didSet {
            guard let text = text, !text.isEmpty else { return }
            guard text != lastSpokenText else { return }
            lastSpokenText = text

            speakToken &+= 1
            let currentToken = speakToken
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                guard let self = self else { return }
                guard currentToken == self.speakToken else { return }
                self.speech.stopSpeaking(at: .immediate)
                let utterance = AVSpeechUtterance(string: text)
                utterance.voice = AVSpeechSynthesisVoice(language: "tr-TR")
                utterance.rate = 0.48
                self.speech.speak(utterance)
            }
        }
    }
}

// MARK: - Review: 3 foto (scroll yok, tek ekranda)
final class ReviewViewController2: SDKBaseViewController {
    private let front: UIImage?
    private let ovd: UIImage?
    private let back: UIImage?
    private var frontImageView: UIImageView?
    private var ovdImageView: UIImageView?
    private var backImageView: UIImageView?
    init(front: UIImage?, ovd: UIImage?, back: UIImage?) {
        self.front = front
        self.ovd = ovd
        self.back = back
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }


    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .darkGray

        let title = UILabel()
        title.text = "Çekilen Fotoğraflar"
        title.font = .boldSystemFont(ofSize: 14)
        title.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(title)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        func makeBlock(_ image: UIImage?, _ name: String, assign: @escaping (UIImageView) -> Void) -> UIView {
            let container = UIView()
            container.clipsToBounds = true

            let iv = UIImageView(image: image)
            iv.contentMode = .scaleAspectFit
            iv.translatesAutoresizingMaskIntoConstraints = false
            iv.isUserInteractionEnabled = true
            container.addSubview(iv)

            NSLayoutConstraint.activate([
                iv.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                iv.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                iv.topAnchor.constraint(equalTo: container.topAnchor),
                iv.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])

            let badge = UILabel()
            badge.text = name
            badge.textColor = .white
            badge.font = .boldSystemFont(ofSize: 12)
            badge.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            badge.layer.cornerRadius = 6
            badge.clipsToBounds = true
            badge.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(badge)
            NSLayoutConstraint.activate([
                badge.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
                badge.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8)
            ])

            assign(iv)
            return container
        }

        stack.addArrangedSubview(makeBlock(front, "Ön Yüz") { iv in self.frontImageView = iv })
        stack.addArrangedSubview(makeBlock(ovd,   "OVD/Parlama") { iv in self.ovdImageView = iv })
        stack.addArrangedSubview(makeBlock(back,  "Arka Yüz") { iv in self.backImageView = iv })

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            title.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])

        if let iv = frontImageView {
            let tap = UITapGestureRecognizer(target: self, action: #selector(copyFrontBase64))
            iv.addGestureRecognizer(tap)
        }
        if let iv = ovdImageView {
            let tap = UITapGestureRecognizer(target: self, action: #selector(copyOVDBase64))
            iv.addGestureRecognizer(tap)
        }
        if let iv = backImageView {
            let tap = UITapGestureRecognizer(target: self, action: #selector(copyBackBase64))
            iv.addGestureRecognizer(tap)
        }

        uploadFront()
        uploadOVD()
        uploadBack()
    }

    private func uploadImage(_ image: UIImage?, to urlString: String, bodyKey: String, title: String) {
        guard let image = image else {
            print("No \(title) image to upload")
            return
        }
        guard let jpegData = image.jpegData(compressionQuality: 0.9) else {
            print("JPEG conversion failed for \(title)")
            return
        }
        let base64String = jpegData.base64EncodedString()
        let cleanedBase64 = base64String
            .replacingOccurrences(of: "\\", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let json: [String: Any] = [bodyKey: cleanedBase64]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            print("JSON serialization failed")
            return
        }
        var finalBodyData = bodyData
        if var jsonString = String(data: bodyData, encoding: .utf8) {
            jsonString = jsonString.replacingOccurrences(of: "\\/", with: "/")
            finalBodyData = jsonString.data(using: .utf8) ?? bodyData
        }
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = finalBodyData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Upload error (\(title)): \(error)")
                DispatchQueue.main.async {
                    self.oneButtonAlertShow(message: error.localizedDescription, title1: title.uppercased()) { }
                }
                return
            }
            var msg = ""
            if let data = data, let str = String(data: data, encoding: .utf8) {
                msg = str
                print("Response (\(title)): \(str)")
            } else {
                msg = "No response body"
            }
            DispatchQueue.main.async {
                self.oneButtonAlertShow(appName: title, message: msg, title1: "OK") { }
            }
        }
        task.resume()
    }
    private func uploadFront() {
        uploadImage(front, to: "https://idocrqa.identify.com.tr/api/front", bodyKey: "front_image", title: "front-front")
    }
    private func uploadOVD() {
        uploadImage(ovd, to: "https://idocrqa.identify.com.tr/api/front", bodyKey: "front_image", title: "idcheck-ovd")
    }
    private func uploadBack() {
        uploadImage(back, to: "https://idocrqa.identify.com.tr/api/back", bodyKey: "back_image", title: "back-back")
    }
    @objc private func dismissSelf() { dismiss(animated: true) }

    @objc private func copyFrontBase64() {
        copyImageBase64(front, label: "front")
    }
    @objc private func copyOVDBase64() {
        copyImageBase64(ovd, label: "ovd")
    }
    @objc private func copyBackBase64() {
        copyImageBase64(back, label: "back")
    }
    private func copyImageBase64(_ image: UIImage?, label: String) {
        guard let image = image, let jpegData = image.jpegData(compressionQuality: 0.9) else { return }
        let b64 = jpegData.base64EncodedString()
        UIPasteboard.general.string = b64
        DispatchQueue.main.async {
            self.oneButtonAlertShow(message: "\(label) base64 panoya kopyalandı", title1: "OK") { }
        }
    }
}

