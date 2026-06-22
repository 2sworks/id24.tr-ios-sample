//
//  SelfieView.swift
//  NewTest
//
//  Selfie ekrani - TASARIM KULLANICI TARAFINDAN DOLDURULACAK.
//
//  --- KULLANIM REHBERI ---
//
//  FOTOGRAF:
//    viewModel.selfieImage           -> cekilen UIImage
//
//  ISLEM:
//    viewModel.processSelfie(image:appState:)
//      -> yuz tespit + yukleme yapar, basarida canContinue=true
//
//  DURUM:
//    viewModel.faceDetected          -> yuz tespit edildi mi
//    viewModel.canContinue           -> devam butonu aktif mi
//    viewModel.resultText            -> sonuc metni
//    viewModel.isLoading             -> islem devam ediyor
//    viewModel.errorMessage          -> hata mesaji
//
//  DEVAM:
//    appState.advanceToNextModule()
//    appState.skipCurrentModule()
//

import SwiftUI

// MARK: - SelfieView

struct SelfieView: View {

    @StateObject private var viewModel: SelfieViewModel
    @StateObject private var camera = SelfieCameraController()
    @EnvironmentObject private var appState: AppStateViewModel

    @State private var isCameraActive = true
    @State private var showSuccessCheckmark = false

    @MainActor
    init() {
        _viewModel = StateObject(wrappedValue: SelfieViewModel())
    }

    #if DEBUG
    @MainActor
    init(previewModel: SelfieViewModel) {
        _viewModel = StateObject(wrappedValue: previewModel)
    }
    #endif

    var body: some View {
        ZStack {
            backgroundLayer
            VStack(spacing: 0) {
                SDKNavigationBar(
                    style: .overlay,
                    onBack: { appState.popBack() },
                    onHelp: {}
                )
                cameraFrameOverlay
                bottomInfoArea
                Spacer()
                actionButtons
                    .padding(.bottom, 32)
            }
            if viewModel.isLoading {
                loadingOverlay
            }
        }
        .onAppear { camera.start() }
        .onDisappear { camera.stop() }
        .onChange(of: viewModel.canContinue) { success in
            if success {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                    showSuccessCheckmark = true
                }
            }
        }
    }
}

// MARK: - Subviews

private extension SelfieView {

    var backgroundLayer: some View {
        Group {
            if isCameraActive {
                SelfieCameraPreview(session: camera.session)
                    .ignoresSafeArea()
            } else if let img = viewModel.selfieImage {
                GeometryReader { geo in
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.25))
            } else {
                Color(white: 0.12)
                    .ignoresSafeArea()
            }
        }
    }

    var cameraFrameOverlay: some View {
        GeometryReader { geo in
            let side = geo.size.width - 40
            ZStack {
                Color.clear
                    .frame(width: side, height: side * 1.15)
                DocumentFrame(width: side, height: side * 1.15)
            }
            .frame(width: geo.size.width, height: side * 1.15)
            .padding(.top, 8)
        }
        .frame(height: UIScreen.main.bounds.width * 1.05)
    }

    var bottomInfoArea: some View {
        VStack(spacing: 8) {
            Text("Selfie")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Group {
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(Color(red: 1, green: 0.45, blue: 0.45))
                } else if viewModel.canContinue {
                    Text("Yüzünüz fotoğrafı başarıyla çekildi teşekkürler,\nşimdi devam edebilirsiniz.")
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                } else {
                    Text("Lütfen yüzünüzü çerçeve içine alarak\nfotoğraf çekin.")
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
            .font(.system(size: 14, weight: .regular))
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: viewModel.errorMessage)
            .animation(.easeInOut(duration: 0.3), value: viewModel.canContinue)
        }
        .padding(.top, 20)
        .padding(.horizontal, 32)
    }

    var actionButtons: some View {
        ZStack {
            HStack {
                if viewModel.selfieImage != nil {
                    CircleActionButton(
                        icon: AnyView(
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                        ),
                        background: Color.white.opacity(0.2),
                        size: 56
                    ) {
                        viewModel.reset()
                        showSuccessCheckmark = false
                        isCameraActive = true
                    }
                }
            }
            .padding(.trailing, 170)

            Group {
                if viewModel.canContinue {
                    CircleActionButton(
                        icon: AnyView(
                            Image(systemName: "checkmark")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                        ),
                        background: IDColor.primary,
                        size: 80
                    ) {
                        appState.advanceToNextModule()
                    }
                    .scaleEffect(showSuccessCheckmark ? 1 : 0.5)
                    .opacity(showSuccessCheckmark ? 1 : 0)
                } else if isCameraActive {
                    CircleActionButton(
                        icon: AnyView(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                        ),
                        background: IDColor.primary,
                        size: 80
                    ) {
                        camera.capturePhoto { image in
                            guard let image else { return }
                            isCameraActive = false
                            viewModel.processSelfie(image: image, appState: appState)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.canContinue)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isCameraActive)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.selfieImage != nil)
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

// MARK: - CircleActionButton

private struct CircleActionButton: View {
    let icon: AnyView
    let background: Color
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(background)
                    .frame(width: size, height: size)
                icon
            }
        }
    }
}

