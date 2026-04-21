//
//  SDKCallScreenViewController+Liveness.swift
//

import UIKit
import ARKit

// MARK: - Liveness Yaşam Döngüsü

extension SDKCallScreenViewController {

    /// Görüşme ekranı açılırken liveness analizini yapılandırır.
    /// `viewWillAppear` içinden çağrılmalı.
    func setupLiveness() {
        CallLivenessAnalyzer.shared.config   = LivenessConfig()
        CallLivenessAnalyzer.shared.listener = self
    }

    /// Görüşme başladığında (startTransfer socket eventi) ARSession'ı başlatır.
    func startLiveness() {
        CallLivenessAnalyzer.shared.start()
    }

    /// Görüşme bittiğinde veya ekran kapandığında analizi durdurur.
    func stopLiveness() {
        CallLivenessAnalyzer.shared.stop()
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
        print("[Liveness] Aksiyon: \(action) | \(detectedCount)/\(requiredCount) | skor: \(score) | hold: \(String(format: "%.2f", holdDuration))sn")
    }

    func onFacePresenceChanged(isPresent: Bool) {
        print("[Liveness] Yüz varlığı değişti: \(isPresent)")
    }

    func onContinuousTrackingProgress(elapsedSeconds: Int, requiredSeconds: Int) {
        print("[Liveness] Kesintisiz takip: \(elapsedSeconds)/\(requiredSeconds)sn")
    }

    func onLivenessVerified(score: Int) {
        print("[Liveness] ✓ Doğrulama tamamlandı | skor: \(score)")
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            // Liveness doğrulandı — isteğe bağlı UI güncellemesi buraya
        }
    }
}
