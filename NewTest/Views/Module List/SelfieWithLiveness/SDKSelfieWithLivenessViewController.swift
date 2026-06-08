//
//  SDKSelfieWithLivenessViewController.swift
//  NewTest
//
//  Created by Ayhan Hakan Tekin on 4.05.2026.
//

import UIKit
import ARKit
import SwiftUI
import IdentifySDK

// MARK: - LivenessConfig

private struct LivenessConfig {
    let requiredHoldDuration: TimeInterval = 1.0  // Hareketsiz tutma süresi (sn) — 0.5–2.0
    let okFrameThreshold:  Int = 5                // Holding'e geçmek için OK frame sayısı — 3–10
    let badFrameThreshold: Int = 3                // Holding'den çıkmak için kötü frame sayısı — 2–5
    let warmupFrameCount:  Int = 30               // Başlangıç ısınma frame sayısı — 20–60

    let closeEnterDepth: Double = 0.31  // Bu mesafeden yakınsa "geri git" başlar (m) — 0.20–0.35
    let closeExitDepth:  Double = 0.32  // Bu mesafeyi geçince "geri git" kalkar (m) — 0.22–0.37
    let farEnterDepth:   Double = 0.34  // Bu mesafeden uzaksa "öne gel" başlar (m) — 0.30–0.50
    let farExitDepth:    Double = 0.36  // Bu mesafenin altında "öne gel" kalkar (m) — 0.32–0.55

    let fwdMinThreshold:   Float = 0.95  // Kameraya diklik (0–1, 1=tam dik) — 0.90–0.99
    let yawMaxThreshold:   Float = 0.10  // Yatay dönüş toleransı (sola/sağa) — 0.08–0.20
    let pitchMaxThreshold: Float = 0.15  // Dikey eğim toleransı (yukarı/aşağı) — 0.10–0.25
}

// MARK: - SDKSelfieWithLivenessViewController

class SDKSelfieWithLivenessViewController: SDKBaseViewController {

    // MARK: - State

    private enum VerifyState {
        case warmingUp, idle, faceDetected, holding, verified
    }

    // MARK: - Face Condition

    private enum FaceCondition: Equatable {
        case tooClose, tooFar, notFitting, ok
    }

    // MARK: - Properties

    private var arView: ARSCNView!
    private var faceNode: SCNNode?
    private var overlayMask: FaceOvalMaskView!
    private var faceProgressLoader: FaceProgressLoader!
    private var instructionLabel: UILabel!
    private var debugLabel: UILabel!

    private let configuration = ARFaceTrackingConfiguration()
    private let config = LivenessConfig()

    private var state: VerifyState = .warmingUp
    private var holdStartDate: Date?
    private var okFrameCounter: Int  = 0
    private var badFrameCounter: Int = 0
    private var warmupFrameCounter: Int = 0

    private var lastInstructionText: String = "Hazırlanıyor..."

    // Condition instruction debounce — 2 ardışık aynı frame sonra uygulanır
    private var conditionInstructionPending: String = ""
    private var conditionInstructionFrames: Int = 0

