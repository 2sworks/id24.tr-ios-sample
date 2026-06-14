
import ARKit
import simd
import IdentifySDK

// MARK: - CallLivenessAnalyzer

/// Performs background face analysis with ARKit during a WebRTC call.
///
/// ## Verification conditions (both must be satisfied)
/// 1. At least `config.requiredActionCount` **distinct** actions detected.
/// 2. Face tracked continuously for `config.requiredContinuousMs` seconds.
///
/// ## Usage
/// ```swift
/// // Before the call starts:
/// CallLivenessAnalyzer.shared.config   = LivenessConfig()
/// CallLivenessAnalyzer.shared.listener = self
/// CallLivenessAnalyzer.shared.start()
///
/// // When the call ends:
/// CallLivenessAnalyzer.shared.stop()
/// ```
///
/// All callbacks are delivered on a background thread.
internal final class CallLivenessAnalyzer: NSObject {

    // MARK: Shared

    static let shared = CallLivenessAnalyzer()

    // MARK: Configuration & Listener

    var config: LivenessConfig = LivenessConfig()
    weak var listener: LivenessListener?

    /// Bridge that forwards each ARKit frame to WebRTC. Assigned on `startLiveness()`.
    var frameHandler: ((CVPixelBuffer) -> Void)?

    // MARK: Running State

    private(set) var isRunning: Bool = false

    // MARK: Internal State

    private let session   = ARSession()
    private let lock      = NSLock()
    private let sendQueue = DispatchQueue(label: "com.liveness.send", qos: .background)

    private var isSessionActive: Bool             = false
    private var lastProcessTime: TimeInterval      = 0
    private var lastFrameForwardTime: TimeInterval = 0
    private let frameForwardInterval: TimeInterval = 1.0 / 24.0
    private var detectedActions                    = Set<LivenessActionType>()
    private var lastActionTimeMap                  = [LivenessActionType: TimeInterval]()
    private var actionActiveStartTime              = [LivenessActionType: TimeInterval]()
    private var lastRawBlendShapes: [ARFaceAnchor.BlendShapeLocation: NSNumber] = [:]
    private var livenessReportTimer: Timer?
    private var lastSentTime: TimeInterval         = 0
    private let sendCooldown: TimeInterval         = 1.0

    private var continuousStartTime: TimeInterval  = 0
    private var faceLostStartTime: TimeInterval    = 0
    private var consecutiveMisses: Int             = 0
    private var isFacePresent: Bool                = false
    private var lastReportedSec: Int               = -1
    private var isVerified: Bool                   = false

    /// Number of consecutive frames without a face before "face lost" is declared.
    private let missToleranceFrames = 3

    // MARK: Init

    private override init() {
        super.init()
        session.delegate = self
    }

    // MARK: Lifecycle

