//
//  LoginView.swift
//  NewTest
//

import SwiftUI
import IdentifySDK

// MARK: - HamburgerMenuItem

private enum HamburgerMenuItem {
    case serverList, moduleList
}

// MARK: - LoginMode

enum LoginMode: CaseIterable {
    case yeniMusteri, identId

    var title: String {
        switch self {
        case .yeniMusteri: return "Yeni Müşteri"
        case .identId:     return "Ident ID"
        }
    }
}

// MARK: - LoginView

struct LoginView: View {

    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject private var appState: AppStateViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var loginMode: LoginMode = .identId
    @State private var showOptions = false
    @State private var showServerList = false
    @State private var showModuleList = false
    @State private var showHamburgerMenu = false
    @State private var showLangPicker = false
    @State private var pendingNavigation: HamburgerMenuItem? = nil
    @State private var pendingConnect = false

    var body: some View {
        ZStack {
            IDColor.adaptiveBackground(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                SDKNavigationBar(
                    style: .login,
                    onMenu: { showHamburgerMenu = true },
                    trailing: AnyView(langFlagButton)
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: IDSpacing.xl) {
                        LoginHeroSection()

                        LoginTabSelector(selected: $loginMode)

                        if loginMode == .identId {
                            IdentIdFormView(identId: $viewModel.identId)
                        } else {
                            YeniMusteriFormView(viewModel: viewModel)
                        }

                        OptionsExpandButton { showOptions = true }
                    }
                    .padding(.horizontal, IDSpacing.lg)
                    .padding(.top, IDSpacing.xl)
                    .padding(.bottom, IDSpacing.lg)
                }

                VStack(spacing: IDSpacing.lg) {
                    SDKButton(
                        title: "Hemen Bağlan",
                        isLoading: appState.isLoading,
                        isDisabled: isConnectDisabled,
                        action: connect
                    )
                    Text("Build No: \(viewModel.buildNumber)")
                        .font(IDFont.caption())
                        .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                }
                .padding(.horizontal, IDSpacing.lg)
                .padding(.vertical, IDSpacing.lg)
            }
        }
        .ignoresSafeArea(.keyboard)
        .navigationBarHidden(true)
        .overlay {
            if appState.isLoading {
                Color.black.opacity(0.45).ignoresSafeArea()
                ProgressView().scaleEffect(1.5).tint(.white)
            }
        }
        .alert("Hata", isPresented: Binding(
            get: { appState.sdkError != nil },
            set: { if !$0 { appState.sdkError = nil } }
        )) {
            Button("Tamam") { appState.sdkError = nil }
        } message: {
            Text(appState.sdkError ?? "")
        }
        .sheet(isPresented: $showOptions) {
            if #available(iOS 16.4, *) {
                OptionsBottomSheet(viewModel: viewModel)
                    .presentationDetents([.height(300)])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(.ultraThinMaterial)
            } else if #available(iOS 16.0, *) {
                OptionsBottomSheet(viewModel: viewModel)
                    .presentationDetents([.height(300)])
                    .presentationDragIndicator(.visible)
            } else {
                OptionsBottomSheet(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showServerList, onDismiss: {
            viewModel.loadSavedServers()
            if pendingConnect {
                pendingConnect = false
                if viewModel.hasUserSelectedServer {
                    viewModel.connect(appState: appState)
                }
            }
        }) {
            ServerListView(viewModel: viewModel)
        }
        .sheet(isPresented: $showModuleList) {
            ModuleListView(viewModel: viewModel)
        }
        .sheet(isPresented: $showLangPicker) {
            if #available(iOS 16.4, *) {
                LanguagePickerSheet(current: viewModel.selectedSDKLang) { lang in
                    viewModel.setSDKLanguage(lang)
                }
                .presentationDetents([.height(360)])
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThinMaterial)
            } else if #available(iOS 16.0, *) {
                LanguagePickerSheet(current: viewModel.selectedSDKLang) { lang in
                    viewModel.setSDKLanguage(lang)
                }
                .presentationDetents([.height(360)])
                .presentationDragIndicator(.visible)
            } else {
                LanguagePickerSheet(current: viewModel.selectedSDKLang) { lang in
                    viewModel.setSDKLanguage(lang)
                }
            }
        }
        .sheet(isPresented: $showHamburgerMenu, onDismiss: {
            switch pendingNavigation {
            case .serverList: showServerList = true
            case .moduleList: showModuleList = true
            case nil: break
            }
            pendingNavigation = nil
        }) {
            if #available(iOS 16.4, *) {
                HamburgerMenuSheet { item in
                    pendingNavigation = item
                    showHamburgerMenu = false
                }
                .presentationDetents([.height(200)])
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThinMaterial)
            } else if #available(iOS 16.0, *) {
                HamburgerMenuSheet { item in
                    pendingNavigation = item
                    showHamburgerMenu = false
                }
                .presentationDetents([.height(200)])
                .presentationDragIndicator(.visible)
            } else {
                HamburgerMenuSheet { item in
                    pendingNavigation = item
                    showHamburgerMenu = false
                }
            }
        }
    }

    private var langFlagButton: some View {
        Button { showLangPicker = true } label: {
            ZStack {
                Circle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color(.systemGray6))
                    .overlay(Circle().stroke(
                        colorScheme == .dark ? Color.white.opacity(0.08) : Color(.systemGray4),
                        lineWidth: 1
                    ))
                Image(viewModel.selectedSDKLang.flagImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 24, height: 24)
                    .clipShape(Circle())
            }
            .frame(width: 48, height: 48)
        }
        .buttonStyle(.plain)
    }

    private var isConnectDisabled: Bool {
        appState.isLoading || (loginMode == .identId ? viewModel.identId.isEmpty : viewModel.firstName.isEmpty)
    }

    private func connect() {
        guard viewModel.hasUserSelectedServer else {
            pendingConnect = true
            showServerList = true
            return
        }
        viewModel.connect(appState: appState)
    }
}