    private var hyst_tooClose = false
    private var hyst_tooFar   = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkCameraPermission()
        startSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arView?.session.pause()
    }

    override func appMovedToBackground() {
        arView?.session.pause()
    }

    override func appMovedToForeground() {
        if state != .verified { startSession() }
    }

    // MARK: - Setup

    private func setupUI() {
        arView = ARSCNView()
        arView.delegate = self
        arView.automaticallyUpdatesLighting = true
        arView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(arView)

        overlayMask = FaceOvalMaskView()
        overlayMask.translatesAutoresizingMaskIntoConstraints = false
        overlayMask.isOpaque = false
        overlayMask.isUserInteractionEnabled = false
        view.addSubview(overlayMask)

        faceProgressLoader = FaceProgressLoader()
        faceProgressLoader.translatesAutoresizingMaskIntoConstraints = false
        faceProgressLoader.isUserInteractionEnabled = false
        faceProgressLoader.isHidden = true
        view.addSubview(faceProgressLoader)

        setupInstructionLabel()
        setupDebugLabel()
        pinToEdges(arView)
        pinToEdges(overlayMask)
        pinToEdges(faceProgressLoader)
    }

    private func pinToEdges(_ v: UIView) {
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: view.topAnchor),
            v.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            v.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            v.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupInstructionLabel() {
        instructionLabel = UILabel()
        instructionLabel.text = "Hazırlanıyor..."
        instructionLabel.textColor = .white
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = 0
        instructionLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        instructionLabel.layer.shadowColor = UIColor.black.cgColor
        instructionLabel.layer.shadowOpacity = 0.7
        instructionLabel.layer.shadowRadius = 4
        instructionLabel.layer.shadowOffset = .zero
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionLabel)

        NSLayoutConstraint.activate([
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    private func setupDebugLabel() {
        debugLabel = UILabel()
        debugLabel.text = ""
        debugLabel.textColor = .yellow
        debugLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        debugLabel.textAlignment = .left
        debugLabel.numberOfLines = 0
        debugLabel.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        debugLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(debugLabel)

        NSLayoutConstraint.activate([
            debugLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            debugLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            debugLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8)
        ])
    }

    private func updateDebugInfo(faceAnchor: ARFaceAnchor) {
        let col     = faceAnchor.transform.columns.3
        let depth   = Double(abs(col.z))
        let depthCm = depth * 100

        let oval = ovalRect(in: view.bounds)
        let proj = arView.projectPoint(SCNVector3(col.x, col.y, col.z))
        let px   = CGFloat(proj.x)
        let py   = CGFloat(proj.y)

        let dx      = (px - oval.midX) / (oval.width  / 2)
        let dy      = (py - oval.midY) / (oval.height / 2)
        let ellipse = dx * dx + dy * dy

        let depthZone: String
        if depth < config.closeEnterDepth    { depthZone = "YAKINDA ⚠️  (<\(Int(config.closeEnterDepth * 100))cm)" }
        else if depth > config.farEnterDepth { depthZone = "UZAKTA  ⚠️  (>\(Int(config.farEnterDepth * 100))cm)" }
        else                                 { depthZone = "OK ✓  (\(Int(config.closeEnterDepth * 100))-\(Int(config.farEnterDepth * 100))cm)" }

        var camZ: Float = 0
        var camX: Float = 0
        var camY: Float = 0
        if let frame = arView.session.currentFrame {
            let cs = simd_mul(simd_inverse(frame.camera.transform), faceAnchor.transform)
            camZ = cs.columns.2.z
            camX = cs.columns.2.x
            camY = cs.columns.2.y
        }

        let centerOk = ellipse < 0.36
        let fwdOk    = camZ > config.fwdMinThreshold
        let yawOk    = abs(camX) < config.yawMaxThreshold
        let pitchOk  = abs(camY) < config.pitchMaxThreshold

        var failReasons: [String] = []
        if !centerOk { failReasons.append("merkez") }
        if !fwdOk    { failReasons.append("fwd(\(String(format: "%.3f", camZ)))>\(String(format: "%.2f", config.fwdMinThreshold))") }
        if !yawOk    { failReasons.append("yaw(\(String(format: "%.3f", camX)))<\(String(format: "%.2f", config.yawMaxThreshold))") }
        if !pitchOk  { failReasons.append("pitch(\(String(format: "%.3f", camY)))<\(String(format: "%.2f", config.pitchMaxThreshold))") }
        let fitStr = failReasons.isEmpty ? "OK ✓" : "REDDEDİLDİ: \(failReasons.joined(separator: ","))"

        let stateStr: String
        switch state {
        case .warmingUp:    stateStr = "warmingUp(\(warmupFrameCounter)/\(config.warmupFrameCount))"
        case .idle:         stateStr = "idle"
        case .faceDetected: stateStr = "faceDetected"
        case .holding:      stateStr = "holding"
        case .verified:     stateStr = "verified"
        }

        debugLabel.text = """
        — MESAFE — \(String(format: "%.1f", depthCm)) cm   \(depthZone)
          close: enter<\(Int(config.closeEnterDepth*100))cm  exit>\(Int(config.closeExitDepth*100))cm  hyst:\(hyst_tooClose)
          far:   enter>\(Int(config.farEnterDepth*100))cm  exit<\(Int(config.farExitDepth*100))cm  hyst:\(hyst_tooFar)
        — FIT (kamera uzayı) — \(fitStr)
          merkez=\(String(format: "%.3f", ellipse))<0.36
          fwd(col2.z)=\(String(format: "%.3f", camZ))>\(String(format: "%.2f", config.fwdMinThreshold))
          yaw(col2.x)=\(String(format: "%.3f", camX))<\(String(format: "%.2f", config.yawMaxThreshold))
          pitch(col2.y)=\(String(format: "%.3f", camY))<\(String(format: "%.2f", config.pitchMaxThreshold))
        — STATE — \(stateStr)
          ok:\(okFrameCounter)/\(config.okFrameThreshold)  bad:\(badFrameCounter)/\(config.badFrameThreshold)
        """
    }

    // MARK: - Session

    private func startSession() {
        guard ARFaceTrackingConfiguration.isSupported else {
            showToast(type: .fail, title: translate(text: .coreError),
                      subTitle: "Cihazınız yüz takibini desteklemiyor", attachTo: view) {
                self.navigationController?.popViewController(animated: true)
            }
            return
        }
        state = .warmingUp
        warmupFrameCounter = 0
        okFrameCounter  = 0
        badFrameCounter = 0
        conditionInstructionPending = ""
        conditionInstructionFrames  = 0
        hyst_tooClose = false
        hyst_tooFar   = false
        faceProgressLoader.isHidden = true
        overlayMask.isHidden = false
        setInstruction("Hazırlanıyor...")
        arView.session.run(configuration)
    }

    // MARK: - Condition Checks

    private func evaluateConditions(faceAnchor: ARFaceAnchor) -> FaceCondition {
        if let c = checkFaceDistance(faceAnchor) { return c }
        if !isFaceFittingOval(faceAnchor)        { return .notFitting }
        return .ok
    }

    // Yüz merkezinin kameraya olan z-mesafesini (metre) kullanır.
    // Camera intrinsics'e veya ekran çözünürlüğüne bağımlılık yoktur.
    private func checkFaceDistance(_ faceAnchor: ARFaceAnchor) -> FaceCondition? {
        let depth = Double(abs(faceAnchor.transform.columns.3.z))
        guard depth > 0 else { return nil }

        if hyst_tooClose {
            if depth > config.closeExitDepth { hyst_tooClose = false } else { return .tooClose }
        } else if depth < config.closeEnterDepth {
            hyst_tooClose = true; return .tooClose
        }

        if hyst_tooFar {
            if depth < config.farExitDepth { hyst_tooFar = false } else { return .tooFar }
        } else if depth > config.farEnterDepth {
            hyst_tooFar = true; return .tooFar
        }

        return nil
    }

    // Yüzün oval içinde doğru konumda ve dik bakışta olup olmadığını kontrol eder.
    private func isFaceFittingOval(_ faceAnchor: ARFaceAnchor) -> Bool {
        let oval = ovalRect(in: view.bounds)
        let t    = faceAnchor.transform
        let col  = t.columns.3

        let proj = arView.projectPoint(SCNVector3(col.x, col.y, col.z))
        let nx = (CGFloat(proj.x) - oval.midX) / (oval.width  / 2)
        let ny = (CGFloat(proj.y) - oval.midY) / (oval.height / 2)
        guard nx * nx + ny * ny < 0.36 else { return false }

        guard let frame = arView.session.currentFrame else { return false }
        let cameraSpace = simd_mul(simd_inverse(frame.camera.transform), faceAnchor.transform)

        guard cameraSpace.columns.2.z > config.fwdMinThreshold   else { return false }
        guard abs(cameraSpace.columns.2.x) < config.yawMaxThreshold   else { return false }
        guard abs(cameraSpace.columns.2.y) < config.pitchMaxThreshold else { return false }

        return true
    }

    private func instructionText(for condition: FaceCondition) -> String {
        switch condition {
        case .tooClose:   return "Çok yakınsınız, lütfen geriye gidin"
        case .tooFar:     return "Çok uzaktasınız, lütfen öne gelin"
        case .notFitting: return "Yüzünüzü çerçeve içinde tutun"
        case .ok:         return "Hareketsiz kalın..."
        }
    }

    // MARK: - Face Detection Logic

    private func handleFaceDetected(_ faceAnchor: ARFaceAnchor) {
        updateDebugInfo(faceAnchor: faceAnchor)
        guard state != .verified, state != .warmingUp else { return }

        let condition = evaluateConditions(faceAnchor: faceAnchor)

        if condition == .ok {
            badFrameCounter = 0
            okFrameCounter += 1
            queueConditionInstruction(instructionText(for: .ok))

            if state != .holding {
                if okFrameCounter >= config.okFrameThreshold {
                    state = .holding
                    holdStartDate = Date()
                }
            }

            if state == .holding, let start = holdStartDate {
                let elapsed = Date().timeIntervalSince(start)
                let progress = CGFloat(min(1.0, elapsed / config.requiredHoldDuration))
                faceProgressLoader.setProgress(progress, animated: false)

                if elapsed >= config.requiredHoldDuration {
                    finalizeVerification()
                }
            }
        } else {
            okFrameCounter = 0
            badFrameCounter += 1

            if state == .holding {
                // Grace period: badFrameThreshold'a kadar holding state korunur,
                // progress sıfırlanmaz. Talimat debounce ile hemen kuyruğa alınır.
                queueConditionInstruction(instructionText(for: condition))
                if badFrameCounter >= config.badFrameThreshold {
                    state = .faceDetected
                    holdStartDate = nil
                    faceProgressLoader.setProgress(0, animated: false)
                }
            } else {
                state = .faceDetected
                holdStartDate = nil
                faceProgressLoader.setProgress(0, animated: false)
                queueConditionInstruction(instructionText(for: condition))
            }
        }
    }

    private func handleNoFace() {
        guard state != .verified else { return }
        state = .idle
        holdStartDate = nil
        okFrameCounter  = 0
        badFrameCounter = 0
        conditionInstructionPending = ""
        conditionInstructionFrames  = 0
        faceProgressLoader.setProgress(0, animated: false)
        setInstruction("Yüzünüzü çerçeve içinde tutun")
        debugLabel.text = "— YÜZ ALGILANMIYOR —"
    }

    private func handleWarmupFrame() {
        warmupFrameCounter += 1
        if warmupFrameCounter >= config.warmupFrameCount {
            state = .idle
            faceProgressLoader.isHidden = false
            faceProgressLoader.startDashAnimation()
            setInstruction("Yüzünüzü çerçeve içinde tutun")
        }
    }

    private func finalizeVerification() {
        guard state != .verified else { return }
        state = .verified

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        faceProgressLoader.setProgress(1.0, animated: true)
        faceProgressLoader.updateRingColors(track: .systemGreen, progress: .systemGreen)
        faceProgressLoader.stopDashAnimation()
        setInstruction("Doğrulandı ✓")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.faceNode?.isHidden = true
            self.faceProgressLoader.isHidden = true
            self.overlayMask.isHidden = true
            let image = self.arView.snapshot()
            self.uploadAndProceed(image: image)
        }
    }

    // MARK: - State Reset

    private func resetState() {
        state = .idle
        holdStartDate = nil
        okFrameCounter  = 0
        badFrameCounter = 0
        conditionInstructionPending = ""
        conditionInstructionFrames  = 0
        hyst_tooClose = false
        hyst_tooFar   = false
        overlayMask.isHidden = false
        debugLabel.isHidden = false
        hideLoader()
        faceProgressLoader.setProgress(0, animated: false)
        faceProgressLoader.updateRingColors(
            track: .white.withAlphaComponent(0.3),
            progress: .white
        )
        faceProgressLoader.startDashAnimation()
        setInstruction("Yüzünüzü çerçeve içinde tutun")
    }

    // MARK: - Upload

    private func uploadAndProceed(image: UIImage) {
        showLoader()
        arView.session.pause()

        manager.uploadIdPhoto(idPhoto: image, selfieType: .selfie) { [weak self] response in
            guard let self = self else { return }
            if response.result == true {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.manager.getNextModule { nextVC in
                        self.arView?.session.pause()
                        self.resetState()
                        self.navigationController?.pushViewController(nextVC, animated: true)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.resetState()
                    self.showToast(
                        type: .fail,
                        title: self.translate(text: .coreError),
                        subTitle: response.messages?.first ?? self.translate(text: .coreUploadError),
                        attachTo: self.view
                    ) {
                        self.startSession()
                    }
                }
            }
        }
    }

    private func setInstruction(_ text: String) {
        guard text != lastInstructionText else { return }
        lastInstructionText = text
        instructionLabel.text = text
    }

    // Condition tabanlı talimatlar için debounce: aynı metin 2 ardışık frame'de
    // görülmeden label güncellenmez. Tek frame'lik gürültü/hata talimatı önlenir.
    private func queueConditionInstruction(_ text: String) {
        if text == conditionInstructionPending {
            conditionInstructionFrames += 1
            if conditionInstructionFrames >= 2 {
                setInstruction(text)
            }
        } else {
            conditionInstructionPending = text
            conditionInstructionFrames = 1
        }
    }

    // Preview only
    func previewShowVerified() {
        state = .verified
        faceProgressLoader.isHidden = false
        faceProgressLoader.setProgress(1.0, animated: false)
        faceProgressLoader.updateRingColors(track: .systemGreen, progress: .systemGreen)
        instructionLabel.text = "Doğrulandı ✓"
    }
}

