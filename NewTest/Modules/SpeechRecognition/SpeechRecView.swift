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
            VStack(spacing: 10) {
                SDKNavigationBar(
                    style: .progress(steps: 4, current: 3),
                    title: "Konuşma Testi",
                    subtitle: "İmzanızı doğrulamamıza yardımcı olun",
                    onBack: {}
                )
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
        SDKButton(
            title: "Devam",
            isDisabled: !viewModel.speechSuccess
        ) {
            viewModel.confirmSpeech(appState: appState)
        }
    }
}

#Preview {
    SpeechRecView()
        .environmentObject(AppStateViewModel())
}
