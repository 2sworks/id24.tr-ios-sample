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
                headerArea
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

    // MARK: - Header

    private var headerArea: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .leading) {
                HStack(spacing: 10) {
                    Image(colorScheme == .dark ? "ic_lang_button_dark" : "ic_lang_button_light")
                        .frame(width: 44, height: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Kimlik Doğrulama")
                            .font(IDFont.bodyMedium(.semibold))
                            .foregroundColor(.white)
                        Text(.popNFC)
                            .font(IDFont.caption(.regular))
                            .foregroundColor(.white.opacity(0.75))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)

                Button(action: { dismiss() }) {
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
                            .font(IDFont.body(.regular))
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
            primaryButton
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
                .font(IDFont.body(.regular))
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

    // MARK: - Primary Button

    private var primaryButton: some View {
        Button(action: { viewModel.startNFC(appState: appState) }) {
            Text(.nfcStart)
                .font(IDFont.body(.semibold))
                .foregroundColor(IDColor.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    viewModel.isLoading
                        ? Color.white.opacity(0.35)
                        : Color.white
                )
                .clipShape(Capsule())
        }
        .disabled(viewModel.isLoading)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
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
                .font(IDFont.body(.regular))
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
                .font(IDFont.body(.semibold))
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
