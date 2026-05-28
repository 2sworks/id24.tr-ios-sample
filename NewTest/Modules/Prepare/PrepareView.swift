//
//  PrepareView.swift
//  NewTest
//
//  Hazirlik ekrani - TASARIM KULLANICI TARAFINDAN DOLDURULACAK.
//
//  --- KULLANIM REHBERI ---
//
//  IZIN DURUMLARI:
//    viewModel.cameraAuthorized    -> kamera izni
//    viewModel.micAuthorized       -> mikrofon izni
//    viewModel.speechAuthorized    -> konusma izni
//    viewModel.allPermissionsGranted -> tumu tamam mi
//
//  HIZ TESTİ:
//    viewModel.speedCheckDone      -> tamamlandi mi
//    viewModel.measuredSpeed       -> kbps degeri
//    viewModel.connectionQuality   -> 0=zayif, 1=orta, 2=iyi
//    viewModel.startSpeedTest()    -> yeniden test baslatir
//
//  DEVAM:
//    viewModel.canProceed          -> devam butonu aktif mi
//    viewModel.completePrepare(appState:) -> modulu tamamlar + sonrakine gecer
//
//  YUKLEME:
//    viewModel.isLoading           -> hiz testi suresi
//

import SwiftUI

struct PrepareView: View {

    @StateObject private var viewModel = PrepareViewModel()
    @EnvironmentObject private var appState: AppStateViewModel

    @State private var hasID = false
    @State private var isAlone = false
    @State private var hasGoodConditions = false

    private var canProceedFull: Bool {
        viewModel.canProceed && hasID && isAlone && hasGoodConditions
    }

    var body: some View {
        ZStack(alignment: .top) {
            IDColor.primary.ignoresSafeArea()
            VStack(spacing: 0) {
                headerArea
                whiteCard
            }
        }
    }

    // MARK: - Header

    private var headerArea: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .leading) {
                // Ortada baslik + alt baslik
                VStack(spacing: 2) {
                    Text("Kimlik Doğrulama")
                        .font(IDFont.bodyMedium(.medium))
                        .foregroundColor(.white)
                    Text("Test etmek istediğiniz ortamı seçin")
                        .font(IDFont.bodySmall(.regular))
                        .foregroundColor(.white.opacity(0.75))
                }
                .frame(maxWidth: .infinity)

                // Sol: geri + dil butonu
                HStack(spacing: 8) {
                    Button(action: {}) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                    }
                    Button(action: {}) {
                        prepareIcon("ic_lang_button_dark", sf: "globe")
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(Color.white.opacity(0.2)))
                    }
                }
            }
            .padding(.horizontal, IDSpacing.lg)

            // 4 adim ilerleme: 2 aktif (beyaz), 2 pasif (yari saydam)
            HStack(spacing: 6) {
                ForEach(0..<4) { i in
                    Capsule()
                        .fill(i < 2 ? Color.white : Color.white.opacity(0.35))
                        .frame(width: 87, height: 6)
                }
            }

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

    // MARK: - Beyaz Kart

    private var whiteCard: some View {
        VStack(spacing: 0) {
            if viewModel.speedCheckDone && viewModel.connectionQuality == .good {
                speedSuccessBanner
                    .padding(.horizontal, IDSpacing.lg)
                    .padding(.top, IDSpacing.lg)
            }

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
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: IDRadius.card))
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Baslik

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: IDSpacing.sm) {
            Text("Hazırlık Listesi")
                .font(IDFont.displayMedium(.semibold))
                .foregroundColor(IDColor.inkDark)

            Text("Lütfen kimlik doğrulama sürecine başlamadan önce aşağıdaki izinleri verdiğinizden emin olun.")
                .font(IDFont.body(.regular))
                .foregroundColor(IDColor.inkLight)
                .lineSpacing(4)
        }
    }

    // MARK: - Izin Listesi

    private var permissionList: some View {
        VStack(spacing: IDSpacing.sm) {
            PreparePermissionRow(
                icon: "ic_camera", sf: "camera.fill",
                title: "Canlı görüşme için kamera izni",
                isChecked: viewModel.cameraAuthorized
            ) { viewModel.checkCamera() }

            PreparePermissionRow(
                icon: "ic_microphone", sf: "mic.fill",
                title: "Mikrofon izni",
                isChecked: viewModel.micAuthorized
            ) { viewModel.checkMicrophone() }

            PreparePermissionRow(
                icon: "ic_ear", sf: "ear",
                title: "Ses tanıma izni",
                isChecked: viewModel.speechAuthorized
            ) { viewModel.checkSpeech() }

            PreparePermissionRow(
                icon: "ic_id_card", sf: "creditcard.fill",
                title: "Kimliğim yanımda",
                isChecked: hasID
            ) { hasID.toggle() }

            PreparePermissionRow(
                icon: "ic_user_dashed", sf: "person.crop.circle.dashed",
                title: "Kimlik doğrulamak için tek başımayım",
                isChecked: isAlone
            ) { isAlone.toggle() }

            PreparePermissionRow(
                icon: "ic_lightbulb", sf: "lightbulb.fill",
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
            Text("Bağlantı Kalitemi Ölç ve Devam Et")
                .font(IDFont.body(.regular))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(canProceedFull ? IDColor.primary : IDColor.primary.opacity(0.35))
                .clipShape(Capsule())
        }
        .disabled(!canProceedFull)
        .animation(.easeInOut(duration: 0.2), value: canProceedFull)
    }

    // MARK: - Hiz Testi Basari Bildirimi

    private var speedSuccessBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: IDRadius.sm)
                    .fill(IDColor.success.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(IDColor.success)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Başarılı")
                    .font(IDFont.body(.semibold))
                    .foregroundColor(IDColor.success)
                Text("Bağlantı için uygun internet hızına sahipsiniz.")
                    .font(IDFont.caption(.regular))
                    .foregroundColor(IDColor.success)
            }
            Spacer()
        }
        .padding(10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: IDRadius.lg))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Yardimci: Assets'te PDF varsa kullan, yoksa SF Symbol

@ViewBuilder
private func prepareIcon(_ name: String, sf: String) -> some View {
    if UIImage(named: name) != nil {
        Image(name)
            .resizable()
            .scaledToFit()
    } else {
        Image(systemName: sf)
    }
}

// MARK: - Permission Row Bileseni

private struct PreparePermissionRow: View {
    let icon: String
    let sf: String
    let title: String
    let isChecked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                prepareIcon(icon, sf: sf)
                    .font(.system(size: 16))
                    .foregroundColor(isChecked ? .white : IDColor.inkLight)
                    .frame(width: 24, height: 24)

                Text(title)
                    .font(IDFont.body(.regular))
                    .foregroundColor(isChecked ? .white : IDColor.inkLight)
                    .multilineTextAlignment(.leading)

                Spacer()

                // Figma: r=6 yuvarlak kare checkbox, checked=beyaz+mavi tick, unchecked=gri
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isChecked ? Color.white : Color(hex: "#D9D9D9"))
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
                    .fill(isChecked ? IDColor.primary : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PrepareView()
        .environmentObject(AppStateViewModel())
}
