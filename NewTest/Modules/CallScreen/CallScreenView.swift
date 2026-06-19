//
//  CallScreenView.swift
//  NewTest
//

import SwiftUI

struct CallScreenView: View {

    @StateObject private var viewModel: CallScreenViewModel
    @EnvironmentObject private var appState: AppStateViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var showEndCallAlert = false
    @State private var nfcPulseActive = false

    @MainActor
    init() {
        _viewModel = StateObject(wrappedValue: CallScreenViewModel())
    }

    #if DEBUG
    @MainActor
    init(viewModel: CallScreenViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    #endif

    var body: some View {
        ZStack {
            Group {
                switch viewModel.callState {
                case .waiting:
                    waitingScreen
                case .ringing:
                    ringingScreen
                case .connected:
                    connectedScreen
                case .smsVerification:
                    connectedScreen
                        .overlay(smsOverlay)
                case .nfcReading:
                    connectedScreen
                        .overlay(nfcOverlay)
                case .ended:
                    endedScreen
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.callState)

            errorToast
        }
        .onAppear {
            appState.manager.socketMessageListener = viewModel
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            appState.manager.socketMessageListener = appState
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: viewModel.socketThankYouStatus) { status in
            guard let status else { return }
            appState.pendingThankYouStatus = status
            appState.advanceToNextModule()
        }
        .alert("Görüşmeyi bitir", isPresented: $showEndCallAlert) {
            Button("İptal", role: .cancel) {}
            Button("Bitir", role: .destructive) {
                viewModel.terminateCall(appState: appState)
            }
        } message: {
            Text("Görüşmeyi kapatırsanız tüm işlemler iptal edilecektir.")
        }
    }

    // MARK: - Waiting

    private var waitingScreen: some View {
        ZStack {
            IDColor.adaptiveBackground(for: colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                waitingIllustration
                    .padding(.bottom, IDSpacing.xl)

                VStack(spacing: IDSpacing.sm) {
                    Text("Lütfen bekleyin...")
                        .font(IDFont.displayMedium(.semibold))
                        .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))

                    Text("Görüntülü görüşme yapmak üzere müşteri hizmetlerine bağlanmak üzeresiniz.")
                        .font(IDFont.bodyRegular(.regular))
                        .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, IDSpacing.lg)
                .padding(.bottom, IDSpacing.xl)

                queueInfoCard
                    .padding(.horizontal, IDSpacing.lg)

                Spacer()
            }
        }
        .overlay { loadingOverlay }
    }

