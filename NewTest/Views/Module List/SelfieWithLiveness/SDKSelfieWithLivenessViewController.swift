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
    // Yüzün hareketsiz tutulması gereken süre (saniye).
    // Artırılırsa doğrulama için daha uzun süre beklenir.
    let requiredHoldDuration: TimeInterval = 1.0

    // Yüz "iyi konumda" sayılmadan önce kaç ardışık frame bekleneceği.
    // Küçük değer → daha hızlı tepki, büyük değer → daha kararlı algılama.
    let okFrameThreshold: Int = 5

    // Yüz bozuk konuma geçince mevcut ilerlemenin iptal edilmesi için
    // kaç ardışık kötü frame görülmesi gerektiği.
    // Büyük değer → küçük anlık bozulmaları tolere eder.
    let badFrameThreshold: Int = 3

    // Kamera açıldıktan sonra algılamaya başlamadan önce beklenen frame sayısı.
    // Bu süre içinde yüz takibi başlatılmaz, kameranın oturması beklenir.
    let warmupFrameCount: Int = 30

    // Parlaklık ölçümünün ne kadar yumuşatılacağı (0–1 arası).
    // Küçük değer → ani değişimlere daha az duyarlı, daha kararlı ölçüm.
    let brightnessAlpha: CGFloat = 0.2

    // Bu parlaklık değerinin altında "çok karanlık" uyarısı verilir.
    let darkEnterThreshold: CGFloat = 500

    // "Çok karanlık" uyarısının bitmesi için gereken parlaklık değeri.
    // Giriş eşiğinden biraz yüksek tutularak uyarının titremesi önlenir.
    let darkExitThreshold: CGFloat = 600

    // Bu parlaklık değerinin üstünde "çok aydınlık" uyarısı verilir.
    let brightEnterThreshold: CGFloat = 3000

    // "Çok aydınlık" uyarısının bitmesi için gereken parlaklık değeri.
    // Giriş eşiğinden biraz düşük tutularak uyarının titremesi önlenir.
    let brightExitThreshold: CGFloat = 2800

    // Başın ne kadar öne/arkaya eğilince uyarı verileceği.
    // Küçük değer → daha az eğimde uyarı verir.
    let tiltEnterThreshold: CGFloat = 0.50

    // Eğim uyarısının bitmesi için gereken eşik.
    // Giriş eşiğinden düşük tutularak uyarının titremesi önlenir.
    let tiltExitThreshold: CGFloat = 0.40

    // Yüz oval genişliğinin bu oranını aşınca "çok yakın" uyarısı verilir.
    // 1.0'a yakın değer → yüz neredeyse ovali doldurunca uyarı verir.
    let closeEnterFraction: CGFloat = 0.98

    // "Çok yakın" uyarısının bitmesi için gereken oran.
    // Giriş oranından düşük tutularak uyarının titremesi önlenir.
    let closeExitFraction: CGFloat = 0.93

    // Yüz oval genişliğinin bu oranının altında kalınca "çok uzak" uyarısı verilir.
    // Büyük değer → daha yakına gelmesi beklenir.
    let farEnterFraction: CGFloat = 0.60

    // "Çok uzak" uyarısının bitmesi için gereken oran.
    // Giriş oranından büyük tutularak uyarının titremesi önlenir.
    let farExitFraction: CGFloat = 0.65

    // Yüz merkezinin ovalden ne kadar saptığında yön uyarısı verileceği.
    // Küçük değer → oval ortasına daha yakın durulması gerekir.
    let positionEnterFraction: CGFloat = 0.20

    // Yön uyarısının bitmesi için gereken sapma miktarı.
    // Giriş değerinden küçük tutularak uyarının titremesi önlenir.
    let positionExitFraction: CGFloat = 0.14

    // Mesafe hesabında kullanılan ortalama yüz genişliği (metre).
    // Farklı kişilere göre ince ayar gerekirse bu değer değiştirilebilir.
    let faceWidthMeters: CGFloat = 0.076

    // Mesafe hesabında kullanılan ortalama yüz yüksekliği (metre).
    // Oval içine sığma kontrolünü de etkiler.
    let faceHeightMeters: CGFloat = 0.092
}