// MARK: - LanguagePickerSheet

private struct LanguagePickerSheet: View {
    let current: SDKLang
    let onSelect: (SDKLang) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private static let languages: [SDKLang] = [.tr, .eng, .de, .az, .ru]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Dil Seçimi")
                    .font(IDFont.bodyLarge(.semibold))
                    .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                        .frame(width: 30, height: 30)
                }
            }
            .padding(.horizontal, IDSpacing.xl)
            .padding(.top, IDSpacing.lg)
            .padding(.bottom, IDSpacing.md)

            VStack(spacing: IDSpacing.sm) {
                ForEach(Self.languages, id: \.self) { lang in
                    LangOptionRow(lang: lang, isSelected: current == lang) {
                        onSelect(lang)
                        dismiss()
                    }
                }
            }
            .padding(.horizontal, IDSpacing.xl)

            Spacer()
        }
        .background(IDColor.adaptiveBackground(for: colorScheme).ignoresSafeArea())
    }
}

// MARK: - LangOptionRow

private struct LangOptionRow: View {
    let lang: SDKLang
    let isSelected: Bool
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: IDSpacing.md) {
                Image(lang.flagImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())

                Text(lang.displayName)
                    .font(IDFont.bodyRegular())
                    .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(IDColor.primary)
                }
            }
            .padding(.horizontal, IDSpacing.lg)
            .padding(.vertical, IDSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: IDRadius.md)
                    .fill(IDColor.adaptiveSurface(for: colorScheme))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - LoginHeroSection

private struct LoginHeroSection: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: IDSpacing.lg) {
            Image(.icAppLogo)
                .renderingMode(.template)
                .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))

            VStack(spacing: IDSpacing.sm) {
                Text("Identify'a Hoş geldiniz!")
                    .font(IDFont.displayMedium())
                    .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                    .multilineTextAlignment(.center)

                Text("Kimlik doğrulama süreci boyunca iyi bir ışığa sahip olmanız, kimliğinizin yanında olması ve tek başınıza olmanız gerekir.")
                    .font(IDFont.bodySmall(.regular))
                    .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
    }
}

// MARK: - LoginTabSelector

private struct LoginTabSelector: View {
    @Binding var selected: LoginMode
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var animation

