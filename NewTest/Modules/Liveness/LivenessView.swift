//
//  LivenessView.swift
//  NewTest
//
//  Canlılık testi ekranı.
//
//  --- KULLANIM REHBERİ ---
//
//  ADIM:
//    viewModel.stepInstruction       -> kullanıcıya gösterilen talimat
//    viewModel.currentStep           -> mevcut LivenessTestStep
//    viewModel.allStepsCompleted     -> tüm adımlar bitti
//
//  BAYRAKLAR (ARSCNViewDelegate için):
//    viewModel.allowBlink            -> kırpma adımı aktif mi
//    viewModel.allowSmile            -> gülme adımı aktif mi
//    viewModel.allowLeft / .allowRight -> baş dönme adımları
//
//  İŞLEMLER:
//    viewModel.uploadFrame(image:appState:)      -> yakalanan frame'i gönder
//    viewModel.uploadVideo(videoData:appState:)  -> video yükle + sonrakine geç
//    viewModel.resetTest()                       -> testi sıfırla
//
//  VİDEO:
//    viewModel.isRecordingEnabled    -> video kayıt aktif mi
//    viewModel.maxVideoSize          -> max boyut (byte)
//
//  DURUM:
//    viewModel.isLoading             -> yükleme devam ediyor
//    viewModel.errorMessage          -> hata
//

import SwiftUI
import ARKit
import IdentifySDK

// MARK: - LivenessView

struct LivenessView: View {

    @StateObject private var viewModel = LivenessViewModel()
    @EnvironmentObject private var appState: AppStateViewModel

    var body: some View {
        ZStack {
            LivenessCameraView(viewModel: viewModel, appState: appState)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                headerBar
                Spacer()
                bottomInfoArea
            }
            if viewModel.isLoading {
                loadingOverlay
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .onChange(of: viewModel.allStepsCompleted) { completed in
            if completed {
                viewModel.uploadVideo(videoData: Data(), appState: appState)
            }
        }
    }
}

// MARK: - Subviews

private extension LivenessView {

    var headerBar: some View {
        ZStack {
            HStack {
                CircleIconButton(systemName: "chevron.left") {
                    appState.skipCurrentModule()
                }
                Spacer()
                CircleIconButton(systemName: "questionmark") {}
            }
            Text("identify")
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .italic()
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 16)
    }

    var bottomInfoArea: some View {
        HStack(spacing: 12) {
            if let iconName = stepIconName {
                Image(systemName: iconName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
            Group {
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(Color(red: 1, green: 0.45, blue: 0.45))
                } else {
                    Text(viewModel.stepInstruction)
                        .foregroundColor(.white)
                }
            }
            .font(.system(size: 20, weight: .semibold))
            .multilineTextAlignment(.center)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: viewModel.stepInstruction)
            .animation(.easeInOut(duration: 0.3), value: viewModel.errorMessage)
        }
        .frame(maxWidth: .infinity, minHeight: 151)
        .background(
            Color.black.opacity(0.5)
                .clipShape(TopRoundedRectangle(radius: 30))
        )
    }

    var stepIconName: String? {
        switch viewModel.currentStep {
        case .turnLeft:  return "arrow.left"
        case .turnRight: return "arrow.right"
        case .blinkEyes: return "eye"
        case .smile:     return "face.smiling"
        default:         return nil
        }
    }

    var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.4)
        }
    }
}

// MARK: - CircleIconButton

private struct CircleIconButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: systemName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - LivenessCameraView

struct LivenessCameraView: UIViewRepresentable {

