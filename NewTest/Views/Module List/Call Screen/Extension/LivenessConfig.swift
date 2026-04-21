
import Foundation

// MARK: - LivenessConfig

/// [CallLivenessAnalyzer] yapılandırma parametreleri.
///
/// Eşikler "doğal konuşma" davranışına göre ayarlanmıştır:
/// kişiden bir şey yapması istenmez, normal video görüşme davranışı yeterlidir.
internal struct LivenessConfig {

    // MARK: Doğrulama Koşulları

    /// Canlılık doğrulaması için gereken farklı aksiyon sayısı
    var requiredActionCount: Int = 3
    /// Kesintisiz yüz takibi için gereken süre (ms)
    var requiredContinuousMs: TimeInterval = 8.0

    // MARK: Zamanlama

    /// İki frame analizi arasındaki minimum süre (saniye)
    var processIntervalSeconds: TimeInterval = 0.5
    /// Aynı aksiyonun tekrar tetiklenmesi için bekleme süresi (saniye)
    var actionCooldownSeconds: TimeInterval = 3.0
    /// Geçici yüz kaybında kesintisiz sayacı sıfırlamadan bekleme (saniye)
    var faceLostToleranceSeconds: TimeInterval = 1.0

    // MARK: Ekrana Bakma

    /// "Ekrana bakıyor" sayılmak için max yaw açısı (derece). ±15° içinde → kişi kameraya bakıyor.
    var lookingAtScreenYawDeg: Float = 15.0
    /// "Ekrana bakıyor" sayılmak için max pitch açısı (derece).
    var lookingAtScreenPitchDeg: Float = 15.0

    // MARK: Göz Durumu

    /// Göz "açık" sayılmak için max blink değeri.
    /// eyeBlinkLeft/Right < eyeOpenMaxBlink → göz açık.
    var eyeOpenMaxBlink: Float = 0.25
    /// Doğal göz kırpma için min blink değeri (kısa anlık kapanma).
    var naturalBlinkMinThreshold: Float = 0.55
    /// Göz kısma (squint) eşiği
    var squintThreshold: Float = 0.45

    // MARK: Konuşma

    /// Konuşma tespiti için min jawOpen değeri.
    /// Düşük eşik: tam ağız açma gerekmez, sadece hareket yeterli.
    var speakingJawThreshold: Float = 0.06

    // MARK: Baş Hareketleri

    var headTurnYawDeg: Float  = 18.0
    var headNodPitchDeg: Float = 15.0
    var headTiltRollDeg: Float = 20.0

    // MARK: Kaş Hareketleri

    /// browInnerUp veya browOuterUp eşiği
    var browRaiseThreshold: Float  = 0.35
    /// browDownLeft + browDownRight eşiği
    var browFurrowThreshold: Float = 0.38
}
