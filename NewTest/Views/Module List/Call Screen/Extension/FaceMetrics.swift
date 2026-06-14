
import Foundation

// MARK: - FaceMetrics

/// Face metrics extracted from a single ARKit frame.
///
/// All blendshape values are in the range [0.0, 1.0] (0 = absent, 1 = maximum).
/// Head angles are in degrees (° [-180, 180]).
internal struct FaceMetrics {

    // MARK: Attention

    /// Is the face turned toward the camera? (|yaw| < threshold AND |pitch| < threshold)
    var isLookingAtScreen: Bool = false

    // MARK: Eye State

    /// Left eye blink value (higher = more closed).
    var eyeBlinkLeft: Float  = 0
    /// Right eye blink value (higher = more closed).
    var eyeBlinkRight: Float = 0
    /// Left eye wide open.
    var eyeWideLeft: Float   = 0
    /// Right eye wide open.
    var eyeWideRight: Float  = 0
    /// Left eye squint.
    var squintLeft: Float    = 0
    /// Right eye squint.
    var squintRight: Float   = 0

    // MARK: Mouth / Speech

    /// Jaw openness — primary metric for speech detection.
    var jawOpen: Float       = 0
    /// Lip pucker.
    var mouthPucker: Float   = 0
    /// Mouth stretch.
    var mouthStretch: Float  = 0
    /// Left smile.
    var smileLeft: Float     = 0
    /// Right smile.
    var smileRight: Float    = 0

    // MARK: Brow Movement

    /// Inner brow raise.
    var browInnerUp: Float      = 0
    /// Left outer brow raise.
    var browOuterUpLeft: Float  = 0
    /// Right outer brow raise.
    var browOuterUpRight: Float = 0
    /// Left brow lower.
    var browDownLeft: Float     = 0
    /// Right brow lower.
    var browDownRight: Float    = 0

    // MARK: Other

    /// Cheek puff.
    var cheekPuff: Float  = 0
    /// Jaw slide left.
    var jawLeft: Float    = 0
    /// Jaw slide right.
    var jawRight: Float   = 0

    // MARK: Head Pose

    /// Yaw: turn right (+) / left (−) (degrees).
    var yawDegrees: Float   = 0
    /// Pitch: tilt up (+) / down (−) (degrees).
    var pitchDegrees: Float = 0
    /// Roll: tilt right (+) / left (−) (degrees).
    var rollDegrees: Float  = 0
}
