//
//  VideoRecorderView.swift
//  NewTest
//
//  --- DURUM MAKİNESİ ---
//
//  idle      : videoURL == nil && !camera.isRecording
//              -> Ortada tek kayıt butonu (mavi, aktif)
//
//  recording : camera.isRecording == true
//              -> Ortada tek kayıt butonu (gri, deaktif)
//
//  recorded  : videoURL != nil
//              -> Arka plan: inline video player (auto-play)
//                 Sol: Yeniden çek (↺)
//                 Orta: Onayla / Sunucuya gönder (✓)
//                 Sağ: Play/Pause toggle (▶/⏸)
//
//  --- AKIŞ ---
//  1. Kayıt başlar  → auto-stop 5 sn → videoSelected → isCameraActive=false → auto-play
//  2. Onay (✓)      → uploadVideo(appState:) → advanceToNextModule()
//  3. Yeniden çek   → player temizle → deleteVideo() → isCameraActive=true → camera.start()
//

import SwiftUI
import AVFoundation

struct VideoRecorderView: View {

    @StateObject private var viewModel = VideoRecorderViewModel()
    @StateObject private var camera = VideoCameraController()
    @EnvironmentObject private var appState: AppStateViewModel

    @State private var isCameraActive = true
    @State private var player: AVPlayer? = nil
    @State private var isVideoPlaying = false

    var body: some View {
        ZStack {
            backgroundLayer
            VStack(spacing: 0) {
                headerBar
                Spacer()
                VStack(spacing: 20) {
                    bottomInfoArea
                    actionButtons
                }
                .padding(.bottom, 48)
            }
            if viewModel.isLoading {
                loadingOverlay
            }
        }
        .ignoresSafeArea()
        .onAppear { camera.start() }
        .onDisappear {
            camera.stop()
            player?.pause()
            player = nil
        }
        // videoURL set edilince player oluştur; AVCaptureSession'ın audio hardware'i
        // bırakmasını beklemek için kısa gecikme sonrası play() çağır
        .onChange(of: viewModel.videoURL) { url in
            guard let url else {
                player?.pause()
                player = nil
                isVideoPlaying = false
                return
            }
            let p = AVPlayer(url: url)
            player = p
            isVideoPlaying = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                guard p === player else { return }
                p.play()
            }
        }
        // Video sonuna gelince başa sar ve tekrar oynat (kullanıcı durdurana kadar döngü)
        .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { _ in
            player?.seek(to: .zero)
            player?.play()
        }
    }
}

// MARK: - Subviews

private extension VideoRecorderView {

    var backgroundLayer: some View {
        Group {
            if isCameraActive {
                SelfieCameraPreview(session: camera.session)
                    .ignoresSafeArea()
            } else if let p = player {
                VideoPlayerView(player: p)
                    .ignoresSafeArea()
            } else {
                Color(white: 0.12)
                    .ignoresSafeArea()
            }
        }
    }

    var headerBar: some View {
        ZStack {
            HStack {
                VideoCircleIconButton(systemName: "chevron.left") {
                    appState.skipCurrentModule()
                }
                Spacer()
                VideoCircleIconButton(systemName: "questionmark") {}
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
        VStack(spacing: 8) {
            Text("Video")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Group {
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(Color(red: 1, green: 0.45, blue: 0.45))
                } else if camera.isRecording {
                    Text("Kaydediliyor...")
                        .foregroundColor(.white.opacity(0.9))
                } else if viewModel.videoURL != nil {
                    Text("Video kaydedildi. Devam etmek için onaylayın\nveya tekrar çekin.")
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                } else {
                    Text("En fazla \(Int(viewModel.videoTimeLimit)) saniye uzunluğunda olacak\nbir video çekerek devam edin.")
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
            .font(.system(size: 14, weight: .regular))
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: viewModel.errorMessage)
            .animation(.easeInOut(duration: 0.3), value: camera.isRecording)
            .animation(.easeInOut(duration: 0.3), value: viewModel.videoURL != nil)
        }
        .padding(.horizontal, 32)
    }

    var actionButtons: some View {
        Group {
            if viewModel.videoURL != nil {
                // Recorded: yeniden çek | onayla | play/pause
                HStack(spacing: 24) {
                    VideoCircleActionButton(
                        icon: AnyView(
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                        ),
                        background: Color.white.opacity(0.2),
                        size: 64
                    ) {
                        player?.pause()
                        player = nil
                        isVideoPlaying = false
                        viewModel.deleteVideo()
                        isCameraActive = true
                        camera.start()
                    }

                    VideoCircleActionButton(
                        icon: AnyView(
                            Image(systemName: "checkmark")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                        ),
                        background: Color(red: 0.24, green: 0.52, blue: 0.98),
                        size: 72
                    ) {
                        viewModel.uploadVideo(appState: appState)
                    }
                    .disabled(viewModel.isLoading)

                    VideoCircleActionButton(
                        icon: AnyView(
                            Image(systemName: isVideoPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(.white)
                                .offset(x: isVideoPlaying ? 0 : 2)
                        ),
                        background: Color.white.opacity(0.2),
                        size: 64
                    ) {
                        if isVideoPlaying {
                            player?.pause()
                            isVideoPlaying = false
                        } else {
                            // Her zaman baştan oynat
                            player?.seek(to: .zero)
                            player?.play()
                            isVideoPlaying = true
                        }
                    }
                }
            } else {
                // Idle veya recording: ortada tek kayıt butonu
                let buttonActive = camera.isReady && !camera.isRecording
                VideoCircleActionButton(
                    icon: AnyView(
                        Image(systemName: "video.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(buttonActive ? .white : Color.white.opacity(0.4))
                    ),
                    background: buttonActive
                        ? Color(red: 0.24, green: 0.52, blue: 0.98)
                        : Color.white.opacity(0.15),
                    size: 72
                ) {
                    camera.startRecording(maxDuration: viewModel.videoTimeLimit) { url in
                        guard let url else { return }
                        viewModel.videoSelected(url: url)
                        isCameraActive = false
                        camera.stop()
                    }
                }
                .disabled(!buttonActive)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.videoURL != nil)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: camera.isRecording)
        .animation(.easeInOut(duration: 0.2), value: isVideoPlaying)
    }

    var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.4)
        }
    }
}

// MARK: - VideoPlayerView

private struct VideoPlayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.playerLayer.videoGravity = .resizeAspectFill
        view.playerLayer.player = player
        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        if uiView.playerLayer.player !== player {
            uiView.playerLayer.player = player
        }
    }

    class PlayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}

// MARK: - VideoCircleIconButton

private struct VideoCircleIconButton: View {
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

// MARK: - VideoCircleActionButton

private struct VideoCircleActionButton: View {
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

// MARK: - Previews

#Preview("Kamera Aktif") {
    VideoRecorderView()
        .environmentObject(AppStateViewModel())
}
