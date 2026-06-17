//
//  SelfieCameraView.swift
//  NewTest
//

import SwiftUI
import AVFoundation
import UIKit

// MARK: - SelfieCameraView

struct SelfieCameraView: View {
    let onCapture: (UIImage) -> Void
    let onDismiss: () -> Void

    @StateObject private var camera = SelfieCameraController()
    @State private var flash = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            SelfieCameraPreview(session: camera.session)
                .ignoresSafeArea()

            VStack {
                Spacer()
                HStack(spacing: 48) {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 52, height: 52)
                            .background(Color.white.opacity(0.18))
                            .clipShape(Circle())
                    }

                    Button {
                        camera.capturePhoto { image in
                            guard let image else { return }
                            onCapture(image)
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 76, height: 76)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 62, height: 62)
                        }
                    }

                    Button {
                        camera.toggleCamera()
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 52, height: 52)
                            .background(Color.white.opacity(0.18))
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 52)
            }
        }
        .onAppear { camera.start() }
        .onDisappear { camera.stop() }
    }
}

// MARK: - SelfieCameraPreview

struct SelfieCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

// MARK: - SelfieCameraController

@MainActor
final class SelfieCameraController: NSObject, ObservableObject {

    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var currentPosition: AVCaptureDevice.Position = .front
    private var captureCompletion: ((UIImage?) -> Void)?

    func start() {
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await self.configureSession(position: .front)
            await MainActor.run { self.session.startRunning() }
        }
    }

    func stop() {
        session.stopRunning()
    }

    func toggleCamera() {
        let next: AVCaptureDevice.Position = currentPosition == .front ? .back : .front
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await self.configureSession(position: next)
        }
    }

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        captureCompletion = completion
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    private func configureSession(position: AVCaptureDevice.Position) async {
        session.beginConfiguration()
        session.inputs.forEach { session.removeInput($0) }

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            session.commitConfiguration()
            return
        }

        session.addInput(input)

        if !session.outputs.contains(photoOutput), session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }

        if let connection = photoOutput.connection(with: .video) {
            if connection.isVideoMirroringSupported && position == .front {
                connection.isVideoMirrored = true
            }
            if #available(iOS 17.0, *) {
                if connection.isVideoRotationAngleSupported(90) {
                    connection.videoRotationAngle = 90
                }
            } else {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
            }
        }

        currentPosition = position
        session.commitConfiguration()

        if !session.isRunning {
            session.startRunning()
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension SelfieCameraController: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            Task { @MainActor in self.captureCompletion?(nil) }
            return
        }
        Task { @MainActor in
            self.captureCompletion?(image)
            self.captureCompletion = nil
        }
    }
}
