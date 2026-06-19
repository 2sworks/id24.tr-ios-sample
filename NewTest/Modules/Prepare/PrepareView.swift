//
//  PrepareView.swift
//  NewTest
//
//  Hazirlik ekrani — iki state + dark mode + Inter font
//

import SwiftUI

struct PrepareView: View {

    @StateObject private var viewModel = PrepareViewModel()
    @EnvironmentObject private var appState: AppStateViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var hasID = false
    @State private var isAlone = false
    @State private var hasGoodConditions = false

    private var isSpeedTestDone: Bool {
        viewModel.speedCheckDone
    }

    private var showSuccessBanner: Bool {
        viewModel.speedCheckDone && viewModel.connectionQuality == .good
    }

    private var canProceedFull: Bool {
        viewModel.cameraAuthorized && viewModel.micAuthorized && viewModel.speechAuthorized
            && hasID && isAlone && hasGoodConditions
    }

    var body: some View {
        ZStack(alignment: .top) {
            (colorScheme == .dark ? IDColor.darkBg : IDColor.primary).ignoresSafeArea()
            VStack(spacing: 0) {
                headerArea
                cardArea
            }
        }
        .successBanner("Bağlantı için uygun internet hızına sahipsiniz.", isVisible: showSuccessBanner)
        .alert("İzin Gerekli", isPresented: $viewModel.showSettingsAlert) {
            Button("Ayarlar") { viewModel.settingsOpenAction?() }
            Button("İptal", role: .cancel) {}
        } message: {
            Text(viewModel.settingsAlertMessage)
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
                        Text("Test etmek istediğiniz ortamı seçin")
                            .font(IDFont.caption(.regular))
                            .foregroundColor(.white.opacity(0.75))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)

                Button(action: {}) {
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
                        .fill(i < 2 ? Color.white : Color.white.opacity(0.35))
                        .frame(maxWidth: .infinity)
                        .frame(height: 6)
                }
            }
            .padding(.horizontal, IDSpacing.lg)

            if viewModel.isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                    Text("Bağlantı hızı ölçülüyor...")
                        .font(IDFont.caption(.regular))
                        .foregroundColor(.white.opacity(0.85))
                }
            }
        }
        .padding(.top, IDSpacing.sm)
        .padding(.bottom, IDSpacing.lg)
    }

    // MARK: - Kart Alan

    private var cardArea: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: IDSpacing.xl) {
                    titleSection
                    permissionList
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

    // MARK: - Baslik

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: IDSpacing.sm) {
            Text(isSpeedTestDone
                 ? "Hangi belgeyi kullanacaksınız?"
                 : "Hazırlık Listesi")
                .font(IDFont.displayMedium(.semibold))
                .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))

            Text(isSpeedTestDone
                 ? "Adınızı ve mevcut adresinizi gösteren bir belge kullanın. Nerede yaşadığınızı doğrulamak için yükleyin."
                 : "Lütfen kimlik doğrulama sürecine başlamadan önce aşağıdaki izinleri verdiğinizden emin olun.")
                .font(IDFont.bodyRegular(.regular))
                .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                .lineSpacing(4)
        }
    }

    // MARK: - Izin Listesi

    private var permissionList: some View {
        VStack(spacing: IDSpacing.sm) {
            PreparePermissionRow(
                icon: "ic_camera", sf: "camera",
                title: "Canlı görüşme için kamera izni",
                isChecked: viewModel.cameraAuthorized
            ) { viewModel.checkCamera() }

            PreparePermissionRow(
                icon: "ic_microphone", sf: "mic",
                title: "Mikrofon izni",
                isChecked: viewModel.micAuthorized
            ) { viewModel.checkMicrophone() }

            PreparePermissionRow(
                icon: "ic_ear", sf: "ear",
                title: "Ses tanıma izni",
                isChecked: viewModel.speechAuthorized
            ) { viewModel.checkSpeech() }

            PreparePermissionRow(
                icon: "ic_id_card", sf: "menucard",
                title: "Kimliğim yanımda",
                isChecked: hasID
            ) { hasID.toggle() }

            PreparePermissionRow(
                icon: "ic_user_dashed", sf: "person.crop.circle.dashed",
                title: "Kimlik doğrulamak için tek başımayım",
                isChecked: isAlone
            ) { isAlone.toggle() }

            PreparePermissionRow(
                icon: "ic_lightbulb", sf: "lightbulb",
                title: "Uygun ışık ve ses koşullarındayım",
                isChecked: hasGoodConditions
            ) { hasGoodConditions.toggle() }
        }
    }

    // MARK: - Devam Butonu

    private var continueButton: some View {
        Button(action: {
            viewModel.completePrepare(appState: appState)
        }) {
            Text(isSpeedTestDone ? "Devam Et" : "Bağlantı Kalitemi Ölç ve Devam Et")
                .font(IDFont.bodyRegular(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(canProceedFull ? IDColor.primary : IDColor.primary.opacity(0.35))
                .clipShape(Capsule())
        }
        .disabled(!canProceedFull)
        .animation(.easeInOut(duration: 0.2), value: canProceedFull)
    }

    // MARK: - Identify Logo

    private var identifyLogoView: some View {
        ZStack {
            Image(colorScheme == .dark ? "ic_lang_button_dark" : "ic_lang_button_light")
                .frame(width: 44, height: 44)
        }
    }
}

struct PreparePermissionRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let icon: String
    let sf: String
    let title: String
    let isChecked: Bool
    let action: () -> Void

    private var uncheckedCheckboxColor: Color {
        colorScheme == .dark ? Color(hex: "#3A3A5C") : Color(hex: "#D9D9D9")
    }

    private var rowIcon: AnyView {
        if UIImage(named: icon) != nil {
            AnyView(Image(icon).renderingMode(.template).resizable().scaledToFit())
        } else {
            AnyView(Image(systemName: sf))
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                rowIcon
                    .font(.system(size: 16))
                    .foregroundColor(isChecked ? .white : IDColor.inkLight)
                    .frame(width: 24, height: 24)

                Text(title)
                    .font(IDFont.bodyRegular(.regular))
                    .foregroundColor(isChecked ? .white : IDColor.inkLight)
                    .multilineTextAlignment(.leading)

                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isChecked ? Color.white : uncheckedCheckboxColor)
                        .frame(width: 20, height: 20)
                    if isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(IDColor.primary)
                    }
                }
            }
            .padding(.horizontal, IDSpacing.lg)
            .frame(minHeight: 48)
            .background(
                RoundedRectangle(cornerRadius: IDRadius.md)
                    .fill(isChecked ? IDColor.primary : uncheckedCheckboxColor.opacity(0.6))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PrepareView()
        .environmentObject(AppStateViewModel())
}

#Preview("Permission Row") {
    VStack(spacing: 12) {
        PreparePermissionRow(
            icon: "ic_camera", sf: "camera",
            title: "Canlı görüşme için kamera izni",
            isChecked: false
        ) {}
        PreparePermissionRow(
            icon: "ic_microphone", sf: "mic",
            title: "Mikrofon izni",
            isChecked: true
        ) {}
        PreparePermissionRow(
            icon: "ic_id_card", sf: "menucard",
            title: "Kimliğim yanımda",
            isChecked: false
        ) {}
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
