//
//  VideoRecorderView.swift
//  NewTest
//
//  --- DURUM MAKİNESİ ---
//
//  idle      : videoURL == nil && !camera.isRecording
//              -> Okuma testi kartı + kayıt butonu (mavi, aktif)
//
//  recording : camera.isRecording == true
//              -> Okuma testi kartı (kullanıcı cümleyi okur) + kayıt butonu (gri, deaktif)
//
//  recorded  : videoURL != nil
//              -> Arka plan: inline video player (auto-play)
//                 Transkripsiyon sonucu + doğrulama kutusu
//                 Sol: Yeniden çek (↺)
//                 Orta: Onayla / Sunucuya gönder (✓) — speechSuccess olmadan disable
//                 Sağ: Play/Pause toggle (▶/⏸)
//
//  --- AKIŞ ---
//  1. Kayıt başlar  → auto-stop 5 sn → videoSelected → isCameraActive=false → auto-play + transkripsiyon
//  2. Onay (✓)      → uploadVideo(appState:) → advanceToNextModule()
//  3. Yeniden çek   → player temizle → deleteVideo() → isCameraActive=true → camera.start()
//

import SwiftUI
import AVFoundation

struct VideoRecorderView: View {

    /// Preview veya dış kaynak için opsiyonel başlangıç metni.
    /// nil ise okuma testi devre dışı (normal akış).
    private let initialReadingText: String?

    init(readingText: String? = nil) {
        self.initialReadingText = readingText
    }

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
                Spacer()
                VStack(spacing: 12) {
                    if viewModel.readingText != nil && viewModel.videoURL == nil {
                        readingTestCard
                    }
                    bottomInfoArea
                    if viewModel.readingText != nil && viewModel.videoURL != nil {
                        recognizedTextBox
                    }
                    actionButtons
                }
                .padding(.bottom, 48)
            }
            if viewModel.isLoading {
                loadingOverlay
            }
        }
        .ignoresSafeArea()
        .overlay(alignment: .top) {
            SDKNavigationBar(
                style: .overlay,
                onBack: { appState.popBack() },
                onHelp: {}
            )
        }
        .onAppear {
            camera.start()
            if let text = initialReadingText {
                viewModel.updateReadingText(text)
            }
        }
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

    // MARK: - Reading Test Card

    var readingTestCard: some View {
        let readingGreen = Color(red: 0.18, green: 0.82, blue: 0.44)
        return VStack(spacing: 16) {
            // Başlık ve açıklama — kart dışında, ortalanmış
            VStack(spacing: 6) {
                Text("Okuma Testi")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Text("Lütfen aşağıdaki metni okurken bir video kaydedin.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            .frame(maxWidth: .infinity)

            // Cümle kartı — yeşil dashed border
            VStack(alignment: .leading, spacing: 8) {
                Text("Okumanız gereken cümle:")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.65))

                Text(viewModel.readingText ?? "")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(readingGreen)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(IDColor.successBright.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        readingGreen.opacity(0.75),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
            )
        }
        .padding(.horizontal, 24)
        .transition(.opacity)
    }

    // MARK: - Recognized Text Box

    @ViewBuilder
    var recognizedTextBox: some View {
        VStack(alignment: .leading, spacing: 8) {
            if viewModel.isTranscribing {
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.85)
                    Text("Ses doğrulanıyor...")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                }
            } else {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: viewModel.speechSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(viewModel.speechSuccess
                            ? Color(red: 0.3, green: 0.85, blue: 0.5)
                            : Color(red: 1, green: 0.45, blue: 0.45))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Söylediğiniz:")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.white.opacity(0.65))
                        Text(viewModel.recognizedText.isEmpty ? "—" : viewModel.recognizedText)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            viewModel.speechSuccess
                                ? Color(red: 0.3, green: 0.85, blue: 0.5).opacity(0.5)
                                : Color.white.opacity(0.15),
                            lineWidth: 1
                        )
                )
        )
        .padding(.horizontal, 24)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .animation(.easeInOut(duration: 0.3), value: viewModel.isTranscribing)
        .animation(.easeInOut(duration: 0.3), value: viewModel.speechSuccess)
    }

    // MARK: - Bottom Info Area

    var bottomInfoArea: some View {
        VStack(spacing: 8) {
            Group {
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(Color(red: 1, green: 0.45, blue: 0.45))
                        .multilineTextAlignment(.center)
                } else if camera.isRecording {
                    Text(viewModel.readingText != nil
                         ? "Kaydediliyor — cümleyi okuyun..."
                         : "Kaydediliyor...")
                        .foregroundColor(.white.opacity(0.9))
                } else if viewModel.videoURL != nil {
                    if viewModel.readingText != nil {
                        if viewModel.isTranscribing {
                            Text("Video kaydedildi. Ses doğrulanıyor...")
                                .foregroundColor(.white.opacity(0.85))
                        } else if viewModel.speechSuccess {
                            Text("Doğrulama başarılı. Devam etmek için onaylayın.")
                                .foregroundColor(Color(red: 0.3, green: 0.85, blue: 0.5))
                        } else {
                            Text("Cümleyi okurken yeniden çekin.")
                                .foregroundColor(.white.opacity(0.85))
                        }
                    } else {
                        Text("Video kaydedildi. Devam etmek için onaylayın\nveya tekrar çekin.")
                            .foregroundColor(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                    }
                } else {
                    Text(viewModel.readingText != nil
                         ? ""
                         : "En fazla \(Int(viewModel.videoTimeLimit)) saniye uzunluğunda olacak\nbir video çekerek devam edin.")
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
            .font(.system(size: 14, weight: .regular))
            .multilineTextAlignment(.center)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: viewModel.errorMessage)
            .animation(.easeInOut(duration: 0.3), value: camera.isRecording)
            .animation(.easeInOut(duration: 0.3), value: viewModel.videoURL != nil)
            .animation(.easeInOut(duration: 0.3), value: viewModel.speechSuccess)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Action Buttons

    var actionButtons: some View {
        Group {
            if viewModel.videoURL != nil {
                // Recorded: yeniden çek | onayla | play/pause
                let readingRequired = viewModel.readingText != nil
                let confirmActive = !viewModel.isLoading &&
                    (!readingRequired || (!viewModel.isTranscribing && viewModel.speechSuccess))
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
                                .foregroundColor(confirmActive ? .white : Color.white.opacity(0.4))
                        ),
                        background: confirmActive
                            ? Color(red: 0.24, green: 0.52, blue: 0.98)
                            : Color.white.opacity(0.15),
                        size: 72
                    ) {
                        viewModel.uploadVideo(appState: appState)
                    }
                    .disabled(!confirmActive)

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
        .animation(.easeInOut(duration: 0.2), value: viewModel.speechSuccess)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isTranscribing)
    }

    // MARK: - Loading Overlay

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

/// Okuma testi yok — sunucudan reading_text gelmediği durum (eski normal akış)
#Preview("Okuma Testi Yok") {
    VideoRecorderView()
        .environmentObject(AppStateViewModel())
}

/// Okuma testi aktif — sunucudan reading_text geldiği durum
#Preview("Okuma Testi Aktif") {
    VideoRecorderView(readingText: "İstanbul'da mutlu bir kış akşamı")
        .environmentObject(AppStateViewModel())
}
