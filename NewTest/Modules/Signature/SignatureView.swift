//
//  SignatureView.swift
//  NewTest
//

import SwiftUI
import SwiftSignatureView

struct SignatureView: View {

    @StateObject private var viewModel = SignatureViewModel()
    @StateObject private var signatureActions = SignatureViewActions()
    @EnvironmentObject private var appState: AppStateViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack(alignment: .top) {
            (colorScheme == .dark ? IDColor.darkBg : IDColor.primary).ignoresSafeArea()
            VStack(spacing: 0) {
                headerArea
                cardArea
            }
        }
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
                        Text("İmza Doğrulama")
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

            // SVG: 4 pill, h=6, rx=3, gap=4pt — 1-2-3 beyaz, 4. soluk
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

    // MARK: - Kart

    private var cardArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleSection
                .padding(.top, IDSpacing.xl)
                .padding(.horizontal, IDSpacing.lg)

            signatureBox
                .padding(.top, IDSpacing.xl)
                .padding(.horizontal, IDSpacing.lg)

            Spacer()

            errorRow
                .padding(.horizontal, IDSpacing.lg)
                .padding(.bottom, IDSpacing.sm)

            continueButton
                .padding(.horizontal, IDSpacing.lg)
                .padding(.bottom, IDSpacing.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(IDColor.adaptiveSurface(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: IDRadius.card))
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Başlık

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: IDSpacing.sm) {
            Text("İmzanızı atın")
                .font(IDFont.displayMedium(.semibold))
                .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))

            Text("Kimlik tespiti için lütfen belirtilen alana imzanızı atın")
                .font(IDFont.bodyRegular(.regular))
                .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                .lineSpacing(4)
        }
    }

    // MARK: - İmza Kutusu (SVG: w=360, h=189, rx=23.5, stroke=#E5E7EB)

    private var signatureBox: some View {
        ZStack(alignment: .topLeading) {
            SwiftSignatureViewRepresentable(
                actions: signatureActions,
                onDraw: { viewModel.signatureDidDraw() }
            )
            .clipShape(RoundedRectangle(cornerRadius: IDRadius.xl))

            // SVG: 39×39, rx=19.5, stroke=#CBD5E1, left=16, top=16
            Button(action: {
                signatureActions.clear()
                viewModel.clearSignature()
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(IDColor.inkMid)
                    .frame(width: 39, height: 39)
                    .background(
                        Circle()
                            .fill(Color.white)
                            .overlay(Circle().stroke(IDColor.divider, lineWidth: 1))
                    )
            }
            .padding(.top, IDSpacing.lg)
            .padding(.leading, IDSpacing.lg)
        }
        .frame(height: 189)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: IDRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: IDRadius.xl)
                .stroke(IDColor.inkBorder, lineWidth: 1)
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

    // MARK: - Devam Butonu (SVG: h=50, rx=25, fill=#446EF7)

    private var continueButton: some View {
        Button(action: {
            guard let image = signatureActions.getCroppedSignature() else { return }
            viewModel.uploadSignature(image: image, appState: appState)
        }) {
            Text("Devam")
                .font(IDFont.bodyRegular(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    viewModel.signatureDrawn
                        ? IDColor.primary
                        : IDColor.primary.opacity(0.35)
                )
                .clipShape(Capsule())
        }
        .disabled(!viewModel.signatureDrawn)
        .animation(.easeInOut(duration: 0.2), value: viewModel.signatureDrawn)
    }

    // MARK: - Logo

    private var identifyLogoView: some View {
        Image(colorScheme == .dark ? "ic_lang_button_dark" : "ic_lang_button_light")
            .frame(width: 44, height: 44)
    }
}

#Preview {
    SignatureView()
        .environmentObject(AppStateViewModel())
}
