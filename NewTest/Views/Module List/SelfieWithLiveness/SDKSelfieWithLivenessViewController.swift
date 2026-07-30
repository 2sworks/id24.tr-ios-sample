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

// MARK: - SelfieDepthConfig (K)

// Tüm sihirli sayılar burada toplanmıştır; tuning ve test için.
// (Ad SelfieDepthConfig: SampleApp target'ında Call Screen içindeki internal LivenessConfig ile çakışmasın diye.)
private struct SelfieDepthConfig {
    // Hold süresi
    let requiredHoldDuration: TimeInterval = 3.0
    // Faz 1 (küçük oval) için yüzün kesintisiz uygun kalması gereken kısa süre; dolunca oval büyür.
    let smallOvalHoldDuration: TimeInterval = 1.0

    // Debounce: holding'e girmek için gereken ardışık ok frame sayısı (A)
    let okFrameThreshold: Int = 5
    // Debounce: holding'i düşürmek için gereken ardışık kötü frame sayısı (A)
    let badFrameThreshold: Int = 3

    // Warm-up: ARKit session başladıktan sonra beklenecek stabil frame sayısı (M)
    // ~30fps'de ≈1s; ~60fps'de ≈0.5s — zaman tabanlı değil frame tabanlı tercih edildi (M)
    let warmupFrameCount: Int = 30

    // Brightness EMA smoothing faktörü: α=0.2 → pürüzsüz, yavaş tepki (C)
    let brightnessAlpha: CGFloat = 0.2
    let darkEnterThreshold: CGFloat  = 500
    let darkExitThreshold: CGFloat   = 600   // tooDark'tan çıkmak için bu değerin üstüne çıkılmalı
    let brightEnterThreshold: CGFloat = 3000
    let brightExitThreshold: CGFloat  = 2800

    // Tilt hysteresis (B): enter=0.50, exit=0.40
    let tiltEnterThreshold: CGFloat = 0.50
    let tiltExitThreshold:  CGFloat = 0.40

    // Mesafe — ARKit depth (metre, negatif z) kullanılır; kamera piksel birimi karışmaz
    // tooFar : kameraya 55cm'den uzaksa → yaklaş (0.50m altına düşünce çıkar)
    // tooClose: kameraya 22cm'den yakınsa → uzaklaş (0.27m üstüne çıkınca çıkar)
    let tooFarDepth:     Float = 0.55
    let tooFarExitDepth: Float = 0.50
    let tooCloseDepth:     Float = 0.22
    let tooCloseExitDepth: Float = 0.27

    // Pozisyon hysteresis — oval boyutunun fraksiyonu olarak (B)
    let positionEnterFraction: CGFloat = 0.20
    let positionExitFraction:  CGFloat = 0.14
}

// MARK: - SDKSelfieWithLivenessViewController

class SDKSelfieWithLivenessViewController: SDKBaseViewController {

    // MARK: - State (M: warmingUp eklendi)

    private enum VerifyState {
        case warmingUp, idle, faceDetected, holding, verified
    }

    // İki fazlı oval: küçük ovalde yüz yerleşince (kısa tutma) büyük ovale geçilir; çekim büyük ovalde.
    private enum OvalPhase { case small, large }

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
    // Yüz mesh'i gizli mi. Gizleme materyal transparency=0 ile yapılır (isHidden bazı cihazlarda güvenilir
    // çizim durdurmuyor); yeni oluşan node'lar da bu duruma uyar.
    private var faceMeshHidden = false
    private var overlayMask: FaceOvalMaskView!
    private var faceProgressLoader: FaceProgressLoader!
    private var instructionLabel: UILabel!

    private let configuration = ARFaceTrackingConfiguration()
    private let config = SelfieDepthConfig()

