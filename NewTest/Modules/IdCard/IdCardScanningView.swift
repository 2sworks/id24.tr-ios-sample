//
//  IdCardScanningView.swift
//  NewTest
//

import SwiftUI
import IdentifySDK

struct IdCardScanningView: View {

    let cardType: CardType

    @StateObject private var viewModel = IdCardViewModel()
    @EnvironmentObject private var appState: AppStateViewModel
    @EnvironmentObject private var coordinator: AppNavigationCoordinator
    @Environment(\.colorScheme) private var colorScheme

    private var isPassport: Bool {
        if case .passport = cardType { return true }
        return false
    }

    var body: some View {
        ZStack(alignment: .top) {
            (colorScheme == .dark ? IDColor.darkBg : IDColor.primary).ignoresSafeArea()
            VStack(spacing: 0) {
                SDKNavigationBar(
                    style: .progress(steps: appState.progressTotal, current: appState.progressStep),
                    title: "Kimlik Doğrulama",
                    subtitle: "Lütfen ilgili adımları tamamlayın",
                    onBack: { coordinator.pop() }
                )
                .padding(.top, IDSpacing.sm)
                cardArea
            }
        }
        .overlay {
            if viewModel.isLoading {
                Color.black.opacity(0.45).ignoresSafeArea()
                ProgressView().tint(.white).scaleEffect(1.3)
            }
        }
        .sdkAlert(
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            ),
            alert: IDAlertModel(
                type: .error,
                title: "Hata",
                message: viewModel.errorMessage ?? "",
                actions: [
                    IDAlertAction(title: "Tamam", style: .cancel)
                ]
            )
        )
        .onAppear {
            viewModel.selectCardType(cardType)
        }
    }

    // MARK: - Card Area

    private var cardArea: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: IDSpacing.xl) {
                titleBlock(
                    title: "Kimlik Tarama",
                    subtitle: "Lütfen kimliğinizin ön ve arka yüzünün fotoğrafını çekin, hazırsanız kamerayı açarak başlayabilirsiniz."
                )
            }
            .padding(.top, IDSpacing.xxl)
            .padding(.horizontal, IDSpacing.lg)

            ScrollView(showsIndicators: false) {
                VStack(spacing: IDSpacing.sm) {
                    CardScanSlotView(
                        image: viewModel.frontPhoto,
                        placeholderImageName: "frontID",
                        buttonTitle: isPassport ? "Pasaport Tara" : "Kimlik Ön Yüz Tara"
                    ) {
                        openScanner(for: .front)
                    }

                    if !isPassport {
                        CardScanSlotView(
                            image: viewModel.backPhoto,
                            placeholderImageName: "backID",
                            buttonTitle: "Kimlik Arka Yüz Tara"
                        ) {
                            openScanner(for: .back)
                        }
                    }
                }
                .padding(.top, IDSpacing.lg)
                .padding(.bottom, IDSpacing.xl)
                .padding(.horizontal, IDSpacing.lg)
            }

            continueButton
                .padding(.horizontal, IDSpacing.lg)
                .padding(.bottom, IDSpacing.xxl)
        }
        .background(IDColor.adaptiveSurface(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: IDRadius.card))
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        SDKButton(
            title: "Devam",
            isDisabled: !viewModel.canContinue,
            action: { appState.advanceToNextModule() }
        )
    }

    // MARK: - Scanner

    private func openScanner(for side: IdCardSide) {
        coordinator.onScanComplete = { image in
            if side == .front {
                viewModel.scanFront(image: image, appState: appState)
            } else {
                viewModel.scanBack(image: image, appState: appState)
            }
        }
        coordinator.push(.idCardScanner(side))
    }

    // MARK: - Helpers

    private func titleBlock(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: IDSpacing.sm) {
            Text(title)
                .font(IDFont.displayMedium(.semibold))
                .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
            Text(subtitle)
                .font(IDFont.bodyRegular(.regular))
                .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                .lineSpacing(4)
        }
    }


}

// MARK: - Card Scan Slot

private struct CardScanSlotView: View {
    @Environment(\.colorScheme) private var colorScheme

    let image: UIImage?
    let placeholderImageName: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
            } else {
                Image(placeholderImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
            }

            if image == nil {
                Button(action: action) {
                    Text(buttonTitle)
                        .font(IDFont.bodyRegular(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, IDSpacing.xl)
                        .frame(height: 44)
                        .background(IDColor.primary)
                        .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Button(action: action) {
                    HStack(spacing: 6) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Tekrar Çek")
                            .font(IDFont.caption(.semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, IDSpacing.md)
                    .padding(.vertical, IDSpacing.xs)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Capsule())
                }
                .padding(IDSpacing.sm)
            }
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: IDRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: IDRadius.lg)
                .stroke(IDColor.inkBorder, lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    IdCardScanningView(cardType: .idCard)
        .environmentObject(AppStateViewModel())
        .environmentObject(AppNavigationCoordinator())
}
