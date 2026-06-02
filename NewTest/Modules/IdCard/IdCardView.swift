//
//  IdCardView.swift
//  NewTest
//

import SwiftUI
import IdentifySDK

// MARK: - Screen State

private enum IdCardScreenState {
    case typeSelection
    case scanning
}

// MARK: - Main View

struct IdCardView: View {

    @StateObject private var viewModel = IdCardViewModel()
    @EnvironmentObject private var appState: AppStateViewModel
    @EnvironmentObject private var coordinator: AppNavigationCoordinator
    @Environment(\.colorScheme) private var colorScheme

    @State private var screenState: IdCardScreenState = .typeSelection
    @State private var selectedCardType: CardType = .idCard

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
                Color.black.opacity(0.45).ignoresSafeArea()
                ProgressView().tint(.white).scaleEffect(1.3)
            }
        }
        .alert("Hata", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("Tamam", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear {
            if let first = viewModel.allowedCardTypes.first {
                selectedCardType = first
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
                        Text("Kimlik Doğrulama")
                            .font(IDFont.bodyMedium(.semibold))
                            .foregroundColor(.white)
                        Text(screenState == .typeSelection
                             ? "Lütfen bir yöntem seçerek devam edin"
                             : "Lütfen ilgili adımları tamamlayın")
                            .font(IDFont.caption(.regular))
                            .foregroundColor(.white.opacity(0.75))
                            .animation(.easeInOut, value: screenState == .typeSelection)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)

                Button(action: {
                    if screenState == .scanning {
                        withAnimation { screenState = .typeSelection }
                    }
                }) {
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
                        .fill(i < (screenState == .typeSelection ? 2 : 3)
                              ? Color.white : Color.white.opacity(0.35))
                        .frame(maxWidth: .infinity)
                        .frame(height: 6)
                        .animation(.easeInOut, value: screenState == .typeSelection)
                }
            }
            .padding(.horizontal, IDSpacing.lg)
        }
        .padding(.top, IDSpacing.sm)
        .padding(.bottom, IDSpacing.lg)
    }

    // MARK: - Card Area

    private var cardArea: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: IDSpacing.xl) {
                    if screenState == .typeSelection {
                        typeSelectionContent
                    } else {
                        scanningContent
                    }
                }
                .padding(.top, IDSpacing.xxl)
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

    // MARK: - Type Selection Content

    private var typeSelectionContent: some View {
        VStack(alignment: .leading, spacing: IDSpacing.xl) {
            titleBlock(
                title: "Belge türünü seçin",
                subtitle: "Lütfen kaydınızı nasıl doğrulamak istediğinizi seçin ve devam edin."
            )

            VStack(spacing: IDSpacing.sm) {
                let allowed = viewModel.allowedCardTypes
                if allowed.contains(where: { if case .idCard = $0 { return true }; return false }) {
                    CardTypeOptionRow(
                        icon: "person.text.rectangle",
                        title: "Çipli T.C. Kimlik Kartı",
                        isSelected: { if case .idCard = selectedCardType { return true }; return false }()
                    ) { selectedCardType = .idCard }
                }
                if allowed.contains(where: { if case .passport = $0 { return true }; return false }) {
                    CardTypeOptionRow(
                        icon: "book.closed",
                        title: "Pasaport",
                        isSelected: { if case .passport = selectedCardType { return true }; return false }()
                    ) { selectedCardType = .passport }
                }
                if allowed.contains(where: { if case .oldSchool = $0 { return true }; return false }) {
                    CardTypeOptionRow(
                        icon: "rectangle.portrait.on.rectangle.portrait",
                        title: "Diğerleri",
                        isSelected: { if case .oldSchool = selectedCardType { return true }; return false }()
                    ) { selectedCardType = .oldSchool }
                }
            }
        }
    }

    // MARK: - Scanning Content

    private var scanningContent: some View {
        VStack(alignment: .leading, spacing: IDSpacing.xl) {
            titleBlock(
                title: "Kimlik Tarama",
                subtitle: "Lütfen kimliğinizin ön ve arka yüzünün fotoğrafını çekin, hazırsanız kamerayı açarak başlayabilirsiniz."
            )

            VStack(spacing: IDSpacing.sm) {
                let isPassport: Bool = {
                    if case .passport = selectedCardType { return true }; return false
                }()

                CardScanSlotView(
                    image: viewModel.frontPhoto,
                    buttonTitle: isPassport ? "Pasaport Tara" : "Kimlik Ön Yüz Tara"
                ) {
                    openScanner(for: .front)
                }

                if !isPassport {
                    CardScanSlotView(
                        image: viewModel.backPhoto,
                        buttonTitle: "Kimlik Arka Yüz Tara"
                    ) {
                        openScanner(for: .back)
                    }
                }
            }
        }
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button(action: handleContinue) {
            Text("Devam")
                .font(IDFont.body(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(continueEnabled ? IDColor.primary : IDColor.primary.opacity(0.35))
                .clipShape(Capsule())
        }
        .disabled(!continueEnabled)
        .animation(.easeInOut(duration: 0.2), value: continueEnabled)
    }

    private var continueEnabled: Bool {
        screenState == .typeSelection || viewModel.canContinue
    }

    private func handleContinue() {
        if screenState == .typeSelection {
            viewModel.selectCardType(selectedCardType)
            withAnimation { screenState = .scanning }
        } else {
            appState.advanceToNextModule()
        }
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
                .font(IDFont.body(.regular))
                .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                .lineSpacing(4)
        }
    }

    private var identifyLogoView: some View {
        Image(colorScheme == .dark ? "ic_lang_button_dark" : "ic_lang_button_light")
            .frame(width: 44, height: 44)
    }
}

// MARK: - Card Type Option Row

private struct CardTypeOptionRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: IDSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? IDColor.primary : IDColor.inkMid)
                    .frame(width: 28, height: 28)

                Text(title)
                    .font(IDFont.body(.medium))
                    .foregroundColor(isSelected
                                     ? IDColor.adaptiveTitle(for: colorScheme)
                                     : IDColor.adaptiveSubtitle(for: colorScheme))

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isSelected ? IDColor.primary : IDColor.inkBorder, lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(IDColor.primary)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(.horizontal, IDSpacing.lg)
            .frame(minHeight: 54)
            .background(
                RoundedRectangle(cornerRadius: IDRadius.md)
                    .fill(isSelected ? IDColor.primaryLight : rowBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: IDRadius.md)
                            .stroke(isSelected ? IDColor.primary : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private var rowBackground: Color {
        colorScheme == .dark ? Color(hex: "#1F2533") : .white
    }
}

// MARK: - Card Scan Slot

private struct CardScanSlotView: View {
    @Environment(\.colorScheme) private var colorScheme

    let image: UIImage?
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        ZStack {
            Group {
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    placeholderBackground
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            Button(action: action) {
                Text(buttonTitle)
                    .font(IDFont.body(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, IDSpacing.xl)
                    .frame(height: 44)
                    .background(IDColor.primary)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 148)
        .clipShape(RoundedRectangle(cornerRadius: IDRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: IDRadius.lg)
                .stroke(IDColor.inkBorder, lineWidth: 1)
        )
    }

    private var placeholderBackground: some View {
        (colorScheme == .dark
         ? Color(hex: "#1A2035")
         : Color(hex: "#D6E4F7"))
    }
}

// MARK: - Preview

#Preview {
    IdCardView()
        .environmentObject(AppStateViewModel())
        .environmentObject(AppNavigationCoordinator())
}