    var body: some View {
        HStack(spacing: 0) {
            ForEach(LoginMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selected = mode
                    }
                } label: {
                    Text(mode.title)
                        .font(IDFont.bodySmall(.semibold))
                        .foregroundColor(selected == mode ? .white : IDColor.adaptiveTitle(for: colorScheme))
                        .frame(width: 104, height: 30)
                        .background(
                            ZStack {
                                if selected == mode {
                                    Capsule()
                                        .fill(IDColor.primary)
                                        .matchedGeometryEffect(id: "tab", in: animation)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 201, height: 46)
        .padding(.horizontal, 10)
        .background(Capsule().fill(IDColor.adaptiveSurface(for: colorScheme)))
        .overlay(
            Capsule()
                .stroke(IDColor.inkBorder.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - StyledTextField

private struct StyledTextField: View {
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
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, IDSpacing.lg)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: IDRadius.md)
                .fill(IDColor.adaptiveSurface(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: IDRadius.md)
                        .stroke(IDColor.inkBorder.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - IdentIdFormView

private struct IdentIdFormView: View {
    @Binding var identId: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: IDSpacing.sm) {
            StyledTextField(placeholder: "Ident ID", text: $identId)
                .overlay(alignment: .trailing) {
                    if !identId.isEmpty {
                        Button { identId = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(IDColor.inkLight)
                                .padding(.trailing, IDSpacing.md)
                        }
                        .buttonStyle(.plain)
                    }
                }

            Button {
                if let copied = UIPasteboard.general.string {
                    identId = copied
                }
            } label: {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(IDColor.primary)
                    .frame(width: 44)
                    .frame(maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: IDRadius.md)
                            .fill(IDColor.adaptiveSurface(for: colorScheme))
                            .overlay(
                                RoundedRectangle(cornerRadius: IDRadius.md)
                                    .stroke(IDColor.inkBorder.opacity(0.15), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - YeniMusteriFormView

private struct YeniMusteriFormView: View {
    @ObservedObject var viewModel: LoginViewModel

    var body: some View {
        VStack(spacing: IDSpacing.sm) {
            HStack(spacing: IDSpacing.sm) {
                StyledTextField(placeholder: "Adınız", text: $viewModel.firstName)
                StyledTextField(placeholder: "Soyadınız", text: $viewModel.lastName)
            }

            StyledTextField(
                placeholder: "T.C. Kimlik Numaranız",
                text: $viewModel.tcNo,
                keyboardType: .numberPad
            )

            StyledTextField(placeholder: "Kimlik Seri Numarası", text: $viewModel.serialNo)

            HStack(spacing: IDSpacing.sm) {
                StyledTextField(
                    placeholder: "Doğum Tarihi",
                    text: $viewModel.birthDate,
                    keyboardType: .numbersAndPunctuation
                )
                StyledTextField(
                    placeholder: "Son Geçerlilik Tarihi",
                    text: $viewModel.expiryDate,
                    keyboardType: .numbersAndPunctuation
                )
            }

            ProjectPickerField(selected: $viewModel.selectedProject)
        }
    }
}

// MARK: - ProjectPickerField

private struct ProjectPickerField: View {
    @Binding var selected: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            Text(selected.isEmpty ? "Proje Seçimi" : selected)
                .font(IDFont.bodySmall())
                .foregroundColor(selected.isEmpty ? IDColor.inkLight : IDColor.adaptiveTitle(for: colorScheme))
            Spacer()
            Image(systemName: "chevron.down")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(IDColor.inkLight)
        }
        .padding(.horizontal, IDSpacing.lg)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: IDRadius.md)
                .fill(IDColor.adaptiveSurface(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: IDRadius.md)
                        .stroke(IDColor.inkBorder.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - OptionsExpandButton

private struct OptionsExpandButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: IDSpacing.xs) {
                Text("Seçenekleri Göster")
                    .font(IDFont.bodySmall(.semibold))
                    .foregroundColor(IDColor.primary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(IDColor.primary)
            }
        }
    }
}

// MARK: - OptionsBottomSheet

struct OptionsBottomSheet: View {
    @ObservedObject var viewModel: LoginViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Seçenekleri Yönet")
                    .font(IDFont.bodyLarge(.semibold))
                    .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                        .frame(width: 30, height: 30)
                }
            }
            .padding(.horizontal, IDSpacing.xl)
            .padding(.top, IDSpacing.lg)
            .padding(.bottom, IDSpacing.md)

            VStack {
                ToggleOptionRow(title: "Temsilci yayını büyük görünsün", isOn: $viewModel.useBigCustomerCam)
                Divider()
                ToggleOptionRow(title: "İşaret dili seçeneği aktif olsun", isOn: $viewModel.useSignLang)
                Divider()
                ToggleOptionRow(title: "Yeni canlılık testi ekranını dene", isOn: $viewModel.useNewLiveness)
                Divider()
                ToggleOptionRow(title: "SSL Pinning", isOn: $viewModel.useSSLPinning)
            }
            .background(
                RoundedRectangle(cornerRadius: IDRadius.md)
                    .fill(IDColor.adaptiveSurface(for: colorScheme))
            )
            .padding(.horizontal, IDSpacing.xl)

            Spacer()
        }
        .background(IDColor.adaptiveBackground(for: colorScheme).ignoresSafeArea())
    }
}

// MARK: - ToggleOptionRow

private struct ToggleOptionRow: View {
    let title: String
    @Binding var isOn: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(IDFont.bodyRegular())
                    .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                Spacer()
                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(IDColor.primary)
            }
            .padding(.horizontal, IDSpacing.xl)
            .padding(.vertical, IDSpacing.sm)

            Divider()
                .padding(.leading, IDSpacing.xl)
                .opacity(0.3)
        }
    }
}

// MARK: - HamburgerMenuSheet

private struct HamburgerMenuSheet: View {
    let onSelect: (HamburgerMenuItem) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Ayarlar")
                    .font(IDFont.bodyLarge(.semibold))
                    .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                        .frame(width: 30, height: 30)
                }
            }
            .padding(.horizontal, IDSpacing.xl)
            .padding(.top, IDSpacing.lg)
            .padding(.bottom, IDSpacing.md)

            VStack(spacing: IDSpacing.sm) {
                MenuOptionRow(icon: .init(.icCubeFocus), title: "Modül Seçme Ekranı") {
                    onSelect(.moduleList)
                }
                MenuOptionRow(icon: .init(.icBugBeetle), title: "Sunucu Ayarları") {
                    onSelect(.serverList)
                }
            }
            .padding(.horizontal, IDSpacing.xl)

            Spacer()
        }
        .background(IDColor.adaptiveBackground(for: colorScheme).ignoresSafeArea())
    }
}

