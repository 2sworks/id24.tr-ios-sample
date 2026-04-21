
import Foundation

// MARK: - LivenessActionType

/// Algılanabilen yüz aksiyon türleri
internal enum LivenessActionType {
    case eyesOpen
    case naturalBlink
    case speaking
    case squint
    case browRaise
    case browFurrow
    case lookingAtScreen
    case headTurnRight
    case headTurnLeft
    case headUp
    case headDown
    case headTilt
}

// MARK: - LivenessListener

/// [CallLivenessAnalyzer] olay dinleyicisi.
///
/// Tüm callback'ler **arka plan thread'inden** gelir.
/// UI güncellemesi gerekiyorsa `DispatchQueue.main.async` kullan.
internal protocol LivenessListener: AnyObject {

    /// Bir yüz aksiyonu algılandığında çağrılır.
    ///
    /// - Parameters:
    ///   - action: Algılanan aksiyon türü
    ///   - metrics: O frame'deki tüm blendshape + head pose değerleri
    ///   - holdDuration: Bu aksiyonun eşiği sürekli aşarak ekranda kaldığı süre (saniye)
    ///   - detectedCount: Şimdiye kadar algılanan farklı aksiyon sayısı
    ///   - requiredCount: Doğrulama için gereken aksiyon sayısı
    ///   - score: Anlık liveness skoru (0–100)
    func onActionDetected(
        action: LivenessActionType,
        metrics: FaceMetrics,
        holdDuration: TimeInterval,
        detectedCount: Int,
        requiredCount: Int,
        score: Int
    )

    /// Yüz varlığı değiştiğinde çağrılır.
    ///
    /// - Parameter isPresent: `true` → yüz tekrar algılandı, `false` → yüz kaybedildi
    func onFacePresenceChanged(isPresent: Bool)

    /// Kesintisiz yüz takibi ilerlemesi; saniye değişiminde tetiklenir.
    ///
    /// - Parameters:
    ///   - elapsedSeconds: Kesintisiz geçen süre (saniye)
    ///   - requiredSeconds: Doğrulama için gereken toplam süre
    func onContinuousTrackingProgress(elapsedSeconds: Int, requiredSeconds: Int)

    /// Tüm doğrulama koşulları sağlandığında **yalnızca bir kez** çağrılır.
    ///
    /// - Parameter score: Son skor (100)
    func onLivenessVerified(score: Int)
}