// MARK: - DocumentFrame

private struct DocumentFrame: View {
    let width: CGFloat
    let height: CGFloat

    private let cornerLength: CGFloat = 28
    private let lineWidth: CGFloat = 7

    var body: some View {
        Canvas { context, _ in
            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            let color = GraphicsContext.Shading.color(.white)
            let r: CGFloat = 18

            func corner(_ origin: CGPoint, dx: CGFloat, dy: CGFloat) {
                var path = Path()
                path.move(to: CGPoint(x: origin.x + dx * cornerLength, y: origin.y))
                path.addLine(to: CGPoint(x: origin.x + dx * r, y: origin.y))
                path.addQuadCurve(
                    to: CGPoint(x: origin.x, y: origin.y + dy * r),
                    control: CGPoint(x: origin.x, y: origin.y)
                )
                path.addLine(to: CGPoint(x: origin.x, y: origin.y + dy * cornerLength))
                context.stroke(path, with: color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            }

            corner(CGPoint(x: rect.minX, y: rect.minY), dx: 1, dy: 1)
            corner(CGPoint(x: rect.maxX, y: rect.minY), dx: -1, dy: 1)
            corner(CGPoint(x: rect.minX, y: rect.maxY), dx: 1, dy: -1)
            corner(CGPoint(x: rect.maxX, y: rect.maxY), dx: -1, dy: -1)

            func edge(from start: CGPoint, to end: CGPoint) {
                var path = Path()
                path.move(to: start)
                path.addLine(to: end)
                context.stroke(path, with: color, lineWidth: 0.5)
            }

            edge(from: CGPoint(x: rect.minX + cornerLength, y: rect.minY),
                 to:   CGPoint(x: rect.maxX - cornerLength, y: rect.minY))
            edge(from: CGPoint(x: rect.minX + cornerLength, y: rect.maxY),
                 to:   CGPoint(x: rect.maxX - cornerLength, y: rect.maxY))
            edge(from: CGPoint(x: rect.minX, y: rect.minY + cornerLength),
                 to:   CGPoint(x: rect.minX, y: rect.maxY - cornerLength))
            edge(from: CGPoint(x: rect.maxX, y: rect.minY + cornerLength),
                 to:   CGPoint(x: rect.maxX, y: rect.maxY - cornerLength))
        }
        .frame(width: width, height: height)
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension SelfieView {
    init(previewModel: SelfieViewModel, cameraActive: Bool = false) {
        _viewModel = StateObject(wrappedValue: previewModel)
        _camera = StateObject(wrappedValue: SelfieCameraController())
        _isCameraActive = State(initialValue: cameraActive)
        _showSuccessCheckmark = State(initialValue: previewModel.canContinue)
    }
}
#endif

// MARK: - Previews

#if DEBUG
#Preview("Kamera Aktif") {
    SelfieView()
        .environmentObject(AppStateViewModel())
}

#Preview("Fotoğraf Çekildi") {
    SelfieView(previewModel: .makePreview(
        selfieImage: UIImage(systemName: "person.fill")
    ))
    .environmentObject(AppStateViewModel())
}

#Preview("Yükleniyor") {
    SelfieView(previewModel: .makePreview(
        selfieImage: UIImage(systemName: "person.fill"),
        isLoading: true
    ))
    .environmentObject(AppStateViewModel())
}

#Preview("Sunucu Hatası") {
    SelfieView(previewModel: .makePreview(
        selfieImage: UIImage(systemName: "person.fill"),
        errorMessage: "Karşılaştırma başarısız (1/3)"
    ))
    .environmentObject(AppStateViewModel())
}

#Preview("Başarılı") {
    SelfieView(previewModel: .makePreview(
        selfieImage: UIImage(systemName: "person.fill"),
        canContinue: true,
        faceDetected: true
    ))
    .environmentObject(AppStateViewModel())
}
#endif
