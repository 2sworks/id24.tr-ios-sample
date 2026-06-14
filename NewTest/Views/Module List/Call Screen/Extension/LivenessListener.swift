
import Foundation

// MARK: - LivenessActionType

/// Detectable face action types.
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

/// Event listener for [CallLivenessAnalyzer].
///
/// All callbacks are delivered on a **background thread**.
/// Dispatch to `DispatchQueue.main.async` for any UI updates.
internal protocol LivenessListener: AnyObject {

    /// Called when a face action is detected.
    ///
    /// - Parameters:
    ///   - action: The detected action type.
    ///   - metrics: All blendshape and head pose values for that frame.
    ///   - holdDuration: How long this action has continuously exceeded its threshold (seconds).
    ///   - detectedCount: Number of distinct actions detected so far.
    ///   - requiredCount: Number of actions required to pass verification.
    ///   - score: Current liveness score (0–100).
    func onActionDetected(
        action: LivenessActionType,
        metrics: FaceMetrics,
        holdDuration: TimeInterval,
        detectedCount: Int,
        requiredCount: Int,
        score: Int
    )

    /// Called when face presence changes.
    ///
    /// - Parameter isPresent: `true` → face detected again, `false` → face lost.
    func onFacePresenceChanged(isPresent: Bool)

    /// Called each second as continuous face tracking progresses.
    ///
    /// - Parameters:
    ///   - elapsedSeconds: Seconds of uninterrupted tracking so far.
    ///   - requiredSeconds: Total seconds required for verification.
    func onContinuousTrackingProgress(elapsedSeconds: Int, requiredSeconds: Int)

    /// Called **exactly once** when all verification conditions are met.
    ///
    /// - Parameter score: Final score (100).
    func onLivenessVerified(score: Int)
}