    private var waitingIllustration: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.941, green: 0.961, blue: 1.0))
                .overlay(
                    Circle()
                        .stroke(Color(red: 0.898, green: 0.910, blue: 0.922).opacity(0.5), lineWidth: 1)
                )
                .frame(width: 144, height: 144)

            Image(.icIdentifyLogoText)
                .resizable()
                .scaledToFit()
                .frame(width: 96)
        }
    }

    private var queueInfoCard: some View {
        Group {
            if !viewModel.queuePosition.isEmpty && viewModel.queuePosition != "0" {
                VStack(spacing: 4) {
                    Text("Bekleyenler arasında \(viewModel.queuePosition). sıradasınız")
                        .font(IDFont.bodySmall(.semibold))
                        .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                        .multilineTextAlignment(.center)
                    Text("tahmini bekleme süreniz \(viewModel.estimatedWait) dakika")
                        .font(IDFont.caption(.regular))
                        .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                }
                .frame(maxWidth: .infinity)
                .padding(IDSpacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: IDRadius.lg)
                        .fill(IDColor.inkBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: IDRadius.lg)
                                .stroke(IDColor.inkBorder, lineWidth: 1)
                        )
                )
            } else {
                Text(.callScreenWaitRepresentative)
                    .font(IDFont.bodySmall(.medium))
                    .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(IDSpacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: IDRadius.lg)
                            .fill(IDColor.inkBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: IDRadius.lg)
                                    .stroke(IDColor.inkBorder, lineWidth: 1)
                            )
                    )
            }
        }
    }

    // MARK: - Ringing

    private var ringingScreen: some View {
        ZStack {
            IDColor.adaptiveBackground(for: colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Image(.incomingCall)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 144, height: 144)
                    .padding(.bottom, IDSpacing.xl)

                VStack(spacing: IDSpacing.sm) {
                    Text("Müşteri temsilcimiz arıyor...")
                        .font(IDFont.displayMedium(.semibold))
                        .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))

                    Text("Video görüşmeyi başlatmak için lütfen cevaplayınız.")
                        .font(IDFont.bodyRegular(.regular))
                        .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, IDSpacing.lg)
                }
                .padding(.bottom, IDSpacing.xxl)

                Spacer()

                Button(action: { viewModel.acceptCall() }) {
                    Image(.incomingCallButton)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 78, height: 78)
                }
                .padding(.bottom, 60)
            }
        }
    }


    // MARK: - Connected

    private var connectedScreen: some View {
        ZStack(alignment: .top) {
            VideoFeedRepresentable(videoView: viewModel.remoteVideoView)
                .ignoresSafeArea()

            LinearGradient(
                colors: [Color.black.opacity(0.55), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 180)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    localCameraView
                }

                Spacer()

                bottomCallPanel
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var localCameraView: some View {
        VideoFeedRepresentable(videoView: viewModel.localVideoView)
            .frame(width: 126, height: 155)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white, lineWidth: 2))
            .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 6)
            .padding(.top, IDSpacing.xl)
            .padding(.trailing, IDSpacing.lg)
    }

    private var bottomCallPanel: some View {
        VStack(spacing: IDSpacing.lg) {
            Capsule()
                .fill(Color.white.opacity(0.4))
                .frame(width: 44, height: 5)

            Text("Görüşme devam ediyor")
                .font(IDFont.bodySmall(.medium))
                .foregroundColor(.white.opacity(0.85))

            Button(action: {
                if viewModel.endCallEnabled {
                    showEndCallAlert = true
                }
            }) {
                ZStack {
                    Circle()
                        .fill(IDColor.error)
                        .frame(width: 72, height: 72)
                        .opacity(viewModel.endCallEnabled ? 1 : 0.35)
                    Image(systemName: "xmark")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .disabled(!viewModel.endCallEnabled)
            .animation(.easeInOut(duration: 0.2), value: viewModel.endCallEnabled)

            Spacer().frame(height: IDSpacing.lg)
        }
        .padding(.top, IDSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                Color(.sRGB, red: 0.22, green: 0.22, blue: 0.22, opacity: 0.35)
                if #available(iOS 15.0, *) {
                    Rectangle().fill(.ultraThinMaterial)
                }
            }
        )
        .clipShape(TopRoundedShape(radius: IDRadius.lg))
    }

    // MARK: - NFC Overlay

    private var nfcOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: IDSpacing.lg) {
                nfcCardIllustration

                VStack(spacing: IDSpacing.sm) {
                    Text("NFC Tarama")
                        .font(IDFont.displayMedium(.semibold))
                        .foregroundColor(.white)

                    Text("NFC Okutma işlemi için lütfen kimlik kartınızı telefonunuzun önüne tutunuz.")
                        .font(IDFont.bodyRegular(.regular))
                        .foregroundColor(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                }

                if !viewModel.nfcStatusMessage.isEmpty {
                    Text(viewModel.nfcStatusMessage)
                        .font(IDFont.bodySmall(.medium))
                        .foregroundColor(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(IDSpacing.xl)
        }
        .onAppear { nfcPulseActive = true }
        .onDisappear { nfcPulseActive = false }
    }

    private var nfcCardIllustration: some View {
        ZStack {
            Image(.nfcBack)
                .resizable()
                .scaledToFill()
                .frame(width: 200, height: 300)
                .scaleEffect(nfcPulseActive ? 1.08 : 0.96)
                .opacity(nfcPulseActive ? 0.55 : 0.95)
                .animation(
                    .easeInOut(duration: 1.4).repeatForever(autoreverses: true),
                    value: nfcPulseActive
                )

            Image(.nfcFront)
                .resizable()
                .scaledToFill()
                .frame(width: 200, height: 300)
                .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 10)
                .padding(.trailing, IDSpacing.lg)
        }
        .frame(width: 300, height: 300)
    }

    // MARK: - SMS Overlay

    private var smsOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: IDSpacing.xl) {
                VStack(spacing: IDSpacing.sm) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 32))
                        .foregroundColor(IDColor.primary)

                    Text("SMS Kodunu Girin")
                        .font(IDFont.displayMedium(.semibold))
                        .foregroundColor(.white)

                    Text("Telefonunuza gelen 6 haneli kodu girin")
                        .font(IDFont.bodyRegular(.regular))
                        .foregroundColor(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                }

                TextField("· · · · · ·", text: $viewModel.smsCode)
                    .keyboardType(.numberPad)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                    .frame(maxWidth: 200)
                    .padding(.vertical, IDSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: IDRadius.md)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: IDRadius.md)
                                    .stroke(IDColor.primary.opacity(0.5), lineWidth: 2)
                            )
                    )

                Button(action: { viewModel.verifySMS(appState: appState) }) {
                    Text("Doğrula")
                        .font(IDFont.bodyRegular(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            viewModel.isSMSCodeValid
                                ? IDColor.primary
                                : IDColor.primary.opacity(0.35)
                        )
                        .clipShape(Capsule())
                }
                .disabled(!viewModel.isSMSCodeValid)
                .animation(.easeInOut(duration: 0.2), value: viewModel.isSMSCodeValid)
            }
            .padding(IDSpacing.xl)
            .background(
                RoundedRectangle(cornerRadius: IDRadius.card)
                    .fill(IDColor.darkBgSecondary)
            )
            .padding(.horizontal, IDSpacing.lg)
        }
    }

    // MARK: - Ended

    private var endedScreen: some View {
        ZStack {
            IDColor.adaptiveBackground(for: colorScheme).ignoresSafeArea()

            VStack(spacing: IDSpacing.xl) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(IDColor.successBright)

                VStack(spacing: IDSpacing.sm) {
                    Text("Görüşme Tamamlandı")
                        .font(IDFont.displayMedium(.semibold))
                        .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                    Text("İşleminiz tamamlanıyor...")
                        .font(IDFont.bodyRegular(.regular))
                        .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                }

                ProgressView().tint(IDColor.primary)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                appState.advanceToNextModule()
            }
        }
    }

    // MARK: - Error Toast

    @ViewBuilder
    private var errorToast: some View {
        if let msg = viewModel.errorMessage {
            VStack {
                Spacer()
                Text(msg)
                    .font(IDFont.bodySmall(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, IDSpacing.lg)
                    .padding(.vertical, IDSpacing.md)
                    .background(IDColor.error.opacity(0.9))
                    .clipShape(Capsule())
                    .padding(.bottom, IDSpacing.xl)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.4), value: viewModel.errorMessage)
        }
    }

    // MARK: - Loading Overlay

    @ViewBuilder
    private var loadingOverlay: some View {
        if viewModel.isLoading {
            Color.black.opacity(0.35).ignoresSafeArea()
            ProgressView().tint(.white).scaleEffect(1.3)
        }
    }
}