// MARK: - ARSCNViewDelegate

extension SDKSelfieWithLivenessViewController: ARSCNViewDelegate {

    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let _ = anchor as? ARFaceAnchor, let device = arView.device else { return nil }
        let faceMesh = ARSCNFaceGeometry(device: device)
        let node = SCNNode(geometry: faceMesh)
        let material = node.geometry?.firstMaterial
        material?.fillMode = .lines
        material?.diffuse.contents = UIColor.white.withAlphaComponent(0.55)
        material?.isDoubleSided = true
        faceNode = node
        return node
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard state != .verified,
              let faceAnchor = anchor as? ARFaceAnchor,
              let faceGeometry = node.geometry as? ARSCNFaceGeometry else { return }

        faceGeometry.update(from: faceAnchor.geometry)

        let isTracked = faceAnchor.isTracked
        let capturedAnchor = faceAnchor

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.state == .warmingUp {
                if isTracked { self.handleWarmupFrame() }
                return
            }
            if isTracked {
                self.handleFaceDetected(capturedAnchor)
            } else {
                self.handleNoFace()
            }
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        if anchor is ARFaceAnchor {
            DispatchQueue.main.async { [weak self] in self?.handleNoFace() }
        }
    }
}

// MARK: - Shared Oval Geometry

private func ovalRect(in bounds: CGRect) -> CGRect {
    let ovalW = bounds.width * 0.75
    let ovalH = ovalW * 1.35
    return CGRect(x: (bounds.width  - ovalW) / 2,
                  y: (bounds.height - ovalH) / 2 - 20,
                  width: ovalW,
                  height: ovalH)
}