    @ObservedObject var viewModel: LivenessViewModel
    let appState: AppStateViewModel

    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView()
        sceneView.delegate = context.coordinator
        sceneView.automaticallyUpdatesLighting = true
        context.coordinator.sceneView = sceneView
        if ARFaceTrackingConfiguration.isSupported {
            context.coordinator.startSession()
        }
        return sceneView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        context.coordinator.syncFlags(from: viewModel)
    }

    static func dismantleUIView(_ uiView: ARSCNView, coordinator: Coordinator) {
        coordinator.stopSession()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel, appState: appState)
    }

    // MARK: Coordinator

    final class Coordinator: NSObject, ARSCNViewDelegate {

        let viewModel: LivenessViewModel
        let appState: AppStateViewModel
        weak var sceneView: ARSCNView?

        private let configuration = ARFaceTrackingConfiguration()
        private let waitSecs: TimeInterval = 2.0

        // Local copies of ViewModel flags — synced on main thread, read on ARKit thread
        var localStep: LivenessTestStep? = nil
        var localAllowBlink = false
        var localAllowSmile = false
        var localAllowLeft  = false
        var localAllowRight = false
        var isCapturing = false

        init(viewModel: LivenessViewModel, appState: AppStateViewModel) {
            self.viewModel = viewModel
            self.appState = appState
        }

        @MainActor
        func syncFlags(from vm: LivenessViewModel) {
            localStep       = vm.currentStep
            localAllowBlink = vm.allowBlink
            localAllowSmile = vm.allowSmile
            localAllowLeft  = vm.allowLeft
            localAllowRight = vm.allowRight
        }

        func startSession() {
            sceneView?.session.run(configuration)
        }

        func stopSession() {
            sceneView?.session.pause()
        }

        // MARK: ARSCNViewDelegate

        func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
            guard let device = sceneView?.device,
                  let faceMesh = ARSCNFaceGeometry(device: device) else { return nil }
            let node = SCNNode(geometry: faceMesh)
            node.geometry?.firstMaterial?.fillMode = .lines
            node.geometry?.firstMaterial?.transparency = 0
            return node
        }

        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            guard let faceAnchor = anchor as? ARFaceAnchor,
                  let faceGeometry = node.geometry as? ARSCNFaceGeometry else { return }
            faceGeometry.update(from: faceAnchor.geometry)
            detectExpression(anchor: faceAnchor)
        }

        // MARK: Expression Detection

        private func detectExpression(anchor: ARFaceAnchor) {
            guard !isCapturing, let step = localStep else { return }

            let smileLeft  = anchor.blendShapes[.mouthSmileLeft]?.decimalValue ?? 0
            let smileRight = anchor.blendShapes[.mouthSmileRight]?.decimalValue ?? 0
            let jawLeft    = anchor.blendShapes[.jawLeft]?.decimalValue ?? 0
            let jawRight   = anchor.blendShapes[.jawRight]?.decimalValue ?? 0
            let eyeBlinkL  = anchor.blendShapes[.eyeBlinkLeft]?.decimalValue ?? 0
            let eyeBlinkR  = anchor.blendShapes[.eyeBlinkRight]?.decimalValue ?? 0

            let triggered: Bool
            switch step {
            case .turnLeft  where localAllowLeft:
                triggered = abs(jawLeft) > 0.15
            case .turnRight where localAllowRight:
                triggered = abs(jawRight) > 0.15
            case .blinkEyes where localAllowBlink:
                triggered = abs(eyeBlinkL) > 0.35 && abs(eyeBlinkR) > 0.35
                          && abs(jawLeft) < 0.03 && abs(jawRight) < 0.03
            case .smile     where localAllowSmile:
                triggered = smileLeft + smileRight > 1.2
                          && abs(jawLeft) < 0.03 && abs(jawRight) < 0.03
            default:
                triggered = false
            }

            if triggered {
                captureAndUpload(step: step)
            }
        }

        private func captureAndUpload(step: LivenessTestStep) {
            guard !isCapturing, let sceneView else { return }
            isCapturing = true
            localAllowLeft  = false
            localAllowRight = false
            localAllowBlink = false
            localAllowSmile = false

            stopSession()
            let image = sceneView.snapshot()
            let appState = self.appState

            Task { @MainActor in
                self.viewModel.uploadFrame(image: image, appState: appState)
                try? await Task.sleep(nanoseconds: UInt64(self.waitSecs * 1_000_000_000))
                self.isCapturing = false
                if !self.viewModel.allStepsCompleted {
                    self.startSession()
                }
            }
        }
    }
}

// MARK: - TopRoundedRectangle

private struct TopRoundedRectangle: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + radius),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Previews

#Preview {
    LivenessView()
        .environmentObject(AppStateViewModel())
}