    // Oval genişliğinin ekran genişliğine oranı: küçük faz 0.50, büyük faz 0.75 (büyük ekranı aşmaz; oran yine 1.5).
    private var ovalScale: CGFloat { ovalPhase == .small ? 0.5 : 0.75 }
    // Metre eşiği çarpanı: küçük faz ×1.5 (yüz DAHA UZAK, küçük ovale otursun), büyük faz ×1.0 (çalışan çekim
    // mesafesi). Böylece iki faz mesafesi belirgin farklı: önce uzakta küçük ovale otur, sonra yaklaşıp büyük ovalde çek.
    private var depthScale: Float { ovalPhase == .small ? 1.5 : 1.0 }

    // State machine — yalnızca main thread'de mutate edilir (F)
    private var state: VerifyState = .warmingUp
    private var ovalPhase: OvalPhase = .small
    // Oval büyüme animasyonunu süren tween (küçük→büyük ölçek geçişi).
    private var ovalScaleLink: CADisplayLink?
    private var ovalScaleAnimStart: CFTimeInterval = 0
    private var ovalScaleFrom: CGFloat = 0
    private var ovalScaleTo: CGFloat = 0
    private let ovalScaleAnimDuration: CFTimeInterval = 0.35
    private var holdStartDate: Date?
    private var okFrameCounter: Int  = 0
    private var badFrameCounter: Int = 0
    private var warmupFrameCounter: Int = 0

    // Instruction dedup — aynı metin tekrar set edilmez (E)
    private var lastInstructionText: String = "Hazırlanıyor..."

    // Condition instruction debounce — 2 ardışık aynı frame sonra uygulanır
    private var conditionInstructionPending: String = ""
    private var conditionInstructionFrames: Int = 0

    // Brightness EMA state (C)
    private var smoothedIntensity: CGFloat?

