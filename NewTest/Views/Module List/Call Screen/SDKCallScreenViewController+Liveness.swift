//
//  SDKCallScreenViewController+Liveness.swift
//

import UIKit
import ARKit

// MARK: - Liveness Lifecycle

extension SDKCallScreenViewController {

    /// Configures the liveness analyzer before the call begins.
    ///
    /// Call this when the call waiting screen appears, **before** WebRTC starts streaming.
    /// It only sets `config` and `listener` — ARKit is not started yet, so there is no
    /// camera conflict with `RTCCameraVideoCapturer`.
    ///
    /// ```swift
    /// // In viewDidLoad or just before showing the waiting screen:
    /// setupLiveness()
    /// ```
    func setupLiveness() {
        CallLivenessAnalyzer.shared.config   = LivenessConfig()
        CallLivenessAnalyzer.shared.listener = self
    }

    /// Switches the camera from WebRTC to ARKit and starts liveness analysis.
    ///
    /// Call this when the `startTransfer` socket event is received (i.e., the remote agent
    /// has joined and the call is active). The method:
    /// 1. Calls `switchToARKitCapture()` to stop `RTCCameraVideoCapturer`.
    /// 2. Assigns a `frameHandler` so ARKit frames are piped directly into WebRTC.
    /// 3. Starts `CallLivenessAnalyzer` on a background thread.
    ///
    /// > Important: Do **not** call this before `setupLiveness()`.
    ///
    /// ```swift
    /// // On startTransfer socket event:
    /// startLiveness()
    /// ```
    func startLiveness() {
        manager.webRTCClient.switchToARKitCapture()
        CallLivenessAnalyzer.shared.frameHandler = { [weak self] pixelBuffer in
            self?.manager.webRTCClient.captureCurrentFrame(sampleBuffer: pixelBuffer)
        }
        DispatchQueue.global(qos: .userInitiated).async {
            CallLivenessAnalyzer.shared.start()
        }
    }

    /// Stops liveness analysis and releases the ARKit session.
    ///
    /// Call this when the call ends or the screen is about to be dismissed.
    /// It is safe to call even if `startLiveness()` was never called.
    ///
    /// ```swift
    /// // In viewWillDisappear or on call-end event:
    /// stopLiveness()
    /// ```
    func stopLiveness() {
        CallLivenessAnalyzer.shared.stop()
    }
}

// MARK: - LivenessListener

extension SDKCallScreenViewController: LivenessListener {

    /// Fired each time a distinct face action is detected (subject to cooldown).
    ///
    /// - Parameters:
    ///   - action: The detected action (e.g. `.speaking`, `.headTurnRight`).
    ///   - metrics: Raw blendshape and head-pose values for the current frame.
    ///   - holdDuration: Seconds this action has been continuously active above its threshold.
    ///   - detectedCount: Total distinct actions detected so far in this session.
    ///   - requiredCount: Distinct actions needed to satisfy the liveness requirement.
    ///   - score: Current composite liveness score in the range 0–100.
    ///
    /// Use `detectedCount` / `requiredCount` to drive a progress indicator, and `score`
    /// to reflect overall confidence to the user or backend.
    ///
    /// > Note: Called on a **background thread** — dispatch to `DispatchQueue.main` for UI work.
    func onActionDetected(
        action: LivenessActionType,
        metrics: FaceMetrics,
        holdDuration: TimeInterval,
        detectedCount: Int,
        requiredCount: Int,
        score: Int
    ) {
        // Update your UI or notify the backend here.
        // Example: progressView.setProgress(Float(detectedCount) / Float(requiredCount))
    }

    /// Fired whenever the face enters or leaves the camera frame.
    ///
    /// - Parameter isPresent: `true` when the face is detected again after being lost;
    ///   `false` when the face disappears beyond the tolerance window
    ///   (`LivenessConfig.faceLostToleranceSeconds`).
    ///
    /// Use this to show / hide a "please keep your face visible" warning.
    ///
    /// > Note: Called on a **background thread** — dispatch to `DispatchQueue.main` for UI work.
    func onFacePresenceChanged(isPresent: Bool) {
        // Show or hide a face-visibility warning here.
        // Example: warningLabel.isHidden = isPresent
    }

    /// Fired once per second while continuous face tracking is active.
    ///
    /// - Parameters:
    ///   - elapsedSeconds: Seconds of uninterrupted tracking accumulated so far.
    ///   - requiredSeconds: Total seconds required to satisfy the time-based condition
    ///     (`LivenessConfig.requiredContinuousMs`).
    ///
    /// Use this to animate a countdown or progress ring.
    ///
    /// > Note: Called on a **background thread** — dispatch to `DispatchQueue.main` for UI work.
    func onContinuousTrackingProgress(elapsedSeconds: Int, requiredSeconds: Int) {
        // Animate a progress indicator here.
        // Example: timerLabel.text = "\(elapsedSeconds) / \(requiredSeconds)s"
    }

    /// Fired **exactly once** when both verification conditions are met:
    /// sufficient distinct actions **and** sufficient continuous tracking time.
    ///
    /// - Parameter score: Final liveness score — always `100` at this point.
    ///
    /// This is the integration hook for notifying the backend that liveness passed,
    /// or for advancing the UI flow (e.g. enabling a "Continue" button).
    ///
    /// > Note: Called on a **background thread** — dispatch to `DispatchQueue.main` for UI work.
    func onLivenessVerified(score: Int) {
        // Liveness check passed — notify backend or advance the UI flow here.
        // Example: delegate?.livenessDidPass(score: score)
    }
}
