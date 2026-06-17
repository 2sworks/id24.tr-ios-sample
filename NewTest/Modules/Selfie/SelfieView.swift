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

    @StateObject private var viewModel = SelfieViewModel()
    @StateObject private var camera = SelfieCameraController()
    @EnvironmentObject private var appState: AppStateViewModel

    @State private var isCameraActive = true
    @State private var showSuccessCheckmark = false

    var body: some View {
        ZStack {
            backgroundLayer
            VStack(spacing: 0) {
                headerBar
                cameraFrameOverlay
                bottomInfoArea
                Spacer()
                actionButtons
                    .padding(.bottom, 48)
            }
            if viewModel.isLoading {
                loadingOverlay
            }
        }
        .ignoresSafeArea()
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
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .overlay(Color.black.opacity(0.25))
            } else {
                Color(white: 0.12)
                    .ignoresSafeArea()
            }
        }
    }

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
        HStack(spacing: 24) {
            // Tekrar dene — sadece fotoğraf çekildiyse görünür
            if viewModel.selfieImage != nil {
                CircleActionButton(
                    icon: AnyView(
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                    ),
                    background: Color.white.opacity(0.2),
                    size: 64
                ) {
                    viewModel.reset()
                    showSuccessCheckmark = false
                    isCameraActive = true
                }
            }

            if viewModel.canContinue {
                CircleActionButton(
                    icon: AnyView(
                        Image(systemName: "checkmark")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    ),
                    background: Color(red: 0.24, green: 0.52, blue: 0.98),
                    size: 72
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
                    background: Color(red: 0.24, green: 0.52, blue: 0.98),
                    size: 72
                ) {
                    camera.capturePhoto { image in
                        guard let image else { return }
                        isCameraActive = false
                        viewModel.processSelfie(image: image, appState: appState)
                    }
                }
            }
        }
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
    private let lineWidth: CGFloat = 3

    var body: some View {
        Canvas { context, _ in
            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            let color = GraphicsContext.Shading.color(.white)
            let r: CGFloat = 10

            func corner(_ origin: CGPoint, dx: CGFloat, dy: CGFloat) {
                var path = Path()
                path.move(to: CGPoint(x: origin.x + dx * cornerLength, y: origin.y))
                path.addLine(to: CGPoint(x: origin.x + dx * r, y: origin.y))
                path.addQuadCurve(
                    to: CGPoint(x: origin.x, y: origin.y + dy * r),
                    control: CGPoint(x: origin.x, y: origin.y)
                )
                path.addLine(to: CGPoint(x: origin.x, y: origin.y + dy * cornerLength))
                context.stroke(path, with: color, lineWidth: lineWidth)
            }

            corner(CGPoint(x: rect.minX, y: rect.minY), dx: 1, dy: 1)
            corner(CGPoint(x: rect.maxX, y: rect.minY), dx: -1, dy: 1)
            corner(CGPoint(x: rect.minX, y: rect.maxY), dx: 1, dy: -1)
            corner(CGPoint(x: rect.maxX, y: rect.maxY), dx: -1, dy: -1)
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
