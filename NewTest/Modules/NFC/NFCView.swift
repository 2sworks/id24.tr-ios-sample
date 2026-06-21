//
//  NFCView.swift
//  NewTest
//
//  NFC okuma ekrani - nfc_front (sabit on) + nfc_back (arkada pulse animasyonlu).
//  Sheet acildiginda NFCView manüel .blur(radius:) ile bulaniklasiyor.
//

import SwiftUI

// MARK: - NFCView

struct NFCView: View {

    @StateObject private var viewModel = NFCViewModel()
    @EnvironmentObject private var appState: AppStateViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var pulseActive: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            (colorScheme == .dark ? IDColor.darkBg : IDColor.primary).ignoresSafeArea()
            VStack(spacing: 0) {
                SDKNavigationBar(
                    style: .overlay,
                    onBack: { appState.popBack() },
                    onHelp: {}
                )
                cardArea
            }
        }
        .blur(radius: viewModel.showEditScreen ? 8 : 0)
        .animation(.easeInOut(duration: 0.25), value: viewModel.showEditScreen)
        .overlay { loadingOverlay }
        .sheet(isPresented: $viewModel.showEditScreen) {
            if #available(iOS 16.0, *) {
                NFCEditView(viewModel: viewModel, appState: appState)
                    .presentationDetents([.height(550)])
            } else {
                NFCEditView(viewModel: viewModel, appState: appState)
            }
        }
        .onAppear { pulseActive = true }
        .onDisappear { pulseActive = false }
    }

    // MARK: - Card Area

    private var cardArea: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: IDSpacing.xl) {
                    titleBlock
                    cardIllustration
                        .frame(maxWidth: .infinity, alignment: .center)
                    VStack(alignment: .center, spacing: IDSpacing.sm) {
                        Text("NFC Tarama")
                            .font(IDFont.displayMedium(.semibold))
                            .foregroundColor(.white)
                        Text("NFC Okutma işlemi için lütfen kimlik kartınızı telefonunuzun önüne tutunuz.")
                            .font(IDFont.bodyRegular(.regular))
                            .foregroundColor(.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity)
                    statusBlock
                }
                .padding(.top, IDSpacing.xxl)
                .padding(.bottom, IDSpacing.xl)
                .padding(.horizontal, IDSpacing.lg)
            }
            SDKButton(
                title: SDKLangManager.shared.translate(.nfcStart),
                style: .secondary,
                isLoading: viewModel.isLoading
            ) {
                viewModel.startNFC(appState: appState)
            }
            .padding(.horizontal, IDSpacing.lg)
            .padding(.bottom, IDSpacing.xxl)
        }
        .background(colorScheme == .dark ? IDColor.darkBg : IDColor.primary)
        .clipShape(RoundedRectangle(cornerRadius: IDRadius.card))
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Illustration

    private var cardIllustration: some View {
        ZStack {
            Image(.nfcBack)
                .resizable()
                .scaledToFill()
                .frame(width: 200, height: 300)
                .scaleEffect(pulseActive ? 1.08 : 0.96)
                .opacity(pulseActive ? 0.55 : 0.95)
                .animation(
                    .easeInOut(duration: 1.4).repeatForever(autoreverses: true),
                    value: pulseActive
                )

            Image(.nfcFront)
                .resizable()
                .scaledToFill()
                .frame(width: 200, height: 300)
                .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 10)
                .padding(.trailing, IDSpacing.lg)
        }
        .frame(width: 300, height: 300)
    }

    // MARK: - Title Block

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: IDSpacing.sm) {
            Text(.nfcInfoTitle)
                .font(IDFont.displayMedium(.semibold))
                .foregroundColor(.white)
            Text(.nfcInfoDesc)
                .font(IDFont.bodyRegular(.regular))
                .foregroundColor(.white.opacity(0.75))
                .lineSpacing(4)
        }
    }

    // MARK: - Status Block

    @ViewBuilder
    private var statusBlock: some View {
        if !viewModel.nfcStatus.isEmpty {
            Text(viewModel.nfcStatus)
                .font(IDFont.bodySmall(.medium))
                .foregroundColor(
                    viewModel.nfcCompleted
                        ? IDColor.successBright
                        : .white.opacity(0.75)
                )
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        if let msg = viewModel.errorMessage {
            Text(msg)
                .font(IDFont.caption(.regular))
                .foregroundColor(IDColor.error)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Loading Overlay

    @ViewBuilder
    private var loadingOverlay: some View {
        if viewModel.isLoading {
            Color.black.opacity(0.45).ignoresSafeArea()
            ProgressView().tint(.white).scaleEffect(1.3)
        }
    }
}

// MARK: - NFC Manuel Duzeltme Sheet

struct NFCEditView: View {

    @ObservedObject var viewModel: NFCViewModel
    let appState: AppStateViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var birthDateText: String = ""
    @State private var validDateText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            sheetHeader
            VStack(alignment: .leading, spacing: IDSpacing.xl) {
                titleBlock
                formBlock
            }
            .padding(.top, IDSpacing.xl)
            .padding(.horizontal, IDSpacing.lg)
            Spacer()
            saveButton
                .padding(.horizontal, IDSpacing.lg)
                .padding(.bottom, IDSpacing.xxl)
        }
        .background(IDColor.adaptiveBackground(for: colorScheme).ignoresSafeArea())
        .onAppear {
            birthDateText = viewModel.birthDate.mrzToNormalDate()
            validDateText = viewModel.validDate.mrzToNormalDate()
        }
    }

    // MARK: - Sheet Header

    private var sheetHeader: some View {
        HStack {
            Spacer().frame(width: 32)
            Spacer()
            Text(.nfcEditInfoTitle)
                .font(IDFont.bodyMedium(.semibold))
                .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(IDColor.adaptiveSurface(for: colorScheme)))
            }
        }
        .padding(.horizontal, IDSpacing.lg)
        .padding(.top, IDSpacing.lg)
        .padding(.bottom, IDSpacing.md)
    }

    // MARK: - Title Block

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: IDSpacing.sm) {
            Text(.nfcKeyErrTitle)
                .font(IDFont.bodyMedium(.semibold))
                .foregroundColor(IDColor.error)
            Text(.nfcKeyErrSubTitle)
                .font(IDFont.bodyRegular(.regular))
                .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                .lineSpacing(4)
        }
    }

    // MARK: - Form Block

    private var formBlock: some View {
        VStack(alignment: .leading, spacing: IDSpacing.lg) {
            fieldGroup(title: SDKLangManager.shared.translate(.nfcSerialNo)) {
                NFCStyledTextField(
                    placeholder: "A32R17869",
                    text: $viewModel.serialNo,
                    keyboardType: .asciiCapable
                )
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)
            }
            fieldGroup(title: SDKLangManager.shared.translate(.nfcBirthDate)) {
                NFCStyledTextField(
                    placeholder: "dd.MM.yyyy",
                    text: $birthDateText,
                    keyboardType: .numbersAndPunctuation
                )
                .disableAutocorrection(true)
            }
            fieldGroup(title: SDKLangManager.shared.translate(.nfcExpDate)) {
                NFCStyledTextField(
                    placeholder: "dd.MM.yyyy",
                    text: $validDateText,
                    keyboardType: .numbersAndPunctuation
                )
                .disableAutocorrection(true)
            }
        }
    }

    @ViewBuilder
    private func fieldGroup<Content: View>(
        title: String,
        @ViewBuilder _ content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: IDSpacing.sm) {
            Text(title)
                .font(IDFont.bodySmall(.medium))
                .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
            content()
        }
    }

    // MARK: - Save Button

    private var canSave: Bool {
        !viewModel.serialNo.isEmpty && !birthDateText.isEmpty && !validDateText.isEmpty
    }

    private func save() {
        viewModel.birthDate = birthDateText.toMrzDate()
        viewModel.validDate = validDateText.toMrzDate()
        viewModel.saveManualDates(appState: appState)
    }

    private var saveButton: some View {
        Button(action: { save() }) {
            Text("Güncelle")
                .font(IDFont.bodyRegular(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(canSave ? IDColor.inkDarkest : IDColor.inkDarkest.opacity(0.35))
                .clipShape(Capsule())
        }
        .disabled(!canSave)
        .animation(.easeInOut(duration: 0.2), value: canSave)
    }
}

// MARK: - StyledTextField (NFC module local)

private struct NFCStyledTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack(alignment: .leading) {
            Text(placeholder)
                .font(IDFont.bodySmall())
                .foregroundColor(IDColor.inkLight)
                .allowsHitTesting(false)
                .opacity(text.isEmpty ? 1 : 0)
            TextField("", text: $text)
                .font(IDFont.bodySmall())
                .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                .keyboardType(keyboardType)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, IDSpacing.lg)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: IDRadius.md)
                .fill(IDColor.adaptiveSurface(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: IDRadius.md)
                        .stroke(IDColor.inkBorder, lineWidth: 1)
                )
        )
    }
}

#Preview {
    NFCView()
        .environmentObject(AppStateViewModel())
}
