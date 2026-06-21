//
//  SignLangView.swift
//  NewTest
//

import SwiftUI

struct SignLangView: View {

    @StateObject private var viewModel = SignLangViewModel()
    @Environment(\.colorScheme) private var colorScheme

    var onFinish: () -> Void

    var body: some View {
        ZStack {
            IDColor.adaptiveBackground(for: colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                illustration
                    .padding(.bottom, IDSpacing.xxl)

                textBlock
                    .padding(.horizontal, IDSpacing.lg)
                    .padding(.bottom, IDSpacing.xxl)

                toggleRow
                    .padding(.horizontal, IDSpacing.lg)

                Spacer()

                SDKButton(
                    title: SDKLangManager.shared.translate(.continuePage),
                    style: .primary
                ) {
                    viewModel.continueAction(onFinish: onFinish)
                }
                .padding(.horizontal, IDSpacing.lg)
                .padding(.bottom, IDSpacing.xxl)
            }
        }
    }

    // MARK: - Illustration

    private var illustration: some View {
        ZStack {
            Circle()
                .fill(colorScheme == .dark
                      ? Color.white.opacity(0.08)
                      : IDColor.primary.opacity(0.08))
                .frame(width: 160, height: 160)

            Image(systemName: "person.wave.2.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .foregroundColor(colorScheme == .dark ? .white : IDColor.primary)
        }
    }

    // MARK: - Text Block

    private var textBlock: some View {
        VStack(spacing: IDSpacing.sm) {
            Text("İşaret Dili Desteği")
                .font(IDFont.displayMedium(.semibold))
                .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                .multilineTextAlignment(.center)

            Text("Görüntülü görüşme sürecinde size işaret dili bilen bir müşteri temsilcisi bağlamak ister misiniz?")
                .font(IDFont.bodyRegular(.regular))
                .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }

    // MARK: - Toggle Row

    private var toggleRow: some View {
        HStack(spacing: IDSpacing.md) {
            Text(SDKLangManager.shared.translate(.coreSignLang))
                .font(IDFont.bodyRegular(.regular))
                .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)

            Toggle("", isOn: $viewModel.isSignLangEnabled)
                .tint(IDColor.primary)
                .labelsHidden()
        }
        .padding(IDSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: IDRadius.lg)
                .fill(IDColor.adaptiveSurface(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: IDRadius.lg)
                        .stroke(
                            viewModel.isSignLangEnabled
                                ? IDColor.primary.opacity(0.4)
                                : IDColor.adaptiveBorder(for: colorScheme),
                            lineWidth: 1
                        )
                )
        )
        .animation(.easeInOut(duration: 0.2), value: viewModel.isSignLangEnabled)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("İşaret Dili — Kapalı") {
    SignLangView(onFinish: {})
}

#Preview("İşaret Dili — Açık") {
    let vm = SignLangViewModel()
    vm.isSignLangEnabled = true
    return SignLangView(onFinish: {})
}
#endif
