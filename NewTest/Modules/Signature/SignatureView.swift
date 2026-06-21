//
//  SignatureView.swift
//  NewTest

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
            VStack(spacing: 10) {
                SDKNavigationBar(
                    style: .progress(steps: 4, current: 3),
                    title: "İmza Doğrulama",
                    subtitle: "İmzanızı doğrulamamıza yardımcı olun",
                    onBack: {}
                )
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

            SDKButton(title: "Devam", isDisabled: !viewModel.signatureDrawn) {
                guard let image = signatureActions.getSignatureForServer(isDark: colorScheme == .dark) else { return }
                viewModel.uploadSignature(image: image, appState: appState)
            }
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
                onDraw: { viewModel.signatureDidDraw() },
                colorScheme: colorScheme
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
                            .fill(colorScheme == .dark ? Color(white: 0.2) : Color.white)
                            .overlay(Circle().stroke(IDColor.divider, lineWidth: 1))
                    )
            }
            .padding(.top, IDSpacing.lg)
            .padding(.leading, IDSpacing.lg)
        }
        .frame(height: 189)
        .background(colorScheme == .dark ? Color(white: 0.12) : Color.white)
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
}

#Preview {
    SignatureView()
        .environmentObject(AppStateViewModel())
}