    // Per-condition hysteresis flags — main thread (B)
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
        view.backgroundColor = .black
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
        ovalScaleLink?.invalidate(); ovalScaleLink = nil
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
        if #available(iOS 17, *) { arView.delegate = self }
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
        // Warm-up sayaçlarını sıfırla; loader gizle (M)
        state = .warmingUp
        ovalPhase = .small
        setOvalScaleInstant(0.5)
        setFaceMeshHidden(false)   // yeni oturumda mesh yeniden görünür
        warmupFrameCounter = 0
        okFrameCounter  = 0
        badFrameCounter = 0
        conditionInstructionPending = ""
        conditionInstructionFrames  = 0
        smoothedIntensity = nil
        faceProgressLoader.isHidden = true
        overlayMask.isHidden = false
        setInstruction("Hazırlanıyor...")
        arView.session.run(configuration)
    }

    // MARK: - Condition Checks (main thread only — F)

    private func evaluateConditions(faceAnchor: ARFaceAnchor) -> FaceCondition {
        if let c = checkBrightness()          { return c }
        if let c = checkTilt(faceAnchor)      { return c }
        if let c = checkFacePosition(faceAnchor) { return c }
        if !isFaceFittingOval(faceAnchor)     { return .notFitting }
        return .ok
    }

    // EMA smoothing + hysteresis (B, C)
    private func checkBrightness() -> FaceCondition? {
        guard let raw = arView.session.currentFrame?.lightEstimate?.ambientIntensity else { return nil }
        let intensity = CGFloat(raw)
        if smoothedIntensity == nil { smoothedIntensity = intensity }
        smoothedIntensity = config.brightnessAlpha * intensity + (1 - config.brightnessAlpha) * smoothedIntensity!
        let s = smoothedIntensity!

        // Karanlık artık çekimi ENGELLEMEZ (.tooDark kaldırıldı). Aydınlatma, çekim anında ekran flaşıyla yapılır.
        if hyst_tooBright {
            if s < config.brightExitThreshold { hyst_tooBright = false } else { return .tooBright }
        } else if s > config.brightEnterThreshold {
            hyst_tooBright = true; return .tooBright
        }

        return nil
    }

    // Hysteresis (B): enter=0.50, exit=0.40
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

    // Projeksiyon main thread'de yapıldığı için view.bounds doğrudan okunabilir (F, H)
    private func checkFacePosition(_ faceAnchor: ARFaceAnchor) -> FaceCondition? {
        let oval = ovalRect(in: view.bounds, scale: ovalScale)
        let col  = faceAnchor.transform.columns.3
        let proj = arView.projectPoint(SCNVector3(col.x, col.y, col.z))
        let centerPt = CGPoint(x: CGFloat(proj.x), y: CGFloat(proj.y))

        // Mesafe: col.z ARKit kamera uzayında negatif, abs değeri metre cinsinden gerçek derinlik.
        // focalX/projectedW yerine doğrudan depth kullanılır — kamera piksel/view point birim karışıklığı önlendi.
        let depth = abs(col.z)
        guard depth > 0 else { return nil }

        // Metre eşikleri faza göre ölçeklenir: küçük fazda yüz daha uzak, büyük fazda daha yakın olmalı.
        let s = depthScale
        if hyst_tooClose {
            if depth > config.tooCloseExitDepth * s { hyst_tooClose = false } else { return .tooClose }
        } else if depth < config.tooCloseDepth * s {
            hyst_tooClose = true; return .tooClose
        }

        if hyst_tooFar {
            if depth < config.tooFarExitDepth * s { hyst_tooFar = false } else { return .tooFar }
        } else if depth > config.tooFarDepth * s {
            hyst_tooFar = true; return .tooFar
        }

        let dy = centerPt.y - oval.midY
        let dx = centerPt.x - oval.midX

        // Dikey pozisyon hysteresis (B)
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

        // Yatay pozisyon hysteresis (B) — selfie ayna: dx yönü ters
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
        let oval = ovalRect(in: view.bounds, scale: ovalScale)
        let col  = faceAnchor.transform.columns.3
        let proj = arView.projectPoint(SCNVector3(col.x, col.y, col.z))
        let centerPt = CGPoint(x: CGFloat(proj.x), y: CGFloat(proj.y))

        // Yüz merkezi oval'in %70 iç bölgesinde olmalı
        // (intrinsics-tabanlı köşe kontrolü kamera piksel/view point birim uyuşmazlığı nedeniyle kaldırıldı)
        let cx = (centerPt.x - oval.midX) / (oval.width  / 2)
        let cy = (centerPt.y - oval.midY) / (oval.height / 2)
        return cx * cx + cy * cy < 0.7
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

    // MARK: - Face Detection Logic (main thread only — F)

    // Progress zaman tabanlı (Date farkı); frame counter debounce için kullanılır (A).
    // Yorum: requiredOkFrames sabit sayı yerine okFrameThreshold + holdStartDate kombinasyonu tercih edildi;
    // bu sayede farklı FPS'lerde (30–60Hz) 3.0s hold süresi tutarlı kalır.
    private func handleFaceDetected(_ faceAnchor: ARFaceAnchor) {
        guard state != .verified, state != .warmingUp else { return }

        let condition = evaluateConditions(faceAnchor: faceAnchor)

        if condition == .ok {
            badFrameCounter = 0
            okFrameCounter += 1
            queueConditionInstruction(instructionText(for: .ok))

            if state != .holding {
                // okFrameThreshold ardışık ok frame sonra holding başlar (A)
                if okFrameCounter >= config.okFrameThreshold {
                    state = .holding
                    holdStartDate = Date()
                }
            }

            if state == .holding, let start = holdStartDate {
                let holdDur = (ovalPhase == .small) ? config.smallOvalHoldDuration : config.requiredHoldDuration
                let elapsed = Date().timeIntervalSince(start)
                let progress = CGFloat(min(1.0, elapsed / holdDur))
                faceProgressLoader.setProgress(progress, animated: false)

                if elapsed >= holdDur {
                    // Faz 1: küçük ovalde kısa tutma dolunca oval büyür; Faz 2: büyük ovalde çekim yapılır.
                    if ovalPhase == .small { growToLargePhase() } else { finalizeVerification() }
                }
            }
        } else {
            okFrameCounter = 0
            badFrameCounter += 1

            if state == .holding {
                // Grace period: badFrameThreshold'a kadar holding state korunur,
                // progress sıfırlanmaz. Talimat debounce ile hemen kuyruğa alınır (A + Fix 2).
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
        setInstruction("Yüzünüzü çerçeve içine yerleştirin")
    }

    // Warm-up frame sayacı; eşiğe ulaşınca loader gösterilir (M)
    private func handleWarmupFrame() {
        warmupFrameCounter += 1
        if warmupFrameCounter >= config.warmupFrameCount {
            state = .idle
            faceProgressLoader.isHidden = false
            faceProgressLoader.startDashAnimation()
            setInstruction("Yüzünüzü çerçeve içine yerleştirin")
        }
    }

    // Faz 1 tamamlandı: küçük ovalde yüz kısa süre tutuldu → büyük ovale geç. Çekim burada YAPILMAZ;
    // büyük ovalde ikinci tutma dolunca finalizeVerification() çalışır.
    private func growToLargePhase() {
        guard ovalPhase == .small else { return }
        ovalPhase = .large
        // Oval küçükten büyüğe yumuşak büyür (mask + halka senkron). Mantık ovali anında büyür (ovalScale
        // hesaplanan değeri .large'a döner); yalnızca çizim animasyonludur.
        animateOvalScale(from: overlayMask.ovalScale, to: ovalScale)
        state = .faceDetected
        holdStartDate = nil
        okFrameCounter = 0; badFrameCounter = 0
        faceProgressLoader.setProgress(0, animated: false)
        // depthScale artık ×1.0 (×1.5'ten yakın); uzaktaki yüz .tooFar okunur, "yaklaşın" talimatı doğal çıkar.
    }

    // Oval boyut çarpanını CADisplayLink ile yumuşak (easeInOut) süren tween; mask ve halkayı eşzamanlı büyütür.
    private func animateOvalScale(from: CGFloat, to: CGFloat) {
        ovalScaleLink?.invalidate()
        ovalScaleFrom = from
        ovalScaleTo = to
        ovalScaleAnimStart = CACurrentMediaTime()
        let link = CADisplayLink(target: self, selector: #selector(stepOvalScale))
        link.add(to: .main, forMode: .common)
        ovalScaleLink = link
    }

    @objc private func stepOvalScale() {
        let raw = (CACurrentMediaTime() - ovalScaleAnimStart) / ovalScaleAnimDuration
        let t = min(1, max(0, raw))
        let eased = t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
        let value = ovalScaleFrom + (ovalScaleTo - ovalScaleFrom) * CGFloat(eased)
        overlayMask.ovalScale = value
        faceProgressLoader.ovalScale = value
        if t >= 1 {
            ovalScaleLink?.invalidate()
            ovalScaleLink = nil
        }
    }

    // Oval boyutunu animasyonsuz ayarlar (sıfırlama/yeni oturum için).
    private func setOvalScaleInstant(_ scale: CGFloat) {
        ovalScaleLink?.invalidate(); ovalScaleLink = nil
        overlayMask.ovalScale = scale
        faceProgressLoader.ovalScale = scale
    }

    // Yüz mesh'ini gizler/gösterir. Gizleme materyal transparency=0 ile (kesin çizim durdurur); güncel node
    // ve bundan sonra oluşacak node'lar da bu duruma uyar.
    private func setFaceMeshHidden(_ hidden: Bool) {
        faceMeshHidden = hidden
        applyFaceMeshVisibility(to: faceNode)
    }

    private func applyFaceMeshVisibility(to node: SCNNode?) {
        node?.isHidden = faceMeshHidden
        node?.geometry?.firstMaterial?.transparency = faceMeshHidden ? 0 : 0.55
    }

    private func finalizeVerification() {
        guard state != .verified else { return }
        state = .verified

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        faceProgressLoader.setProgress(1.0, animated: true)
        faceProgressLoader.updateRingColors(track: .systemGreen, progress: .systemGreen)
        faceProgressLoader.stopDashAnimation()
        setInstruction("Doğrulandı ✓")

        // Yüz mesh'ini çekimden ~1 sn önce kapat (fotoğrafta wireframe olmasın); yeşil halka bu 1 sn görünür kalır.
        setFaceMeshHidden(true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.faceProgressLoader.isHidden = true
            self.overlayMask.isHidden = true
            self.captureWithFlash()
        }
    }

    // Çekim anı flaşı (normal kamera gibi): ön kamerada donanım feneri olmadığından ekran kısa süre beyaz yanıp
    // yüzü aydınlatır, kamera bu ışıkla pozladıktan sonra kare alınır. Beyaz katman snapshot'a girmez
    // (arView.snapshot yalnızca kamera katmanını alır); sonra parlaklık geri yüklenir.
    private func captureWithFlash() {
        let flashView = UIView(frame: view.bounds)
        flashView.backgroundColor = .white
        flashView.alpha = 0
        flashView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        flashView.isUserInteractionEnabled = false
        view.addSubview(flashView)
        let previousBrightness = UIScreen.main.brightness
        UIScreen.main.brightness = 1.0
        // Yumuşak flaş: beyaz 0.30 sn'de belirir (ani "patlama"dan ~%50 yavaş); zirvede, kamera ekran ışığıyla
        // pozladıktan sonra kare alınır, ardından beyaz kaybolur ve parlaklık geri gelir.
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            flashView.alpha = 1
        }, completion: { _ in
            let image = self.arView.snapshot()
            // Kareyi aldıktan sonra oturumu durdur ve sahneyi sıfırla: donmuş yeşil halka/mesh gibi
            // "yarım kalmış" görüntü kalmasın. (Pause, kalan karelerin state makinesini tekrar tetiklemesini önler.)
            self.arView.session.pause()
            self.resetState()
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
                flashView.alpha = 0
            }, completion: { _ in
                flashView.removeFromSuperview()
                UIScreen.main.brightness = previousBrightness
            })
            self.uploadAndProceed(image: image)
        })
    }

    // MARK: - State Reset

    private func resetState() {
        state = .idle
        holdStartDate = nil
        ovalPhase = .small
        setOvalScaleInstant(0.5)
        okFrameCounter  = 0
        badFrameCounter = 0
        conditionInstructionPending = ""
        conditionInstructionFrames  = 0
        smoothedIntensity = nil
        overlayMask.isHidden = false
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

        manager.uploadIdPhoto(idPhoto: image, selfieType: .selfie) { [weak self] response in
            guard let self = self else { return }

            if response.result == true && response.data?.comparison == false {
                DispatchQueue.main.async {
                    self.hideLoader()
                    let isFinalAttempt = self.manager.selfieComparisonCount == self.manager.tryedSelfieComparisonCount
                    if isFinalAttempt {
                        self.oneButtonAlertShow(
                            appName: "İşleminiz Başarısız",
                            message: "İşleminiz başarısız oldu.",
                            title1: "Bitir"
                        ) {
                            if self.manager.activeComparisonResultSkipModule == "1" {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    self.skipModuleAct()
                                }
                            } else {
                                self.closeSDK()
                            }
                        }
                    } else {
                        let retryMessage = "✓ Yüzünüzün net ve tam olarak göründüğünden emin olun.\n✓ Kimlik sahibi kişinin işlemi gerçekleştirdiğinden emin olun.\n✓ Yeterli ışık bulunan bir ortamda çekim yapın."
                        self.oneButtonAlertShow(
                            appName: "İşlem Tamamlanamadı",
                            message: retryMessage,
                            title1: "Tekrar Dene"
                        ) {
                            self.manager.tryedSelfieComparisonCount += 1
                            self.startSession()   // mesh görünürlüğü startSession içinde geri açılır
                        }
                    }
                }
            } else if response.result == true {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // Modül başarıyla geçildi: deneme sayacı sıfırlanır (sonraki girişte eski sayaç
                    // taşınmasın), loader gizlenir. Modül GEÇERKEN tam reset yapılır:
                    //  • AR oturumu resetTracking + removeExistingAnchors ile temizlenir (bayat
                    //    takip/anchor sonraki girişe taşınmasın), sonra durdurulur.
                    //  • resetState() koşulsuz çağrılır (getNextModule callback'ini beklemeden).
                    self.manager.tryedSelfieComparisonCount = 1
                    self.hideLoader()
                    self.arView?.session.run(self.configuration, options: [.resetTracking, .removeExistingAnchors])
                    self.arView?.session.pause()
                    self.resetState()
                    self.manager.getNextModule { nextVC in
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

    // Aynı metin tekrar set edilmez — her frame relayout önlenir (E)
    // Çağrıldığı nokta her zaman main thread'dir (F)
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
// ARSCNViewDelegate conformansı iOS 17+ gerektiriyor; sınıfa değil extension'a eklendi

@available(iOS 17, *)
extension SDKSelfieWithLivenessViewController: ARSCNViewDelegate {

    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let _ = anchor as? ARFaceAnchor, let device = arView.device else { return nil }
        let faceMesh = ARSCNFaceGeometry(device: device)
        let node = SCNNode(geometry: faceMesh)
        let material = node.geometry?.firstMaterial
        material?.fillMode = .lines
        material?.diffuse.contents = UIColor.white   // görünürlük transparency ile yönetilir
        material?.isDoubleSided = true
        faceNode = node
        // Güncel gizli/görünür duruma uy (çekim aşamasında gelen yeni anchor'da mesh geri gelmesin).
        applyFaceMeshVisibility(to: node)
        // Loader gösterimini render callback'e bırakıyoruz (M); nodeFor'da gecikme yok
        return node
    }

    // Render thread'den çağrılır; yalnızca SCNGeometry güncellenir burada.
    // Tüm state mutasyonları main thread'e dispatch edilir (F).
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard state != .verified,
              let faceAnchor = anchor as? ARFaceAnchor,
              let faceGeometry = node.geometry as? ARSCNFaceGeometry else { return }

        // SceneKit geometry güncellemesi render thread'de güvenlidir
        faceGeometry.update(from: faceAnchor.geometry)

        let isTracked = faceAnchor.isTracked
        let capturedAnchor = faceAnchor   // ARKit anchor read-only thread-safe

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

private func ovalRect(in bounds: CGRect, scale: CGFloat = 0.75) -> CGRect {
    let ovalW = bounds.width * scale
    let ovalH = ovalW * 1.35
    return CGRect(x: (bounds.width  - ovalW) / 2,
                  y: (bounds.height - ovalH) / 2 - 20,
                  width: ovalW,
                  height: ovalH)
}

// MARK: - FaceOvalMaskView

private class FaceOvalMaskView: UIView {
    // Oval genişlik oranı (küçük faz 0.50, büyük faz 0.75). Controller büyüme animasyonu boyunca günceller.
    var ovalScale: CGFloat = 0.5 { didSet { setNeedsDisplay() } }
    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        UIColor.black.withAlphaComponent(0.80).setFill()
        ctx.fill(rect)
        ctx.setBlendMode(.clear)
        UIBezierPath(ovalIn: ovalRect(in: rect, scale: ovalScale)).fill()
    }
}

// MARK: - FaceProgressLoader

private class FaceProgressLoader: UIView {

    // MARK: - Layers
    //
    // Tek halka stratejisi (L):
    //   trackLayer  — sabit ekran ovalinin üzerinde; progress arkaplanı
    //   progressLayer — aynı path üzerinde dolan progress
    //   spinnerLayer  — ovalin 10px dışında dönen dash halka; idle animasyonu
    //
    // Yüze yapışan dinamik oval kaldırıldı; tüm path'ler ovalRect(in:bounds)'tan üretilir.

    private let trackLayer    = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private let spinnerLayer  = CAShapeLayer()

    private var currentProgress: CGFloat = 0

    // Throttle (G): bounds değişmezse path yeniden set edilmez
    private var lastPathBounds: CGRect = .zero
    private var lastPathScale: CGFloat = -1
    // Oval genişlik oranı (küçük faz 0.50, büyük faz 0.75). Değişince halka path'leri yeniden kurulur.
    var ovalScale: CGFloat = 0.5 { didSet { updateRingPaths() } }

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

        trackLayer.fillColor   = UIColor.clear.cgColor
        trackLayer.strokeColor = UIColor.white.withAlphaComponent(0.3).cgColor
        trackLayer.lineWidth   = 4
        trackLayer.lineCap     = .round
        trackLayer.lineDashPattern = [30, 40]
        trackLayer.isHidden    = true   // spinnerLayer dış halkayı karşılar; trackLayer gizli kalır
        layer.addSublayer(trackLayer)

        progressLayer.fillColor   = UIColor.clear.cgColor
        progressLayer.strokeColor = UIColor.white.cgColor
        progressLayer.lineWidth   = 4
        progressLayer.lineCap     = .round
        progressLayer.lineDashPattern = [30, 40]
        progressLayer.strokeStart = 0
        progressLayer.strokeEnd   = 0
        layer.addSublayer(progressLayer)

        spinnerLayer.fillColor   = UIColor.clear.cgColor
        spinnerLayer.strokeColor = UIColor.white.withAlphaComponent(0.6).cgColor
        spinnerLayer.lineWidth   = 3
        spinnerLayer.lineCap     = .round
        spinnerLayer.lineDashPattern = [12, 20]
        spinnerLayer.strokeEnd   = 1
        spinnerLayer.isHidden    = true
        layer.addSublayer(spinnerLayer)
    }

    // MARK: - Path Update (G)

    // CATransaction ile implicit animation kapatılır;
    // bounds değişmezse path tekrar set edilmez (throttle).
    private func updateRingPaths() {
        let b = bounds
        guard abs(b.width  - lastPathBounds.width)  > 1 ||
              abs(b.height - lastPathBounds.height) > 1 ||
              abs(ovalScale - lastPathScale) > 0.0001 else { return }
        lastPathBounds = b
        lastPathScale = ovalScale

        let oval = ovalRect(in: b, scale: ovalScale)
        let innerPath  = makeBezierOval(cx: oval.midX, cy: oval.midY,
                                        rx: oval.width / 2,
                                        ry: oval.height / 2)
        let spinnerPath = makeBezierOval(cx: oval.midX, cy: oval.midY,
                                         rx: oval.width  / 2 + 10,
                                         ry: oval.height / 2 + 10)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        trackLayer.path    = innerPath.cgPath
        progressLayer.path = innerPath.cgPath
        spinnerLayer.path  = spinnerPath.cgPath
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

    func setProgress(_ progress: CGFloat, animated: Bool = false) {
        let p = max(0, min(1, progress))
        guard p != currentProgress || animated else { return }  // redundant set'ten kaçın
        if animated {
            let anim = CABasicAnimation(keyPath: "strokeEnd")
            anim.fromValue = currentProgress
            anim.toValue   = p
            anim.duration  = 0.3
            anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            progressLayer.add(anim, forKey: "progressAnimation")
        }
        CATransaction.begin()
        CATransaction.setDisableActions(!animated)
        progressLayer.strokeEnd = p
        CATransaction.commit()
        currentProgress = p
    }

    func resetProgress() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        progressLayer.strokeEnd = 0
        CATransaction.commit()
        currentProgress = 0
    }

    // MARK: - Animation

    func startDashAnimation() {
        // trackLayer gizli olduğundan animasyon yalnızca spinnerLayer'a eklenir
        trackLayer.removeAnimation(forKey: "dashAnimation")

        let spinnerDash = CABasicAnimation(keyPath: "lineDashPhase")
        spinnerDash.fromValue     = 0
        spinnerDash.toValue       = NSNumber(value: -32)   // negatif: saat yönünde döner
        spinnerDash.duration      = 0.8
        spinnerDash.repeatCount   = .infinity
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
        // trackLayer her zaman gizli; yalnızca progress + spinner yönetilir
        progressLayer.isHidden = !visible
        spinnerLayer.isHidden  = !visible
    }

    // MARK: - Colors

    func updateRingColors(track: UIColor, progress: UIColor) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.4)
        // trackLayer gizli olduğu için yalnızca progressLayer rengi güncellenir
        progressLayer.strokeColor = progress.cgColor
        CATransaction.commit()
    }

    // MARK: - Layout

    // bounds erişimi yalnızca burada; main thread garantili (H)
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
