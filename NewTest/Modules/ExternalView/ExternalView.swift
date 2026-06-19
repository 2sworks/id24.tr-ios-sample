//
//  ExternalView.swift
//  NewTest
//
//  SDK modülleri arasına eklenen özel (harici) ekranın SwiftUI karşılığı.
//  UIKit'teki ExternalViewController + isExternalScreen = true davranışını taklit eder:
//  Bu ekran coordinator path'ine eklenirken moduleStepOrder artmaz.
//  "Devam Et" butonu advanceToNextModule() çağırarak sıradaki SDK modülünü yükler.
//

import SwiftUI

struct ExternalView: View {

    @StateObject private var viewModel: ExternalViewModel
    @EnvironmentObject private var appState: AppStateViewModel
    @Environment(\.colorScheme) private var colorScheme

    init(
        title: String = "Bilgilendirme",
        subtitle: String = "Devam etmeden önce lütfen bilgileri okuyun.",
        icon: String = "info.circle.fill"
    ) {
        _viewModel = StateObject(wrappedValue: ExternalViewModel(
            title: title,
            subtitle: subtitle,
            iconName: icon
        ))
    }

    var body: some View {
        ZStack(alignment: .top) {
            (colorScheme == .dark ? IDColor.darkBg : IDColor.primary)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                headerArea
                cardArea
            }
        }
    }

    // MARK: - Header

    private var headerArea: some View {
        HStack(spacing: 10) {
            ZStack {
                Image(colorScheme == .dark ? "ic_lang_button_dark" : "ic_lang_button_light")
                    .frame(width: 44, height: 44)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Kimlik Doğrulama")
                    .font(IDFont.bodyMedium(.semibold))
                    .foregroundColor(.white)
                Text("Devam etmeden önce bilgileri okuyun")
                    .font(IDFont.caption(.regular))
                    .foregroundColor(.white.opacity(0.75))
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, IDSpacing.lg)
        .padding(.top, IDSpacing.sm)
        .padding(.bottom, IDSpacing.lg)
    }

    // MARK: - Card

    private var cardArea: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: IDSpacing.xl) {
                    iconArea
                    titleSection
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

    // MARK: - Icon

    private var iconArea: some View {
        ZStack {
            Circle()
                .fill(IDColor.primary.opacity(0.12))
                .frame(width: 88, height: 88)
            Image(systemName: viewModel.iconName)
                .font(.system(size: 40))
                .foregroundColor(IDColor.primary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Title & Subtitle

    private var titleSection: some View {
        VStack(spacing: IDSpacing.sm) {
            Text(viewModel.title)
                .font(IDFont.displayMedium(.semibold))
                .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                .multilineTextAlignment(.center)

            Text(viewModel.subtitle)
                .font(IDFont.bodyRegular(.regular))
                .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button {
            viewModel.proceed(appState: appState)
        } label: {
            Text("Devam Et")
                .font(IDFont.bodyRegular(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(IDColor.primary)
                .clipShape(Capsule())
        }
    }
}

#Preview {
    ExternalView(
        title: "Bilgilendirme",
        subtitle: "Devam etmeden önce lütfen bilgileri okuyun.",
        icon: "info.circle.fill"
    )
    .environmentObject(AppStateViewModel())
    .environmentObject(AppNavigationCoordinator())
}