    /// Preloads the ARKit model in the background and immediately releases the camera.
    /// Call this on the call waiting screen so the model is ready without conflicting with WebRTC.
    func prewarm() {
        guard ARFaceTrackingConfiguration.isSupported, !isSessionActive else { return }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = false
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self else { return }
            isSessionActive = true
            session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            Thread.sleep(forTimeInterval: 0.2)
            session.pause()
            isSessionActive = false
            print("[CallLivenessAnalyzer] Prewarm complete")
        }
    }

    /// Starts the ARKit session. Subsequent calls are silently ignored.
    func startSession() {
        guard ARFaceTrackingConfiguration.isSupported, !isSessionActive else { return }
        isSessionActive = true
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = false
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            print("[CallLivenessAnalyzer] ARKit session started")
        }
    }

    /// Begins data collection and server reporting.
    /// If the session is already running, `run()` is not called again — no freeze.
    func start() {
        guard ARFaceTrackingConfiguration.isSupported else {
            print("[CallLivenessAnalyzer] ARFaceTracking is not supported on this device")
            return
        }
        resetState()
        isRunning = true
        startSession()
        livenessReportTimer?.invalidate()
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.sendQueue.async { self?.sendLivenessReportIfNeeded() }
        }
        RunLoop.main.add(timer, forMode: .common)
        livenessReportTimer = timer
        print("[CallLivenessAnalyzer] Liveness analysis started | config=\(config)")
    }

    /// Stops the timer and pauses the session.
    func stop() {
        isRunning = false
        isSessionActive = false
        frameHandler = nil
        livenessReportTimer?.invalidate()
        livenessReportTimer = nil
        session.pause()
        print("[CallLivenessAnalyzer] Liveness stopped | score=\(computeScore()) actions=\(detectedActions)")
    }

    /// Releases all resources. Call `start()` to reuse.
    func release() {
        stop()
        listener = nil
        resetState()
        print("[CallLivenessAnalyzer] Released")
    }

    // MARK: Score

    /// Current liveness score (0–100).
    ///
    /// = (detected / required actions) × 50  +  (elapsed s / required s) × 50
    func computeScore() -> Int {
        let cfg = config
        let actionScore = min(Float(detectedActions.count) / Float(cfg.requiredActionCount), 1.0) * 50.0
        let elapsed     = continuousStartTime > 0 ? Date().timeIntervalSince1970 - continuousStartTime : 0.0
        let contScore   = min(Float(elapsed) / Float(cfg.requiredContinuousMs), 1.0) * 50.0
        return Int(actionScore + contScore)
    }

    func getDetectedActions() -> Set<LivenessActionType> {
        return detectedActions
    }

    // MARK: Face Presence Tracking

    private func handleFacePresence(faceFound: Bool, now: TimeInterval) {
        let cfg = config

        if faceFound {
            let wasMissing = consecutiveMisses > 0
            consecutiveMisses = 0

            if wasMissing && faceLostStartTime > 0 {
                let lostDuration = now - faceLostStartTime
                faceLostStartTime = 0
                if lostDuration > cfg.faceLostToleranceSeconds {
                    continuousStartTime = now
                    lastReportedSec     = -1
                    print("[CallLivenessAnalyzer] Long loss (\(lostDuration)s) → tracking reset")
                }
            }

            if continuousStartTime == 0 { continuousStartTime = now }

            if !isFacePresent {
                isFacePresent = true
                listener?.onFacePresenceChanged(isPresent: true)
            }

            let elapsedSec = Int(now - continuousStartTime)
            if elapsedSec != lastReportedSec {
                lastReportedSec = elapsedSec
                listener?.onContinuousTrackingProgress(
                    elapsedSeconds: elapsedSec,
                    requiredSeconds: Int(cfg.requiredContinuousMs)
                )
            }

        } else {
            consecutiveMisses += 1
            if consecutiveMisses == 1 { faceLostStartTime = now }

            if consecutiveMisses >= missToleranceFrames && isFacePresent {
                isFacePresent = false
                listener?.onFacePresenceChanged(isPresent: false)
            }
        }
    }

    // MARK: Blendshape Action Detection

    private func detectBlendshapeActions(metrics: FaceMetrics, now: TimeInterval) -> Bool {
        let cfg = config

        let eyesOpen = metrics.eyeBlinkLeft  < cfg.eyeOpenMaxBlink &&
                       metrics.eyeBlinkRight < cfg.eyeOpenMaxBlink

        let naturalBlink = (metrics.eyeBlinkLeft  > cfg.naturalBlinkMinThreshold ||
                            metrics.eyeBlinkRight > cfg.naturalBlinkMinThreshold) && !eyesOpen

        let speaking   = metrics.jawOpen > cfg.speakingJawThreshold

        let squinting  = metrics.squintLeft  > cfg.squintThreshold &&
                         metrics.squintRight > cfg.squintThreshold

        let browRaise  = metrics.browInnerUp > cfg.browRaiseThreshold ||
                         (metrics.browOuterUpLeft  > cfg.browRaiseThreshold &&
                          metrics.browOuterUpRight > cfg.browRaiseThreshold)

        let browFurrow = metrics.browDownLeft  > cfg.browFurrowThreshold &&
                         metrics.browDownRight > cfg.browFurrowThreshold

        return checkAction(.eyesOpen,     isActive: eyesOpen,     metrics: metrics, now: now)
            || checkAction(.naturalBlink, isActive: naturalBlink, metrics: metrics, now: now)
            || checkAction(.speaking,     isActive: speaking,     metrics: metrics, now: now)
            || checkAction(.squint,       isActive: squinting,    metrics: metrics, now: now)
            || checkAction(.browRaise,    isActive: browRaise,    metrics: metrics, now: now)
            || checkAction(.browFurrow,   isActive: browFurrow,   metrics: metrics, now: now)
    }

    // MARK: Head Pose Action Detection

    private func detectHeadPoseActions(metrics: FaceMetrics, now: TimeInterval) -> Bool {
        let cfg   = config
        let yaw   = metrics.yawDegrees
        let pitch = metrics.pitchDegrees
        let roll  = metrics.rollDegrees

        let lookingAtScreen = abs(yaw)   < cfg.lookingAtScreenYawDeg &&
                              abs(pitch) < cfg.lookingAtScreenPitchDeg

        return checkAction(.lookingAtScreen, isActive: lookingAtScreen,              metrics: metrics, now: now)
            || checkAction(.headTurnRight,   isActive: yaw   >  cfg.headTurnYawDeg,  metrics: metrics, now: now)
            || checkAction(.headTurnLeft,    isActive: yaw   < -cfg.headTurnYawDeg,  metrics: metrics, now: now)
            || checkAction(.headUp,          isActive: pitch >  cfg.headNodPitchDeg, metrics: metrics, now: now)
            || checkAction(.headDown,        isActive: pitch < -cfg.headNodPitchDeg, metrics: metrics, now: now)
            || checkAction(.headTilt,        isActive: abs(roll) > cfg.headTiltRollDeg, metrics: metrics, now: now)
    }

    // MARK: Action Check

    /// Tracks the active/inactive state of an action and its hold duration.
    @discardableResult
    private func checkAction(
        _ action: LivenessActionType,
        isActive: Bool,
        metrics: FaceMetrics,
        now: TimeInterval
    ) -> Bool {
        if !isActive {
            actionActiveStartTime.removeValue(forKey: action)
            return false
        }
        if actionActiveStartTime[action] == nil {
            actionActiveStartTime[action] = now
        }
        let holdDuration = now - (actionActiveStartTime[action] ?? now)
        return fire(action: action, metrics: metrics, holdDuration: holdDuration, now: now)
    }

    // MARK: Action Firing

    @discardableResult
    private func fire(
        action: LivenessActionType,
        metrics: FaceMetrics,
        holdDuration: TimeInterval,
        now: TimeInterval
    ) -> Bool {
        let lastTime = lastActionTimeMap[action] ?? 0
        guard now - lastTime >= config.actionCooldownSeconds else { return false }

        lastActionTimeMap[action] = now
        detectedActions.insert(action)

        let score         = computeScore()
        let detectedCount = detectedActions.count
        let requiredCount = config.requiredActionCount

        print("[CallLivenessAnalyzer] ↑ Action: \(action) | hold=\(String(format: "%.2f", holdDuration))s | \(detectedCount)/\(requiredCount) | score=\(score) yaw=\(Int(metrics.yawDegrees))° pitch=\(Int(metrics.pitchDegrees))°")

        listener?.onActionDetected(
            action: action,
            metrics: metrics,
            holdDuration: holdDuration,
            detectedCount: detectedCount,
            requiredCount: requiredCount,
            score: score
        )
        return true
    }

    // MARK: Verification

    private func checkVerification(now: TimeInterval) {
        let cfg          = config
        let enoughAction = detectedActions.count >= cfg.requiredActionCount
        let elapsed      = continuousStartTime > 0 ? now - continuousStartTime : 0.0
        let enoughTime   = elapsed >= cfg.requiredContinuousMs

        guard enoughAction && enoughTime else { return }
        isVerified = true
        print("[CallLivenessAnalyzer] ✓ Liveness verified! actions=\(detectedActions) duration=\(String(format: "%.1f", elapsed))s")
        listener?.onLivenessVerified(score: 100)
    }

    // MARK: FaceMetrics Construction

    private func buildFaceMetrics(
        blendShapes: [ARFaceAnchor.BlendShapeLocation: NSNumber],
        transform: simd_float4x4
    ) -> FaceMetrics {
        func blend(_ key: ARFaceAnchor.BlendShapeLocation) -> Float {
            return blendShapes[key]?.floatValue ?? 0
        }

        let (yaw, pitch, roll) = headPoseFromTransform(transform)
        let cfg = config

        return FaceMetrics(
            isLookingAtScreen: abs(yaw)   < cfg.lookingAtScreenYawDeg &&
                               abs(pitch) < cfg.lookingAtScreenPitchDeg,

            eyeBlinkLeft:     blend(.eyeBlinkLeft),
            eyeBlinkRight:    blend(.eyeBlinkRight),
            eyeWideLeft:      blend(.eyeWideLeft),
            eyeWideRight:     blend(.eyeWideRight),
            squintLeft:       blend(.eyeSquintLeft),
            squintRight:      blend(.eyeSquintRight),

            jawOpen:          blend(.jawOpen),
            mouthPucker:      blend(.mouthPucker),
            mouthStretch:     blend(.mouthStretchLeft),
            smileLeft:        blend(.mouthSmileLeft),
            smileRight:       blend(.mouthSmileRight),

            browInnerUp:      blend(.browInnerUp),
            browOuterUpLeft:  blend(.browOuterUpLeft),
            browOuterUpRight: blend(.browOuterUpRight),
            browDownLeft:     blend(.browDownLeft),
            browDownRight:    blend(.browDownRight),

            cheekPuff:        blend(.cheekPuff),
            jawLeft:          blend(.jawLeft),
            jawRight:         blend(.jawRight),

            yawDegrees:       yaw,
            pitchDegrees:     pitch,
            rollDegrees:      roll
        )
    }

    // MARK: Head Pose

    /// Extracts yaw/pitch/roll angles (in degrees) from an ARFaceAnchor transform matrix.
    private func headPoseFromTransform(_ transform: simd_float4x4) -> (yaw: Float, pitch: Float, roll: Float) {
        let pitch = asin(-transform.columns.2.y)
        let yaw   = atan2(transform.columns.2.x, transform.columns.2.z)
        let roll  = atan2(transform.columns.0.y, transform.columns.1.y)

        let toDeg: Float = 180.0 / .pi
        return (yaw * toDeg, pitch * toDeg, roll * toDeg)
    }

    // MARK: Reset

    private func resetState() {
        detectedActions.removeAll()
        lastActionTimeMap.removeAll()
        actionActiveStartTime.removeAll()
        lastRawBlendShapes.removeAll()
        lastProcessTime     = 0
        continuousStartTime = 0
        faceLostStartTime   = 0
        consecutiveMisses   = 0
        isFacePresent       = false
        lastReportedSec     = -1
        isVerified          = false
    }

    private func sendLivenessReportIfNeeded() {
        guard isRunning else { return }

        let now = Date().timeIntervalSince1970
        guard now - lastSentTime >= sendCooldown else { return }
        lastSentTime = now

        lock.lock()
        let shapes  = lastRawBlendShapes
        let actions = detectedActions
        lock.unlock()

        guard !shapes.isEmpty else { return }
        var metricsDict: [String: Double] = [:]
        for (key, value) in shapes {
            let rounded = (Double(value.floatValue) * 100).rounded() / 100
            if rounded > 0.0 { metricsDict[key.rawValue] = rounded }
        }
        guard !metricsDict.isEmpty else { return }

        let actionStrings = actions.map { "\($0)" }
        IdentifyManager.shared.sendLivenessReport(metrics: metricsDict, detectedActions: actionStrings)
    }
}

