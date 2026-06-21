//
//  IdCardView.swift
//  NewTest
//

import SwiftUI
import IdentifySDK

// MARK: - Main View

struct IdCardView: View {

    @StateObject private var viewModel = IdCardViewModel()
    @EnvironmentObject private var coordinator: AppNavigationCoordinator
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedCardType: CardType = .idCard

    var body: some View {
        ZStack(alignment: .top) {
            (colorScheme == .dark ? IDColor.darkBg : IDColor.primary).ignoresSafeArea()
            VStack(spacing: 0) {
                SDKNavigationBar(
                    style: .progress(steps: 4, current: 2),
                    title: "Kimlik Doğrulama",
                    subtitle: "Lütfen bir yöntem seçerek devam edin"
                )
                .padding(.top, IDSpacing.sm)
                cardArea
            }
        }
        .onAppear {
            if let first = viewModel.allowedCardTypes.first {
                selectedCardType = first
            }
        }
    }

    // MARK: - Card Area

    private var cardArea: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: IDSpacing.xl) {
                    typeSelectionContent
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
                let showAll = allowed.isEmpty
                if showAll || allowed.contains(where: { if case .idCard = $0 { return true }; return false }) {
                    CardTypeOptionRow(
                        icon: "person.text.rectangle",
                        title: "Çipli T.C. Kimlik Kartı",
                        isSelected: { if case .idCard = selectedCardType { return true }; return false }()
                    ) { selectedCardType = .idCard }
                }
                if showAll || allowed.contains(where: { if case .passport = $0 { return true }; return false }) {
                    CardTypeOptionRow(
                        icon: "book.closed",
                        title: "Pasaport",
                        isSelected: { if case .passport = selectedCardType { return true }; return false }()
                    ) { selectedCardType = .passport }
                }
                if showAll || allowed.contains(where: { if case .oldSchool = $0 { return true }; return false }) {
                    CardTypeOptionRow(
                        icon: "rectangle.portrait.on.rectangle.portrait",
                        title: "Diğerleri",
                        isSelected: { if case .oldSchool = selectedCardType { return true }; return false }()
                    ) { selectedCardType = .oldSchool }
                }
            }
        }
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        SDKButton(title: "Devam", action: handleContinue)
    }

    private func handleContinue() {
        coordinator.push(.idCardScanning(selectedCardType))
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

// MARK: - Card Type Option Row

private struct CardTypeOptionRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    private var uncheckedBgColor: Color {
        colorScheme == .dark ? IDColor.darkMuted : IDColor.divider
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(
                        isSelected ? IDColor.primaryLight : colorScheme == .dark ? IDColor.primaryLight : IDColor.darkMuted
                    )
                    .frame(width: 24, height: 24)

                Text(title)
                    .font(IDFont.bodyRegular(.regular))
                    .foregroundColor(
                        isSelected ? IDColor.primaryLight : colorScheme == .dark ? IDColor.primaryLight : IDColor.darkMuted
                    )
                    .multilineTextAlignment(.leading)

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isSelected ? IDColor.primaryLight : uncheckedBgColor, lineWidth: 2)
                        .frame(width: 20, height: 20)
                    if isSelected {
                        Circle()
                            .fill(IDColor.primaryLight)
                            .frame(width: 10, height: 10)
                    }
                }
            }
            .padding(.horizontal, IDSpacing.lg)
            .frame(minHeight: 48)
            .background(
                RoundedRectangle(cornerRadius: IDRadius.md)
                    .fill(isSelected ? IDColor.primary : uncheckedBgColor.opacity(0.2))
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Preview

#Preview {
    IdCardView()
        .environmentObject(AppStateViewModel())
        .environmentObject(AppNavigationCoordinator())
}