// MARK: - SDKSelfieWithLivenessViewController

class SDKSelfieWithLivenessViewController: SDKBaseViewController {

    // MARK: - State

    private enum VerifyState {
        case warmingUp, idle, faceDetected, holding, verified
    }

    // MARK: - Face Condition

    private enum FaceCondition: Equatable {
        case tooDark, tooBright
        case tiltedUp, tiltedDown
        case tooClose, tooFar
        case tooHigh, tooLow
        case tooLeft, tooRight
        case notFitting
        case ok
    }

    // MARK: - Properties

    private var arView: ARSCNView!
    private var faceNode: SCNNode?
    private var overlayMask: FaceOvalMaskView!
    private var faceProgressLoader: FaceProgressLoader!
    private var instructionLabel: UILabel!

    private let configuration = ARFaceTrackingConfiguration()
    private let config = LivenessConfig()

    private var state: VerifyState = .warmingUp
    private var holdStartDate: Date?
    private var okFrameCounter: Int  = 0
    private var badFrameCounter: Int = 0
    private var warmupFrameCounter: Int = 0

    private var lastInstructionText: String = "Hazırlanıyor..."

    private var smoothedIntensity: CGFloat?

    private var hyst_tooDark    = false
    private var hyst_tooBright  = false
    private var hyst_tiltedUp   = false
    private var hyst_tiltedDown = false
    private var hyst_tooClose   = false
    private var hyst_tooFar     = false
    private var hyst_tooHigh    = false
    private var hyst_tooLow     = false
    private var hyst_tooLeft    = false
    private var hyst_tooRight   = false

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
        smoothedIntensity = nil
        hyst_tooDark    = false
        hyst_tooBright  = false
        hyst_tiltedUp   = false
        hyst_tiltedDown = false
        hyst_tooClose   = false
        hyst_tooFar     = false
        hyst_tooHigh    = false
        hyst_tooLow     = false
        hyst_tooLeft    = false
        hyst_tooRight   = false
        faceProgressLoader.isHidden = true
        setInstruction("Hazırlanıyor...")
        arView.session.run(configuration)
    }

    // MARK: - Condition Checks

    private func evaluateConditions(faceAnchor: ARFaceAnchor) -> FaceCondition {
        if let c = checkBrightness()             { return c }
        if let c = checkTilt(faceAnchor)         { return c }
        if let c = checkFacePosition(faceAnchor) { return c }
        if !isFaceFittingOval(faceAnchor)        { return .notFitting }
        return .ok
    }

    private func checkBrightness() -> FaceCondition? {
        guard let raw = arView.session.currentFrame?.lightEstimate?.ambientIntensity else { return nil }
        let intensity = CGFloat(raw)
        if smoothedIntensity == nil { smoothedIntensity = intensity }
        smoothedIntensity = config.brightnessAlpha * intensity + (1 - config.brightnessAlpha) * smoothedIntensity!
        let s = smoothedIntensity!

        if hyst_tooDark {
            if s > config.darkExitThreshold { hyst_tooDark = false } else { return .tooDark }
        } else if s < config.darkEnterThreshold {
            hyst_tooDark = true; return .tooDark
        }

        if hyst_tooBright {
            if s < config.brightExitThreshold { hyst_tooBright = false } else { return .tooBright }
        } else if s > config.brightEnterThreshold {
            hyst_tooBright = true; return .tooBright
        }

        return nil
    }

    private func checkTilt(_ faceAnchor: ARFaceAnchor) -> FaceCondition? {
        let pitchY = CGFloat(faceAnchor.transform.columns.2.y)

        if hyst_tiltedDown {
            if pitchY <  config.tiltExitThreshold  { hyst_tiltedDown = false } else { return .tiltedDown }
        } else if pitchY >  config.tiltEnterThreshold {
            hyst_tiltedDown = true; return .tiltedDown
        }

        if hyst_tiltedUp {
            if pitchY > -config.tiltExitThreshold  { hyst_tiltedUp = false } else { return .tiltedUp }
        } else if pitchY < -config.tiltEnterThreshold {
            hyst_tiltedUp = true; return .tiltedUp
        }

        return nil
    }

    private func checkFacePosition(_ faceAnchor: ARFaceAnchor) -> FaceCondition? {
        let oval = ovalRect(in: view.bounds)
        let col  = faceAnchor.transform.columns.3
        let proj = arView.projectPoint(SCNVector3(col.x, col.y, col.z))
        let centerPt = CGPoint(x: CGFloat(proj.x), y: CGFloat(proj.y))

        let depth = abs(col.z)
        guard depth > 0, let frame = arView.session.currentFrame else { return nil }
        let focalX = CGFloat(frame.camera.intrinsics.columns.0.x)
        let projectedW = focalX * config.faceWidthMeters / CGFloat(depth)

        if hyst_tooClose {
            if projectedW < oval.width * config.closeExitFraction  { hyst_tooClose = false } else { return .tooClose }
        } else if projectedW > oval.width * config.closeEnterFraction {
            hyst_tooClose = true; return .tooClose
        }

        if hyst_tooFar {
            if projectedW > oval.width * config.farExitFraction    { hyst_tooFar = false }   else { return .tooFar }
        } else if projectedW < oval.width * config.farEnterFraction {
            hyst_tooFar = true; return .tooFar
        }

        let dy = centerPt.y - oval.midY
        let dx = centerPt.x - oval.midX

        if hyst_tooHigh {
            if dy > -(oval.height * config.positionExitFraction)   { hyst_tooHigh = false } else { return .tooHigh }
        } else if dy < -(oval.height * config.positionEnterFraction) {
            hyst_tooHigh = true; return .tooHigh
        }

        if hyst_tooLow {
            if dy <  oval.height * config.positionExitFraction     { hyst_tooLow = false }  else { return .tooLow }
        } else if dy >  oval.height * config.positionEnterFraction {
            hyst_tooLow = true; return .tooLow
        }

        if hyst_tooRight {
            if dx > -(oval.width * config.positionExitFraction)    { hyst_tooRight = false } else { return .tooRight }
        } else if dx < -(oval.width * config.positionEnterFraction) {
            hyst_tooRight = true; return .tooRight
        }

        if hyst_tooLeft {
            if dx <  oval.width * config.positionExitFraction      { hyst_tooLeft = false }  else { return .tooLeft }
        } else if dx >  oval.width * config.positionEnterFraction {
            hyst_tooLeft = true; return .tooLeft
        }

        return nil
    }

    private func isFaceFittingOval(_ faceAnchor: ARFaceAnchor) -> Bool {
        let oval = ovalRect(in: view.bounds)
        let col  = faceAnchor.transform.columns.3
        let proj = arView.projectPoint(SCNVector3(col.x, col.y, col.z))
        let centerPt = CGPoint(x: CGFloat(proj.x), y: CGFloat(proj.y))

        let cx = (centerPt.x - oval.midX) / (oval.width  / 2)
        let cy = (centerPt.y - oval.midY) / (oval.height / 2)
        guard cx * cx + cy * cy < 0.25 else { return false }

        let depth = abs(col.z)
        guard let frame = arView.session.currentFrame else { return false }
        let intrinsics = frame.camera.intrinsics
        let focalX = CGFloat(intrinsics.columns.0.x)
        let focalY = CGFloat(intrinsics.columns.1.y)
        let projectedW = focalX * config.faceWidthMeters  / CGFloat(depth)
        let projectedH = focalY * config.faceHeightMeters / CGFloat(depth)

        let points: [CGPoint] = [
            CGPoint(x: centerPt.x - projectedW / 2, y: centerPt.y),
            CGPoint(x: centerPt.x + projectedW / 2, y: centerPt.y),
            CGPoint(x: centerPt.x,                  y: centerPt.y - projectedH * 0.55),
            CGPoint(x: centerPt.x,                  y: centerPt.y + projectedH * 0.45),
        ]
        for pt in points {
            let dx = (pt.x - oval.midX) / (oval.width  / 2)
            let dy = (pt.y - oval.midY) / (oval.height / 2)
            if dx * dx + dy * dy > 0.85 { return false }
        }
        return true
    }

    private func instructionText(for condition: FaceCondition) -> String {
        switch condition {
        case .tooDark:    return "Ortam çok karanlık, daha aydınlık bir yere geçin"
        case .tooBright:  return "Ortam çok aydınlık, gölgeye geçin"
        case .tiltedDown: return "Başınızı yukarı kaldırın"
        case .tiltedUp:   return "Başınızı öne eğin"
        case .tooClose:   return "Biraz geriye gidin"
        case .tooFar:     return "Biraz öne gelin"
        case .tooHigh:    return "Yüzünüzü biraz aşağı alın"
        case .tooLow:     return "Yüzünüzü biraz yukarı alın"
        case .tooLeft:    return "Yüzünüzü sola kaydırın"
        case .tooRight:   return "Yüzünüzü sağa kaydırın"
        case .notFitting: return "Yüzünüzü çerçeve içine yerleştirin"
        case .ok:         return "Hareketsiz kalın..."
        }
    }

    // MARK: - Face Detection Logic

    private func handleFaceDetected(_ faceAnchor: ARFaceAnchor) {
        guard state != .verified, state != .warmingUp else { return }

        let condition = evaluateConditions(faceAnchor: faceAnchor)

        if condition == .ok {
            badFrameCounter = 0
            okFrameCounter += 1
            setInstruction(instructionText(for: .ok))

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
                if badFrameCounter >= config.badFrameThreshold {
                    state = .faceDetected
                    holdStartDate = nil
                    faceProgressLoader.setProgress(0, animated: false)
                    setInstruction(instructionText(for: condition))
                }
            } else {
                state = .faceDetected
                holdStartDate = nil
                faceProgressLoader.setProgress(0, animated: false)
                setInstruction(instructionText(for: condition))
            }
        }
    }

    private func handleNoFace() {
        guard state != .verified else { return }
        state = .idle
        holdStartDate = nil
        okFrameCounter  = 0
        badFrameCounter = 0
        faceProgressLoader.setProgress(0, animated: false)
        setInstruction("Yüzünüzü çerçeve içine yerleştirin")
    }

    private func handleWarmupFrame() {
        warmupFrameCounter += 1
        if warmupFrameCounter >= config.warmupFrameCount {
            state = .idle
            faceProgressLoader.isHidden = false
            faceProgressLoader.startDashAnimation()
            setInstruction("Yüzünüzü çerçeve içine yerleştirin")
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
            self.faceProgressLoader.isHidden = true
            self.faceNode?.isHidden = true
            let image = self.arView.snapshot()
            self.faceNode?.isHidden = false
            self.faceProgressLoader.isHidden = false
            self.uploadAndProceed(image: image)
        }
    }

    // MARK: - State Reset

    private func resetState() {
        state = .idle
        holdStartDate = nil
        okFrameCounter  = 0
        badFrameCounter = 0
        smoothedIntensity = nil
        hyst_tooDark    = false
        hyst_tooBright  = false
        hyst_tiltedUp   = false
        hyst_tiltedDown = false
        hyst_tooClose   = false
        hyst_tooFar     = false
        hyst_tooHigh    = false
        hyst_tooLow     = false
        hyst_tooLeft    = false
        hyst_tooRight   = false
        hideLoader()
        faceProgressLoader.setProgress(0, animated: false)
        faceProgressLoader.updateRingColors(
            track: .white.withAlphaComponent(0.3),
            progress: .white
        )
        faceProgressLoader.startDashAnimation()
        setInstruction("Yüzünüzü çerçeve içine yerleştirin")
    }

    // MARK: - Upload

    private func uploadAndProceed(image: UIImage) {
        showLoader()
        arView.session.pause()

        manager.uploadIdPhoto(idPhoto: image, selfieType: .selfieWithLiveness) { [weak self] response in
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
