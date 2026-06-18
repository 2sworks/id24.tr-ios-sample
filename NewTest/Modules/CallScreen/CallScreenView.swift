//
//  CallScreenView.swift
//  NewTest
//

import SwiftUI

struct CallScreenView: View {

    @StateObject private var viewModel = CallScreenViewModel()
    @EnvironmentObject private var appState: AppStateViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var showEndCallAlert = false
    @State private var pulseActive = false

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
                case .ended:
                    endedScreen
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.callState)

            errorToast
        }
        .onAppear {
            appState.manager.socketMessageListener = viewModel
            pulseActive = true
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            appState.manager.socketMessageListener = appState
            pulseActive = false
            UIApplication.shared.isIdleTimerDisabled = false
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
        ZStack(alignment: .top) {
            (colorScheme == .dark ? IDColor.darkBg : IDColor.primary).ignoresSafeArea()
            VStack(spacing: 0) {
                waitingHeader
                waitingCard
            }
        }
        .overlay { loadingOverlay }
    }

    private var waitingHeader: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .leading) {
                HStack(spacing: 10) {
                    Image(colorScheme == .dark ? "ic_lang_button_dark" : "ic_lang_button_light")
                        .frame(width: 44, height: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Görüntülü Görüşme")
                            .font(IDFont.bodyMedium(.semibold))
                            .foregroundColor(.white)
                        Text("Temsilcimiz bağlanıyor")
                            .font(IDFont.caption(.regular))
                            .foregroundColor(.white.opacity(0.75))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, IDSpacing.lg)

            HStack(spacing: IDSpacing.xs) {
                ForEach(0..<4) { i in
                    Capsule()
                        .fill(i < 3 ? Color.white : Color.white.opacity(0.35))
                        .frame(maxWidth: .infinity)
                        .frame(height: 6)
                }
            }
            .padding(.horizontal, IDSpacing.lg)
        }
        .padding(.top, IDSpacing.sm)
        .padding(.bottom, IDSpacing.lg)
    }

    private var waitingCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: IDSpacing.xl) {
                VStack(alignment: .leading, spacing: IDSpacing.sm) {
                    Text("Lütfen bekleyin")
                        .font(IDFont.displayMedium(.semibold))
                        .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))

                    Text(.waitingDesc1)
                        .font(IDFont.body(.regular))
                        .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                        .lineSpacing(4)
                }

                queueInfoCard

                HStack(spacing: IDSpacing.sm) {
                    ProgressView()
                        .tint(IDColor.primary)
                    Text("Bağlantı bekleniyor")
                        .font(IDFont.bodySmall(.medium))
                        .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                }
            }
            .padding(.top, IDSpacing.xl)
            .padding(.horizontal, IDSpacing.lg)

            Spacer()

            cancelButton
                .padding(.horizontal, IDSpacing.lg)
                .padding(.bottom, IDSpacing.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(IDColor.adaptiveSurface(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: IDRadius.card))
        .ignoresSafeArea(edges: .bottom)
    }

    private var queueInfoCard: some View {
        Group {
            if !viewModel.queuePosition.isEmpty && viewModel.queuePosition != "0" {
                HStack(spacing: IDSpacing.md) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 18))
                        .foregroundColor(IDColor.primary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(viewModel.queuePosition). sıradasınız")
                            .font(IDFont.bodySmall(.semibold))
                            .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                        if !viewModel.estimatedWait.isEmpty && viewModel.estimatedWait != "0" {
                            Text("Tahmini ~\(viewModel.estimatedWait) dakika")
                                .font(IDFont.caption(.regular))
                                .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                        }
                    }
                    Spacer()
                }
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
                HStack(spacing: IDSpacing.md) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 18))
                        .foregroundColor(IDColor.primary)
                    Text(.callScreenWaitRepresentative)
                        .font(IDFont.bodySmall(.medium))
                        .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                    Spacer()
                }
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

    private var cancelButton: some View {
        Button(action: { showEndCallAlert = true }) {
            Text("Görüşmeyi İptal Et")
                .font(IDFont.body(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(IDColor.primary)
                .clipShape(Capsule())
        }
    }

    // MARK: - Ringing

    private var ringingScreen: some View {
        ZStack {
            IDColor.adaptiveBackground(for: colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                avatarSection
                    .padding(.bottom, IDSpacing.xl)

                VStack(spacing: IDSpacing.sm) {
                    Text("Çağrı Geliyor")
                        .font(IDFont.displayMedium(.semibold))
                        .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))

                    Text("Temsilci sizinle görüşmek istiyor")
                        .font(IDFont.body(.regular))
                        .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                }
                .padding(.bottom, IDSpacing.xl)

                callerInfoCard
                    .padding(.horizontal, IDSpacing.lg)
                    .padding(.bottom, IDSpacing.xxl)

                Spacer()

                callActionButtons
                    .padding(.bottom, 60)
            }
        }
    }

    private var avatarSection: some View {
        ZStack {
            Circle()
                .fill(IDColor.primary.opacity(0.12))
                .frame(width: 160, height: 160)
                .scaleEffect(pulseActive ? 1.15 : 0.95)
                .animation(
                    .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: pulseActive
                )

            Circle()
                .fill(IDColor.primary.opacity(0.2))
                .frame(width: 130, height: 130)

            Circle()
                .fill(IDColor.primary)
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundColor(.white)
                )
        }
    }

    private var callerInfoCard: some View {
        HStack(spacing: IDSpacing.md) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 20))
                .foregroundColor(IDColor.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text("Identify Temsilcisi")
                    .font(IDFont.bodySmall(.semibold))
                    .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                Text("Kimlik doğrulama görüşmesi")
                    .font(IDFont.caption(.regular))
                    .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
            }
            Spacer()

            Image(systemName: "lock.fill")
                .font(.system(size: 14))
                .foregroundColor(IDColor.success)
        }
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

    private var callActionButtons: some View {
        HStack(spacing: 60) {
            Button(action: { viewModel.terminateCall(appState: appState) }) {
                ZStack {
                    Circle()
                        .fill(IDColor.error)
                        .frame(width: 72, height: 72)
                    Image(systemName: "phone.down.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.white)
                }
            }

            Button(action: { viewModel.acceptCall() }) {
                ZStack {
                    Circle()
                        .fill(IDColor.successBright)
                        .frame(width: 72, height: 72)
                    Image(systemName: "phone.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.white)
                }
            }
        }
    }

    // MARK: - Connected

    private var connectedScreen: some View {
        ZStack(alignment: .top) {
            VideoFeedRepresentable(videoView: viewModel.remoteVideoView)
                .ignoresSafeArea()

            VStack {
                HStack(alignment: .top) {
                    networkQualityView
                        .padding(.top, IDSpacing.lg)
                        .padding(.leading, IDSpacing.lg)

                    Spacer()

                    localCameraView
                }

                Spacer()

                bottomCallPanel
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var networkQualityView: some View {
        HStack(spacing: 4) {
            Image(systemName: networkQualityIcon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(networkQualityColor)
        }
        .padding(.horizontal, IDSpacing.sm)
        .padding(.vertical, IDSpacing.xs)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    private var networkQualityIcon: String {
        switch viewModel.networkQualityText {
        case "good":   return "wifi"
        case "medium": return "wifi.exclamationmark"
        default:       return "wifi.slash"
        }
    }

    private var networkQualityColor: Color {
        switch viewModel.networkQualityText {
        case "good":   return IDColor.successBright
        case "medium": return Color.orange
        default:       return IDColor.error
        }
    }

    private var localCameraView: some View {
        VideoFeedRepresentable(videoView: viewModel.localVideoView)
            .frame(width: 112, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: IDRadius.md))
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
        .clipShape(TopRoundedShape(radius: IDRadius.card))
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
                        .font(IDFont.body(.regular))
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
                        .font(IDFont.body(.semibold))
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
                        .font(IDFont.body(.regular))
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

// MARK: - Preview

#Preview {
    CallScreenView()
        .environmentObject(AppStateViewModel())
}
