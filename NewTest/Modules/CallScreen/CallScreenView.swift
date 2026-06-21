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
                    waitingScreen
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.callState)

            errorToast
        }
        .onAppear {
            appState.manager.socketMessageListener = viewModel
            UIApplication.shared.isIdleTimerDisabled = true
            viewModel.checkSignLangIfNeeded(appState: appState)
        }
        .onDisappear {
            appState.manager.socketMessageListener = appState
            UIApplication.shared.isIdleTimerDisabled = false
            viewModel.cleanup()
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
        .successBanner(viewModel.photoTakenToast ?? "", isVisible: viewModel.photoTakenToast != nil)
        .sheet(isPresented: $viewModel.showNFCEdit) {
            CallNFCEditSheet(viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $viewModel.showSignLangGate) {
            SignLangView {
                viewModel.signLangCompleted()
            }
        }
        .fullScreenCover(isPresented: $viewModel.showLostConnection) {
            LostConnectionView(
                onReconnectCompleted: {
                    viewModel.handleReconnectCompleted()
                },
                onReconnectCompletedWithStatus: { isWaitingRoom, statusType in
                    viewModel.handleReconnectCompletedWithStatus(
                        isWaitingRoom: isWaitingRoom,
                        statusType: statusType,
                        appState: appState
                    )
                }
            )
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
                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : IDColor.primary.opacity(0.1))
                .frame(width: 144, height: 144)

            Image(.icIdentifyLogoText)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 96)
                .foregroundColor(colorScheme == .dark ? .white : IDColor.primary)
        }
    }

    private var queueInfoCard: some View {
        Group {
            if !viewModel.queuePosition.isEmpty && viewModel.queuePosition != "0" {
                VStack(spacing: 4) {
                    Text("Bekleyenler arasında \(viewModel.queuePosition). sıradasınız")
                        .font(IDFont.bodyMediumPlus(.semibold))
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
                        .fill(IDColor.adaptiveSurface(for: colorScheme))
                        .overlay(
                            RoundedRectangle(cornerRadius: IDRadius.lg)
                                .stroke(IDColor.adaptiveBorder(for: colorScheme), lineWidth: 1)
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
                            .fill(IDColor.adaptiveSurface(for: colorScheme))
                            .overlay(
                                RoundedRectangle(cornerRadius: IDRadius.lg)
                                    .stroke(IDColor.adaptiveBorder(for: colorScheme), lineWidth: 1)
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
                HStack(alignment: .top) {
                    networkQualityIndicator
                        .padding(.top, IDSpacing.xl)
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

    // MARK: - Network Quality Indicator

    @ViewBuilder
    private var networkQualityIndicator: some View {
        switch viewModel.networkQuality {
        case .none:
            EmptyView()
        case .bad:
            qualityIcon(name: "wifi.exclamationmark", color: .red)
                .padding(.leading, IDSpacing.lg)
        case .medium:
            qualityIcon(name: "wifi", color: .yellow)
                .padding(.leading, IDSpacing.lg)
        case .good:
            qualityIcon(name: "wifi", color: .green)
                .padding(.leading, IDSpacing.lg)
        }
    }

    private func qualityIcon(name: String, color: Color) -> some View {
        Image(systemName: name)
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(color)
            .padding(8)
            .background(.ultraThinMaterial, in: Circle())
    }

    private var bottomCallPanel: some View {
        VStack(spacing: IDSpacing.lg) {
            Capsule()
                .fill(Color.white.opacity(0.4))
                .frame(width: 44, height: 5)

            Button(action: {
                if viewModel.endCallEnabled {
                    showEndCallAlert = true
                }
            }) {
                VStack {
                    ZStack {
                        Circle()
                            .fill(IDColor.error)
                            .frame(width: 72, height: 72)
                            .opacity(viewModel.endCallEnabled ? 1 : 0.35)
                        Image(systemName: "xmark")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Text("Görüşmeyi sonlandır")
                        .font(IDFont.bodySmall(.medium))
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

// MARK: - NFC Edit Sheet (Remote NFC — panel .editNfcProcess ile tetiklenir)

private struct CallNFCEditSheet: View {

    @ObservedObject var viewModel: CallScreenViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var serial: String = ""
    @State private var birth: String = ""
    @State private var valid: String = ""

    private var canSave: Bool {
        !serial.isEmpty && !birth.isEmpty && !valid.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            sheetHeader
            VStack(alignment: .leading, spacing: IDSpacing.xl) {
                VStack(alignment: .leading, spacing: IDSpacing.sm) {
                    Text("MRZ Bilgilerini Düzeltin")
                        .font(IDFont.bodyMedium(.semibold))
                        .foregroundColor(IDColor.error)
                    Text("Kimlik bilgilerinde hata tespit edildi. Lütfen aşağıdaki alanları kontrol edip güncelleyin.")
                        .font(IDFont.bodyRegular(.regular))
                        .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                        .lineSpacing(4)
                }
                fieldGroup(title: "Seri No") {
                    editTextField(placeholder: "A32R17869", text: $serial, keyboard: .asciiCapable)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                }
                fieldGroup(title: "Doğum Tarihi") {
                    editTextField(placeholder: "dd.MM.yyyy", text: $birth, keyboard: .numbersAndPunctuation)
                }
                fieldGroup(title: "Son Geçerlilik") {
                    editTextField(placeholder: "dd.MM.yyyy", text: $valid, keyboard: .numbersAndPunctuation)
                }
            }
            .padding(.top, IDSpacing.xl)
            .padding(.horizontal, IDSpacing.lg)
            Spacer()
            Button(action: {
                viewModel.saveAndRestartRemoteNFC(serial: serial, birth: birth, valid: valid)
            }) {
                Text("Güncelle")
                    .font(IDFont.bodyRegular(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(canSave ? IDColor.inkDarkest : IDColor.inkDarkest.opacity(0.35))
                    .clipShape(Capsule())
            }
            .disabled(!canSave)
            .animation(.easeInOut(duration: 0.2), value: canSave)
            .padding(.horizontal, IDSpacing.lg)
            .padding(.bottom, IDSpacing.xxl)
        }
        .background(IDColor.adaptiveBackground(for: colorScheme).ignoresSafeArea())
        .onAppear {
            serial = viewModel.nfcEditSerial
            birth = viewModel.nfcEditBirth
            valid = viewModel.nfcEditValid
        }
    }

    private var sheetHeader: some View {
        HStack {
            Spacer().frame(width: 32)
            Spacer()
            Text("MRZ Düzeltme")
                .font(IDFont.bodyMedium(.semibold))
                .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(IDColor.adaptiveSurface(for: colorScheme)))
            }
        }
        .padding(.horizontal, IDSpacing.lg)
        .padding(.top, IDSpacing.lg)
        .padding(.bottom, IDSpacing.md)
    }

    @ViewBuilder
    private func fieldGroup<Content: View>(title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: IDSpacing.sm) {
            Text(title)
                .font(IDFont.bodySmall(.medium))
                .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
            content()
        }
    }

    private func editTextField(placeholder: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        ZStack(alignment: .leading) {
            Text(placeholder)
                .font(IDFont.bodySmall())
                .foregroundColor(IDColor.inkLight)
                .allowsHitTesting(false)
                .opacity(text.wrappedValue.isEmpty ? 1 : 0)
            TextField("", text: text)
                .font(IDFont.bodySmall())
                .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                .keyboardType(keyboard)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, IDSpacing.lg)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: IDRadius.md)
                .fill(IDColor.adaptiveSurface(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: IDRadius.md)
                        .stroke(IDColor.inkBorder, lineWidth: 1)
                )
        )
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

#Preview("Photo Toast") {
    CallScreenView(viewModel: CallScreenViewModel(
        previewState: .connected,
        photoTakenToast: "Temsilci ekran görüntüsü aldı"
    ))
    .environmentObject(AppStateViewModel())
}

#Preview("Bağlantı Kalitesi — Kötü") {
    CallScreenView(viewModel: CallScreenViewModel(
        previewState: .connected,
        networkQuality: .bad
    ))
    .environmentObject(AppStateViewModel())
}

#Preview("Bağlantı Kalitesi — İyi") {
    CallScreenView(viewModel: CallScreenViewModel(
        previewState: .connected,
        networkQuality: .good
    ))
    .environmentObject(AppStateViewModel())
}

#endif
