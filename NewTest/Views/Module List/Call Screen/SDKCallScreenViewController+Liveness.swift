//
//  SDKCallScreenViewController+Liveness.swift
//

import UIKit
import ARKit

// MARK: - Associated Object Keys

private var livenessStatusViewKey: UInt8 = 0

// MARK: - Liveness Yaşam Döngüsü

extension SDKCallScreenViewController {

    private var livenessStatusView: LivenessStatusView? {
        get { objc_getAssociatedObject(self, &livenessStatusViewKey) as? LivenessStatusView }
        set { objc_setAssociatedObject(self, &livenessStatusViewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    /// Görüşme bekleme ekranı açılırken çağrılır. Sadece config ve listener ayarlar;
    /// ARKit session başlatılmaz — WebRTC kamerayı önce tek başına kullanır.
    func setupLiveness() {
        CallLivenessAnalyzer.shared.config   = LivenessConfig()
        CallLivenessAnalyzer.shared.listener = self
    }

    /// Görüşme başladığında (startTransfer socket eventi) çağrılır.
    /// RTCCameraVideoCapturer durdurulur, ARKit tek kamera sahibi olur.
    /// ARKit frame'leri doğrudan WebRTC'ye iletilir — çakışma ve freeze olmaz.
    func startLiveness() {
        showLivenessStatusView()
        manager.webRTCClient.switchToARKitCapture()
        CallLivenessAnalyzer.shared.frameHandler = { [weak self] pixelBuffer in
            self?.manager.webRTCClient.captureCurrentFrame(sampleBuffer: pixelBuffer)
        }
        DispatchQueue.global(qos: .userInitiated).async {
            CallLivenessAnalyzer.shared.start()
        }
    }

    /// Görüşme bittiğinde veya ekran kapandığında analizi durdurur.
    func stopLiveness() {
        CallLivenessAnalyzer.shared.stop()
        hideLivenessStatusView()
    }

    // MARK: - Status View

    private func showLivenessStatusView() {
        DispatchQueue.main.async { [weak self] in
            guard let self, livenessStatusView == nil else { return }

            let statusView = LivenessStatusView()
            statusView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(statusView)

            NSLayoutConstraint.activate([
                statusView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
                statusView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
                statusView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -58),
                statusView.heightAnchor.constraint(equalToConstant: 230)
            ])

            statusView.alpha = 0
            UIView.animate(withDuration: 0.3) { statusView.alpha = 1 }
            livenessStatusView = statusView
        }
    }

    private func hideLivenessStatusView() {
        DispatchQueue.main.async { [weak self] in
            guard let self, let sv = livenessStatusView else { return }
            UIView.animate(withDuration: 0.3, animations: {
                sv.alpha = 0
            }) { _ in
                sv.removeFromSuperview()
                self.livenessStatusView = nil
            }
        }
    }
}

// MARK: - LivenessListener

extension SDKCallScreenViewController: LivenessListener {

    func onActionDetected(
        action: LivenessActionType,
        metrics: FaceMetrics,
        holdDuration: TimeInterval,
        detectedCount: Int,
        requiredCount: Int,
        score: Int
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.livenessStatusView?.markActionDetected(action)
            self?.livenessStatusView?.flashAction(action)
            self?.livenessStatusView?.updateScore(score)
        }
        print("[Liveness] Aksiyon: \(action) | \(detectedCount)/\(requiredCount) | skor: \(score) | hold: \(String(format: "%.2f", holdDuration))sn")
    }

    func onFacePresenceChanged(isPresent: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.livenessStatusView?.updateFacePresence(isPresent)
        }
        print("[Liveness] Yüz varlığı değişti: \(isPresent)")
    }

    func onContinuousTrackingProgress(elapsedSeconds: Int, requiredSeconds: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.livenessStatusView?.updateTracking(elapsed: elapsedSeconds, required: requiredSeconds)
        }
        print("[Liveness] Kesintisiz takip: \(elapsedSeconds)/\(requiredSeconds)sn")
    }

    func onLivenessVerified(score: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.livenessStatusView?.updateScore(score)
        }
        print("[Liveness] ✓ Doğrulama tamamlandı | skor: \(score)")
    }
}
