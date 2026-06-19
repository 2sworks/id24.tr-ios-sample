//
//  ThankYouView.swift
//  NewTest
//
//  Tamamlanma ekrani.
//
//  DURUM:
//    .completed    -> basarili KYC (ty_checkmark, yesil)
//    .missedCall   -> cagri cevapsiz (ty_xmark, turuncu)
//    .notCompleted -> tamamlanamadi (ty_xmark, kirmizi)
//
//  CIKIS: appState.resetFlow() -> ana ekrana don
//

import SwiftUI

struct ThankYouView: View {

    @StateObject private var viewModel: ThankYouViewModel
    @EnvironmentObject private var appState: AppStateViewModel
    @Environment(\.colorScheme) private var colorScheme

    init(status: ThankYouStatus = .completed) {
        _viewModel = StateObject(wrappedValue: ThankYouViewModel(status: status))
    }

    var body: some View {
        ZStack {
            IDColor.adaptiveBackground(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                logoArea
                Spacer()
                contentArea
                Spacer()
                actionButton
                    .padding(.horizontal, IDSpacing.lg)
                    .padding(.bottom, IDSpacing.xxl)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Logo

    private var logoArea: some View {
        Image("ic_identify_logo_text")
            .resizable()
            .scaledToFit()
            .frame(width: 118, height: 34, alignment: .center)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, IDSpacing.xl)
    }

    // MARK: - Content

    private var contentArea: some View {
        VStack(spacing: IDSpacing.lg) {
            statusIcon
            Text(titleText)
                .font(IDFont.displaySmall(.semibold))
                .foregroundColor(titleColor)
                .multilineTextAlignment(.center)
            VStack(spacing: IDSpacing.sm) {
                Text(subtitleText)
                    .font(IDFont.bodyRegular(.regular))
                    .foregroundColor(IDColor.inkMid)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                if !subtitle2Text.isEmpty {
                    Text(subtitle2Text)
                        .font(IDFont.bodyRegular(.regular))
                        .foregroundColor(IDColor.inkMid)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }
        }
        .padding(.horizontal, IDSpacing.xxl)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch viewModel.completeStatus {
        case .completed:
            Image("ty_checkmark")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
        case .missedCall:
            Image("ty_xmark")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundColor(.orange)
        case .notCompleted:
            Image("ty_xmark")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
        }
    }

    private var titleText: String {
        switch viewModel.completeStatus {
        case .completed:    return SDKKeywords.thankU.localized
        case .missedCall:   return SDKKeywords.missedCallTitle.localized
        case .notCompleted: return SDKKeywords.identifyFailedTitle.localized
        }
    }

    private var titleColor: Color {
        switch viewModel.completeStatus {
        case .completed:    return IDColor.success
        case .missedCall:   return .orange
        case .notCompleted: return IDColor.error
        }
    }

    private var subtitleText: String {
        switch viewModel.completeStatus {
        case .completed:
            return viewModel.isSelfieIdentification
                ? SDKKeywords.selfieIdentInfo1.localized
                : SDKKeywords.selfieIdentInfo3.localized
        case .missedCall:
            return SDKKeywords.missedCallSubTitle.localized
        case .notCompleted:
            return SDKKeywords.identifyFailedDesc.localized
        }
    }

    private var subtitle2Text: String {
        guard viewModel.completeStatus == .completed,
              viewModel.isSelfieIdentification else { return "" }
        return SDKKeywords.selfieIdentInfo2.localized
    }

    // MARK: - Button

    private var actionButton: some View {
        Button {
            appState.resetFlow()
        } label: {
            Text(SDKKeywords.coreOk.localized)
                .font(IDFont.bodyRegular(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(IDColor.primary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Previews

private extension ThankYouView {
    static func preview(status: ThankYouStatus) -> some View {
        ThankYouView(status: status)
            .environmentObject(AppStateViewModel())
            .environmentObject(AppNavigationCoordinator())
    }
}

#Preview("Başarılı") {
    ThankYouView.preview(status: .completed)
}

#Preview("Başarılı — Dark") {
    ThankYouView.preview(status: .completed)
        .preferredColorScheme(.dark)
}

#Preview("Cevapsız Çağrı") {
    ThankYouView.preview(status: .missedCall)
}

#Preview("Tamamlanamadı") {
    ThankYouView.preview(status: .notCompleted)
}