// MARK: - ARSessionDelegate

extension CallLivenessAnalyzer: ARSessionDelegate {

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard isRunning else { return }

        let now = Date().timeIntervalSince1970

        guard now - lastProcessTime >= config.processIntervalSeconds else { return }
        lastProcessTime = now

        let faceAnchor = anchors.compactMap { $0 as? ARFaceAnchor }.first

        lock.lock()
        defer { lock.unlock() }

        handleFacePresence(faceFound: faceAnchor != nil, now: now)
        guard let anchor = faceAnchor else { return }

        lastRawBlendShapes = anchor.blendShapes
        let metrics = buildFaceMetrics(blendShapes: anchor.blendShapes, transform: anchor.transform)

        detectBlendshapeActions(metrics: metrics, now: now)
        detectHeadPoseActions(metrics: metrics, now: now)
        if !isVerified { checkVerification(now: now) }
    }

    /// Forwards each ARKit frame to WebRTC throttled to 24 fps.
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard isRunning, frameHandler != nil else { return }
        let now = frame.timestamp
        guard now - lastFrameForwardTime >= frameForwardInterval else { return }
        lastFrameForwardTime = now
        frameHandler?(frame.capturedImage)
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        print("[CallLivenessAnalyzer] ARSession error: \(error.localizedDescription)")
    }
}
