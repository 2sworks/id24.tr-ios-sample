
import Foundation

// MARK: - FaceMetrics

/// Tek bir ARKit frame'inden çıkarılan yüz metrikleri.
///
/// Tüm blendshape değerleri [0.0, 1.0] arasındadır (0 = yok, 1 = maksimum).
/// Kafa açıları derece cinsindendir (° [-180, 180]).
internal struct FaceMetrics {

    // MARK: Ekrana Dikkat

    /// Yüz kameraya dönük mü? (|yaw| < eşik AND |pitch| < eşik)
    var isLookingAtScreen: Bool = false

    // MARK: Göz Durumu

    /// Sol göz kırpma değeri (yüksek = kapalı)
    var eyeBlinkLeft: Float  = 0
    /// Sağ göz kırpma değeri (yüksek = kapalı)
    var eyeBlinkRight: Float = 0
    /// Sol göz açılması
    var eyeWideLeft: Float   = 0
    /// Sağ göz açılması
    var eyeWideRight: Float  = 0
    /// Sol göz kısma
    var squintLeft: Float    = 0
    /// Sağ göz kısma
    var squintRight: Float   = 0

    // MARK: Ağız / Konuşma

    /// Çene açıklığı — konuşma tespiti için birincil metrik
    var jawOpen: Float       = 0
    /// Dudak büzme
    var mouthPucker: Float   = 0
    /// Ağız genişletme
    var mouthStretch: Float  = 0
    /// Sol gülümseme
    var smileLeft: Float     = 0
    /// Sağ gülümseme
    var smileRight: Float    = 0

    // MARK: Kaş Hareketleri

    /// İç kaş kaldırma
    var browInnerUp: Float      = 0
    /// Sol dış kaş kaldırma
    var browOuterUpLeft: Float  = 0
    /// Sağ dış kaş kaldırma
    var browOuterUpRight: Float = 0
    /// Sol kaş indirme
    var browDownLeft: Float     = 0
    /// Sağ kaş indirme
    var browDownRight: Float    = 0

    // MARK: Diğer

    /// Yanak şişirme
    var cheekPuff: Float  = 0
    /// Çene sola kayma
    var jawLeft: Float    = 0
    /// Çene sağa kayma
    var jawRight: Float   = 0

    // MARK: Kafa Hareketi (Head Pose)

    /// Yaw: sağa (+) / sola (−) bakma (derece)
    var yawDegrees: Float   = 0
    /// Pitch: yukarı (+) / aşağı (−) bakma (derece)
    var pitchDegrees: Float = 0
    /// Roll: sağa (+) / sola (−) eğme (derece)
    var rollDegrees: Float  = 0
}
