//
//  LostConnectionView.swift
//  NewTest
//

import SwiftUI
import IdentifySDK

struct LostConnectionView: View {

    @StateObject private var viewModel = LostConnectionViewModel()
    @Environment(\.colorScheme) private var colorScheme

    var onReconnectCompleted: (() -> Void)?
    var onReconnectCompletedWithStatus: ((Bool, String?) -> Void)?

    var body: some View {
        ZStack {
            IDColor.adaptiveBackground(for: colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                iconArea
                    .padding(.bottom, IDSpacing.xxl)

                textArea

                Spacer()

                reconnectButton
                    .padding(.horizontal, IDSpacing.lg)
                    .padding(.bottom, IDSpacing.xxl)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.onReconnectCompleted = onReconnectCompleted
            viewModel.onReconnectCompletedWithStatus = onReconnectCompletedWithStatus
        }
    }

    // MARK: - Icon

    private var iconArea: some View {
        ZStack {
            Image("lost_connection")
                .resizable()
                .scaledToFit()
                .frame(width: 144, height: 144)
        }
    }

    // MARK: - Text

    private var textArea: some View {
        VStack(spacing: IDSpacing.sm) {
            Text("Bağlantı koptu..")
                .font(IDFont.displayMedium(.semibold))
                .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                .multilineTextAlignment(.center)

            Text("Canlı görüşme sırasında bağlantınız koptu lütfen bağlantınızı kontrol edin.")
                .font(IDFont.body(.regular))
                .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, IDSpacing.xxl)
        }
    }

    // MARK: - Button

    private var reconnectButton: some View {
        Button(action: { viewModel.reconnect() }) {
            HStack(spacing: 8) {
                if viewModel.isReconnecting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.85)
                }
                Text(buttonTitle)
                    .font(IDFont.body(.semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(viewModel.canReconnect ? IDColor.primary : IDColor.primary.opacity(0.35))
            .clipShape(Capsule())
        }
        .disabled(!viewModel.canReconnect)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isReconnecting)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isNetworkAvailable)
    }

    private var buttonTitle: String {
        if viewModel.isReconnecting { return "Bağlanıyor..." }
        if !viewModel.isNetworkAvailable { return "İnternet Yok" }
        return "Yeniden Bağlan"
    }
}

#Preview {
    LostConnectionView(onReconnectCompleted: { }, onReconnectCompletedWithStatus: { _,_ in })
        .environmentObject(LostConnectionViewModel())
        .environmentObject(AppStateViewModel())
}
