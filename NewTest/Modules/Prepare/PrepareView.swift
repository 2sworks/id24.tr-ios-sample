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
                SDKNavigationBar(
                    style: .progress(steps: 4, current: 2),
                    title: "Kimlik Doğrulama",
                    subtitle: "Test etmek istediğiniz ortamı seçin",
                    onBack: {}
                )

                if viewModel.isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        Text("Bağlantı hızı ölçülüyor...")
                            .font(IDFont.caption(.regular))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .padding(.bottom, IDSpacing.sm)
                }

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
                .foregroundColor(IDColor.adaptiveSubtitleContent(for: colorScheme))
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
        SDKButton(
            title: isSpeedTestDone ? "Devam Et" : "Bağlantı Kalitemi Ölç ve Devam Et",
            isDisabled: !canProceedFull
        ) {
            viewModel.completePrepare(appState: appState)
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
        colorScheme == .dark ? IDColor.darkMuted : IDColor.divider
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
                    .foregroundColor(
                        isChecked ? IDColor.primaryLight : colorScheme == .dark ? IDColor.primaryLight : IDColor.darkMuted
                    )
                    .frame(width: 24, height: 24)

                Text(title)
                    .font(IDFont.bodyRegular(.regular))
                    .foregroundColor(
                        isChecked ? IDColor.primaryLight : colorScheme == .dark ? IDColor.primaryLight : IDColor.darkMuted
                    )
                    .multilineTextAlignment(.leading)

                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isChecked ? IDColor.primaryLight : uncheckedCheckboxColor)
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
                    .fill(isChecked ? IDColor.primary : uncheckedCheckboxColor.opacity(0.2))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PrepareView()
        .environmentObject(AppStateViewModel())
}
