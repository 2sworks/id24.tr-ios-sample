//
//  VideoCameraController.swift
//  NewTest
//
//  AVCaptureMovieFileOutput tabanli, on kamera ile 5 saniyelik
//  video kayit yapan controller. SelfieView'daki SelfieCameraController
//  ile ayni pattern'i izler.
//

import AVFoundation
import SwiftUI

@MainActor
final class VideoCameraController: NSObject, ObservableObject {

    let session = AVCaptureSession()
    private let movieOutput = AVCaptureMovieFileOutput()

    @Published var isRecording = false
    /// Session yapılandırıldı ve kayıta hazır
    @Published var isReady = false

    private var recordingCompletion: ((URL?) -> Void)?

    // MARK: - Session Lifecycle

    func start() {
        isReady = false
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await self.configureSession()
            await MainActor.run {
                self.session.startRunning()
                self.isReady = true
            }
        }
    }

    func stop() {
        isReady = false
        if movieOutput.isRecording {
            movieOutput.stopRecording()
        }
        Task.detached { [weak self] in
            self?.session.stopRunning()
            // Session durduktan sonra audio hardware'i playback için serbest bırak
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try? AVAudioSession.sharedInstance().setActive(true)
        }
    }

    // MARK: - Recording

    func startRecording(maxDuration: TimeInterval, completion: @escaping (URL?) -> Void) {
        guard !isRecording else { return }
        recordingCompletion = completion
        movieOutput.maxRecordedDuration = CMTime(seconds: maxDuration, preferredTimescale: 600)
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        movieOutput.startRecording(to: tempURL, recordingDelegate: self)
        isRecording = true
    }

    // MARK: - Private

    private func configureSession() async {
        session.beginConfiguration()
        session.sessionPreset = .high
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }

        guard
            let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
            session.canAddInput(videoInput)
        else {
            session.commitConfiguration()
            return
        }
        session.addInput(videoInput)

        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }

        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
        }

        if let connection = movieOutput.connection(with: .video) {
            if #available(iOS 17.0, *) {
                if connection.isVideoRotationAngleSupported(90) {
                    connection.videoRotationAngle = 90
                }
            } else {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
            }
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = true
            }
        }

        session.commitConfiguration()
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension VideoCameraController: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        // AVErrorMaximumDurationReached: 5 sn limitine ulaşıldı — gerçek bir hata değil
        let isMaxDuration = (error as? AVError)?.code == .maximumDurationReached
        let succeeded = error == nil || isMaxDuration

        Task { @MainActor in
            self.isRecording = false
            self.recordingCompletion?(succeeded ? outputFileURL : nil)
            self.recordingCompletion = nil
        }
    }
}
