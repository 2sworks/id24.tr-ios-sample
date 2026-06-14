
import Foundation

// MARK: - LivenessConfig

/// Configuration parameters for [CallLivenessAnalyzer].
///
/// Thresholds are tuned for "natural conversation" behaviour:
/// no deliberate action is required from the user — normal video call behaviour is sufficient.
internal struct LivenessConfig {

    // MARK: Verification Requirements

    /// Number of distinct actions required to pass liveness verification.
    var requiredActionCount: Int = 3
    /// Duration of uninterrupted face tracking required (seconds).
    var requiredContinuousMs: TimeInterval = 8.0

    // MARK: Timing

    /// Minimum interval between two frame analyses (seconds).
    var processIntervalSeconds: TimeInterval = 1.0
    /// Cooldown before the same action can be fired again (seconds).
    var actionCooldownSeconds: TimeInterval = 3.0
    /// Grace period after face loss before resetting the continuous tracking counter (seconds).
    var faceLostToleranceSeconds: TimeInterval = 1.0

    // MARK: Looking at Screen

    /// Maximum yaw angle (degrees) for "looking at screen". ±15° → person is facing the camera.
    var lookingAtScreenYawDeg: Float = 15.0
    /// Maximum pitch angle (degrees) for "looking at screen".
    var lookingAtScreenPitchDeg: Float = 15.0

    // MARK: Eye State

    /// Maximum blink value for an eye to be considered "open".
    /// eyeBlinkLeft/Right < eyeOpenMaxBlink → eye is open.
    var eyeOpenMaxBlink: Float = 0.25
    /// Minimum blink value for a natural blink (brief closure).
    var naturalBlinkMinThreshold: Float = 0.55
    /// Squint detection threshold.
    var squintThreshold: Float = 0.45

    // MARK: Speaking

    /// Minimum jawOpen value for speech detection.
    /// Low threshold: a full mouth opening is not required — any jaw movement is sufficient.
    var speakingJawThreshold: Float = 0.06

    // MARK: Head Movement

    var headTurnYawDeg: Float  = 18.0
    var headNodPitchDeg: Float = 15.0
    var headTiltRollDeg: Float = 20.0

    // MARK: Brow Movement

    /// browInnerUp or browOuterUp threshold.
    var browRaiseThreshold: Float  = 0.35
    /// browDownLeft + browDownRight threshold.
    var browFurrowThreshold: Float = 0.38
}