// MARK: - FaceOvalMaskView

private class FaceOvalMaskView: UIView {
    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        UIColor.black.withAlphaComponent(0.65).setFill()
        ctx.fill(rect)
        ctx.setBlendMode(.clear)
        UIBezierPath(ovalIn: ovalRect(in: rect)).fill()
    }
}

// MARK: - FaceProgressLoader

private class FaceProgressLoader: UIView {

    // MARK: - Layers

    private let spinnerLayer = CAShapeLayer()
    private var lastPathBounds: CGRect = .zero

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    // MARK: - Setup

    private func setupLayers() {
        backgroundColor = .clear
        spinnerLayer.fillColor   = UIColor.clear.cgColor
        spinnerLayer.strokeColor = UIColor.white.withAlphaComponent(0.6).cgColor
        spinnerLayer.lineWidth   = 3
        spinnerLayer.lineCap     = .round
        spinnerLayer.lineDashPattern = [12, 20]
        spinnerLayer.strokeEnd   = 1
        spinnerLayer.isHidden    = true
        layer.addSublayer(spinnerLayer)
    }

    // MARK: - Path Update

    private func updateRingPaths() {
        let b = bounds
        guard abs(b.width  - lastPathBounds.width)  > 1 ||
              abs(b.height - lastPathBounds.height) > 1 else { return }
        lastPathBounds = b

        let oval = ovalRect(in: b)
        let spinnerPath = makeBezierOval(cx: oval.midX, cy: oval.midY,
                                         rx: oval.width  / 2 + 10,
                                         ry: oval.height / 2 + 10)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        spinnerLayer.path = spinnerPath.cgPath
        CATransaction.commit()
    }