// MARK: - MenuOptionRow

private struct MenuOptionRow: View {
    let icon: Image
    let title: String
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: IDSpacing.md) {
                icon
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                    .frame(width: 24)
                Text(title)
                    .font(IDFont.bodyRegular())
                    .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(IDColor.inkLight)
            }
            .padding(.horizontal, IDSpacing.lg)
            .padding(.vertical, IDSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: IDRadius.md)
                    .fill(IDColor.adaptiveSurface(for: colorScheme))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ServerListView

struct ServerListView: View {
    @ObservedObject var viewModel: LoginViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            IDColor.adaptiveBackground(for: colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                SubScreenTopBar(
                    title: "Sunucu Seçimi",
                    subtitle: "Test etmek istediğiniz ortamı seçin",
                    onBack: { dismiss() }
                )

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: IDSpacing.lg) {
                        VStack(alignment: .leading, spacing: IDSpacing.sm) {
                            Text("Sunucu Listesi")
                                .font(IDFont.displaySmall(.bold))
                                .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                            Text("Bağlanmak istediğiniz sunucuyu aşağıdan seçerek devam edebilirsiniz.")
                                .font(IDFont.bodySmall())
                                .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                                .lineSpacing(3)
                        }

                        VStack(spacing: IDSpacing.sm) {
                            ForEach(viewModel.serverList) { server in
                                ServerOptionRow(
                                    server: server,
                                    isSelected: viewModel.selectedServer.id == server.id,
                                    onTap: { viewModel.selectServer(server) }
                                )
                            }
                        }
                    }
                    .padding(IDSpacing.xl)
                }

                SDKButton(title: "Devam") { dismiss() }
                    .padding(.horizontal, IDSpacing.xl)
                    .padding(.bottom, IDSpacing.xl)
            }
        }
    }
}

// MARK: - ServerOptionRow