// MARK: - TopRoundedShape

private struct TopRoundedShape: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: radius))
        path.addArc(
            center: CGPoint(x: radius, y: radius),
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.width - radius, y: 0))
        path.addArc(
            center: CGPoint(x: rect.width - radius, y: radius),
            radius: radius,
            startAngle: .degrees(270),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Bekleme") {
    CallScreenView(viewModel: CallScreenViewModel(previewState: .waiting))
        .environmentObject(AppStateViewModel())
}

#Preview("Bekleme — Sıra Var") {
    CallScreenView(viewModel: CallScreenViewModel(previewState: .waiting, queuePosition: "1", estimatedWait: "5"))
        .environmentObject(AppStateViewModel())
}

#Preview("Çağrı Geliyor") {
    CallScreenView(viewModel: CallScreenViewModel(previewState: .ringing))
        .environmentObject(AppStateViewModel())
}

#Preview("Görüşme Devam Ediyor") {
    CallScreenView(viewModel: CallScreenViewModel(previewState: .connected))
        .environmentObject(AppStateViewModel())
}

#Preview("NFC Okuma") {
    CallScreenView(viewModel: CallScreenViewModel(previewState: .nfcReading))
        .environmentObject(AppStateViewModel())
}

#Preview("Görüşme Tamamlandı") {
    CallScreenView(viewModel: CallScreenViewModel(previewState: .ended))
        .environmentObject(AppStateViewModel())
}
#endif
