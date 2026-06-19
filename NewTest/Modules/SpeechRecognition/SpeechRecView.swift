//
//  SpeechRecView.swift
//  NewTest
//

import SwiftUI

struct SpeechRecView: View {

    @StateObject private var viewModel = SpeechRecViewModel()
    @EnvironmentObject private var appState: AppStateViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var micScale: CGFloat = 1.0
    private let accentOrange = Color(hex: "#FCA64F")

    var body: some View {
        ZStack(alignment: .top) {
            (colorScheme == .dark ? IDColor.darkBg : IDColor.primary).ignoresSafeArea()
            VStack(spacing: 0) {
                headerArea
                cardArea
            }
        }
        .successBanner("Kelime okuma başarılı", isVisible: viewModel.speechSuccess)
        .overlay {
            if viewModel.isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView().tint(.white)
            }
        }
    }

    // MARK: - Header

    private var headerArea: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .leading) {
                HStack(spacing: 10) {
                    identifyLogoView
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Konuşma Testi")
                            .font(IDFont.bodyMedium(.semibold))
                            .foregroundColor(.white)
                        Text("İmzanızı doğrulamamıza yardımcı olun")
                            .font(IDFont.caption(.regular))
                            .foregroundColor(.white.opacity(0.75))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)

                Button(action: {}) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal, IDSpacing.lg)

            HStack(spacing: 6) {
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

    // MARK: - Kart

    private var cardArea: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: IDSpacing.xl) {
                titleSection
                wordCard
            }
            .padding(.top, IDSpacing.xxl)
            .padding(.horizontal, IDSpacing.lg)

            Spacer()

            micButtonArea

            Spacer()

            errorRow
                .padding(.horizontal, IDSpacing.lg)

            recognizedWordBox
                .padding(.horizontal, IDSpacing.lg)
                .padding(.bottom, 16)

            continueButton
                .padding(.horizontal, IDSpacing.lg)
                .padding(.bottom, IDSpacing.xxl)
        }
        .background(IDColor.adaptiveSurface(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: IDRadius.card))
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Başlık

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: IDSpacing.sm) {
            Text("Konuşma Testi")
                .font(IDFont.displayMedium(.semibold))
                .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))

            Text("Lütfen mikrofona basılı tutarak aşağıdaki kelimeyi okuyun")
                .font(IDFont.bodyRegular(.regular))
                .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                .lineSpacing(4)
        }
    }

    // MARK: - Kelime Kartı

    private var wordCard: some View {
        Text(viewModel.targetWord)
            .font(.system(size: 40, weight: .heavy))
            .foregroundStyle(
                LinearGradient(
                    colors: [.red, .orange, .green, .teal, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, IDSpacing.xl)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
            )
    }

    // MARK: - Mikrofon Butonu

    private var micButtonArea: some View {
        ZStack {
            Circle()
                .fill(accentOrange)
                .frame(width: 80, height: 80)
                .shadow(color: accentOrange.opacity(0.4), radius: 12, y: 6)

            Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)
        }
        .scaleEffect(micScale)
        .frame(maxWidth: .infinity, alignment: .center)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !viewModel.isRecording else { return }
                    viewModel.startRecording()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                        micScale = 1.15
                    }
                }
                .onEnded { _ in
                    viewModel.stopRecording()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
                        micScale = 1.0
                    }
                }
        )
    }

    // MARK: - Tanınan Kelime Kutusu

    private var recognizedWordBox: some View {
        VStack(alignment: .leading, spacing: IDSpacing.xs) {
            Text("Söylediğiniz kelime:")
                .font(IDFont.bodySmall(.regular))
                .foregroundColor(accentOrange)

            Text(viewModel.recognizedText.isEmpty ? "—" : viewModel.recognizedText)
                .font(IDFont.displayMedium(.bold))
                .foregroundColor(accentOrange)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(IDSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(accentOrange.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    accentOrange.opacity(0.5),
                    style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                )
        )
    }

    // MARK: - Hata Satırı

    @ViewBuilder
    private var errorRow: some View {
        if let msg = viewModel.errorMessage {
            Text(msg)
                .font(IDFont.caption(.regular))
                .foregroundColor(IDColor.error)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: - Devam Butonu

    private var continueButton: some View {
        Button(action: {
            viewModel.confirmSpeech(appState: appState)
        }) {
            Text("Devam")
                .font(IDFont.bodyRegular(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    viewModel.speechSuccess
                        ? IDColor.primary
                        : IDColor.primary.opacity(0.35)
                )
                .clipShape(Capsule())
        }
        .disabled(!viewModel.speechSuccess)
        .animation(.easeInOut(duration: 0.2), value: viewModel.speechSuccess)
    }

    // MARK: - Logo

    private var identifyLogoView: some View {
        ZStack {
            Image(colorScheme == .dark ? "ic_lang_button_dark" : "ic_lang_button_light")
                .frame(width: 44, height: 44)
        }
    }
}

#Preview {
    SpeechRecView()
        .environmentObject(AppStateViewModel())
}