    private func makeBezierOval(cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat) -> UIBezierPath {
        let p = UIBezierPath()
        p.move(to: CGPoint(x: cx, y: cy - ry))
        p.addCurve(to: CGPoint(x: cx + rx, y: cy),
                   controlPoint1: CGPoint(x: cx + rx * 0.55, y: cy - ry),
                   controlPoint2: CGPoint(x: cx + rx, y: cy - ry * 0.55))
        p.addCurve(to: CGPoint(x: cx, y: cy + ry),
                   controlPoint1: CGPoint(x: cx + rx, y: cy + ry * 0.55),
                   controlPoint2: CGPoint(x: cx + rx * 0.55, y: cy + ry))
        p.addCurve(to: CGPoint(x: cx - rx, y: cy),
                   controlPoint1: CGPoint(x: cx - rx * 0.55, y: cy + ry),
                   controlPoint2: CGPoint(x: cx - rx, y: cy + ry * 0.55))
        p.addCurve(to: CGPoint(x: cx, y: cy - ry),
                   controlPoint1: CGPoint(x: cx - rx, y: cy - ry * 0.55),
                   controlPoint2: CGPoint(x: cx - rx * 0.55, y: cy - ry))
        p.close()
        return p
    }

    // MARK: - Progress

    func setProgress(_ progress: CGFloat, animated: Bool = false) {}