private struct ServerOptionRow: View {
    let server: ServerOption
    let isSelected: Bool
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(server.title)
                    .font(IDFont.bodyRegular(.semibold))
                    .foregroundColor(isSelected ? .white : IDColor.adaptiveTitle(for: colorScheme))
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .white : IDColor.adaptiveSubtitle(for: colorScheme))
            }
            .padding(.horizontal, IDSpacing.lg)
            .padding(.vertical, IDSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: IDRadius.md)
                    .fill(isSelected ? IDColor.primary : IDColor.adaptiveSurface(for: colorScheme))
            )
        }
    }
}

// MARK: - ModuleListView

struct ModuleListView: View {
    
    @ObservedObject var viewModel: LoginViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var isEditing = false
    @State private var activeModules: [SdkModules] = []
    @State private var passiveModules: [SdkModules] = []

    var body: some View {
        ZStack {
            IDColor.adaptiveBackground(for: colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                SubScreenTopBar(
                    title: "Modül Seçimi",
                    subtitle: "Modül listesi aşağıdaki gibidir",
                    onBack: { dismiss() },
                    trailing: {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isEditing.toggle()
                            }
                        } label: {
                            HStack {
                                Image(.icPencilLine)
                                    .renderingMode(.template)
                                    .foregroundColor(IDColor.inkBackground)
                                
                                Text(isEditing ? "Bitti" : "Edit")
                                    .font(IDFont.bodySmall(.semibold))
                                    .foregroundColor(IDColor.inkBackground)
                            }
                            .padding(.horizontal, IDSpacing.md)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: IDRadius.pill)
                                    .foregroundStyle(IDColor.primary)
                                    
                            )
                        }
                    }
                )

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: IDSpacing.sm) {
                        Text("Aktif Modüller")
                            .font(IDFont.caption(.semibold))
                            .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                            .padding(.horizontal, IDSpacing.lg)

                        VStack(spacing: 0) {
                            ForEach(Array(activeModules.enumerated()), id: \.element) { index, module in
                                ModuleRow(
                                    module: module,
                                    isEditing: isEditing,
                                    isLast: index == activeModules.count - 1,
                                    onRemove: {
                                        withAnimation {
                                            let removed = activeModules[index]
                                            activeModules.removeSubrange(index...index)
                                            passiveModules.append(removed)
                                        }
                                    }
                                )
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: IDRadius.md)
                                .fill(IDColor.adaptiveSurface(for: colorScheme))
                        )
                        .padding(.horizontal, IDSpacing.lg)

                        Text("Değişiklikler için kaydetmeyi unutmayın aksi halde web modül listesinden devam edilir.")
                            .font(IDFont.caption())
                            .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                            .padding(.horizontal, IDSpacing.lg)
                            .padding(.top, IDSpacing.xs)

                        if !passiveModules.isEmpty {
                            Text("Pasif Modüller")
                                .font(IDFont.caption(.semibold))
                                .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                                .padding(.horizontal, IDSpacing.lg)
                                .padding(.top, IDSpacing.sm)

                            VStack(spacing: 0) {
                                ForEach(Array(passiveModules.enumerated()), id: \.element) { index, module in
                                    PassiveModuleRow(
                                        module: module,
                                        isEditing: isEditing,
                                        isLast: index == passiveModules.count - 1,
                                        onAdd: {
                                            withAnimation {
                                                passiveModules.removeSubrange(index...index)
                                                activeModules.append(module)
                                            }
                                        }
                                    )
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: IDRadius.md)
                                    .fill(IDColor.adaptiveSurface(for: colorScheme))
                            )
                            .padding(.horizontal, IDSpacing.lg)
                        }
                    }
                    .padding(.top, IDSpacing.sm)
                    .padding(.bottom, IDSpacing.lg)
                }

                SDKButton(title: "Listeyi Kaydet") {
                    viewModel.updateModules(activeModules)
                    dismiss()
                }
                .padding(.horizontal, IDSpacing.xl)
                .padding(.bottom, IDSpacing.xl)
            }
        }
        .onAppear {
            activeModules = viewModel.selectedModules.isEmpty ? viewModel.availableModules : viewModel.selectedModules
            let activeSet = Set(activeModules)
            passiveModules = viewModel.availableModules.filter { !activeSet.contains($0) }
        }
    }
}

// MARK: - ModuleRow

private struct ModuleRow: View {
    let module: SdkModules
    let isEditing: Bool
    let isLast: Bool
    let onRemove: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: IDSpacing.md) {
                if isEditing {
                    Button(action: onRemove) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(IDColor.error)
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                Text(module.displayName)
                    .font(IDFont.bodyRegular())
                    .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))

                Spacer()
            }
            .padding(.horizontal, IDSpacing.lg)
            .padding(.vertical, IDSpacing.md + 2)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isEditing)

            if !isLast {
                Divider()
                    .padding(.leading, isEditing ? IDSpacing.lg + 22 + IDSpacing.md : IDSpacing.lg)
                    .opacity(0.4)
            }
        }
    }
}

// MARK: - PassiveModuleRow

private struct PassiveModuleRow: View {
    let module: SdkModules
    let isEditing: Bool
    let isLast: Bool
    let onAdd: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: IDSpacing.md) {
                if isEditing {
                    Button(action: onAdd) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(IDColor.primary)
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                Text(module.displayName)
                    .font(IDFont.bodyRegular())
                    .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))

                Spacer()
            }
            .padding(.horizontal, IDSpacing.lg)
            .padding(.vertical, IDSpacing.md + 2)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isEditing)

            if !isLast {
                Divider()
                    .padding(.leading, isEditing ? IDSpacing.lg + 22 + IDSpacing.md : IDSpacing.lg)
                    .opacity(0.4)
            }
        }
    }
}

// MARK: - SubScreenTopBar

private struct SubScreenTopBar<Trailing: View>: View {
    let title: String
    let subtitle: String?
    let onBack: () -> Void
    let trailing: Trailing
    @Environment(\.colorScheme) private var colorScheme

    init(
        title: String,
        subtitle: String?,
        onBack: @escaping () -> Void,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.onBack = onBack
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: IDSpacing.sm) {
            Button(action: onBack) {
                Image(.icCaretLeft)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                    .frame(width: 36, height: 36)
            }

            HStack(spacing: IDSpacing.sm) {
                Image(.icLangButtonDark)
                    .resizable()
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(IDFont.bodySmall(.semibold))
                        .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                    if let subtitle {
                        Text(subtitle)
                            .font(IDFont.caption())
                            .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            trailing
        }
        .padding(.horizontal, IDSpacing.lg)
        .frame(height: 56)
    }
}

extension SubScreenTopBar where Trailing == EmptyView {
    init(title: String, subtitle: String?, onBack: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.onBack = onBack
        self.trailing = EmptyView()
    }
}

// MARK: - StepProgressBar

private struct StepProgressBar: View {
    let steps: Int
    let current: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: IDSpacing.xs) {
            ForEach(0..<steps, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index <= current ? IDColor.primary : IDColor.adaptiveSurface(for: colorScheme))
                    .frame(height: 4)
            }
        }
    }
}

// MARK: - SDKLang display helpers

private extension SDKLang {
    var flagImageName: String {
        switch self {
        case .tr:  return "turkey"
        case .eng: return "united_kingdom"
        case .de:  return "germany"
        case .az:  return "azerbaijan"
        case .ru:  return "russia"
        @unknown default: return "turkey"
        }
    }

    var displayName: String {
        switch self {
        case .tr:  return "Türkçe"
        case .eng: return "English"
        case .de:  return "Deutsch"
        case .az:  return "Azərbaycan"
        case .ru:  return "Русский"
        @unknown default: return "Türkçe"
        }
    }
}

// MARK: - SdkModules display name

extension SdkModules {
    var displayName: String {
        switch self {
        case .prepare:           return "Prepare"
        case .idCard:            return "ID Card"
        case .idcard_w_ovd:      return "ID Card OVD"
        case .nfc:               return "MRZ & NFC Screen"
        case .livenessDetection: return "Liveness Detection"
        case .speech:            return "Speech Recognition"
        case .addressConf:       return "Address Confirm"
        case .signature:         return "Signature"
        case .videoRecord:       return "Video Recorder"
        case .selfie:            return "Selfie"
        case .waitScreen:        return "Call Wait Screen"
        default:                 return rawValue
        }
    }
}

// MARK: - Preview

#Preview {
    LoginView()
        .environmentObject(AppStateViewModel())
}

#Preview("Modül Seçimi") {
    ModuleListView(viewModel: LoginViewModel())
}

#Preview("Sunucu Seçimi") {
    ServerListView(viewModel: LoginViewModel())
}