    func resetProgress() {}

    // MARK: - Animation

    func startDashAnimation() {
        let spinnerDash = CABasicAnimation(keyPath: "lineDashPhase")
        spinnerDash.fromValue      = 0
        spinnerDash.toValue        = NSNumber(value: -32)
        spinnerDash.duration       = 0.8
        spinnerDash.repeatCount    = .infinity
        spinnerDash.timingFunction = CAMediaTimingFunction(name: .linear)
        spinnerLayer.add(spinnerDash, forKey: "spinnerAnimation")

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        spinnerLayer.strokeColor = UIColor.white.withAlphaComponent(0.6).cgColor
        spinnerLayer.isHidden    = false
        CATransaction.commit()
    }

    func stopDashAnimation() {
        spinnerLayer.removeAnimation(forKey: "spinnerAnimation")
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.4)
        spinnerLayer.strokeColor = UIColor.systemGreen.cgColor
        CATransaction.commit()
    }

    // MARK: - Visibility

    func setRingVisible(_ visible: Bool) {
        spinnerLayer.isHidden = !visible
    }

    // MARK: - Colors

    func updateRingColors(track: UIColor, progress: UIColor) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.4)
        spinnerLayer.strokeColor = track.cgColor
        CATransaction.commit()
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        updateRingPaths()
    }
}

// MARK: - Preview

@available(iOS 17, *)
#Preview("Yüz Doğrulama - Bekleniyor") {
    SDKSelfieWithLivenessViewController()
}

@available(iOS 17, *)
#Preview("Yüz Doğrulama - Doğrulandı") {
    let vc = SDKSelfieWithLivenessViewController()
    vc.loadViewIfNeeded()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        vc.previewShowVerified()
    }
    return vc
}
