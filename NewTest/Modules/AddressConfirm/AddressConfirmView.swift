//
//  AddressConfirmView.swift
//  NewTest
//

import SwiftUI
import IdentifySDK

struct AddressConfirmView: View {

    @StateObject private var viewModel = AddressConfirmViewModel()
    @EnvironmentObject private var appState: AppStateViewModel
    @EnvironmentObject private var coordinator: AppNavigationCoordinator
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack(alignment: .top) {
            (colorScheme == .dark ? IDColor.darkBg : IDColor.primary).ignoresSafeArea()
            VStack(spacing: 0) {
                headerArea
                cardArea
            }
        }
        .overlay {
            if viewModel.isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView().tint(.white)
            }
        }
        .overlay {
            ZStack {
                if viewModel.showDocumentOptions {
                    documentOptionsOverlay
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: viewModel.showDocumentOptions)
        }
        .documentScanner(isPresented: $viewModel.showScanner, profile: .generic, style: scannerStyle, configuration: .document) { result in
            if case .success(let doc) = result {
                viewModel.photoSelected(doc.croppedImage)
            }
        }
        .sheet(isPresented: $viewModel.showGallery) {
            ImageGalleryPickerRepresentable(
                onImage: { image in
                    viewModel.photoSelected(image)
                    viewModel.showGallery = false
                },
                onCancel: { viewModel.showGallery = false }
            )
        }
        .sheet(isPresented: $viewModel.showPDFPicker) {
            PDFDocumentPickerRepresentable(
                onURL: { url in
                    viewModel.pdfSelectedFromURL(url)
                    viewModel.showPDFPicker = false
                },
                onCancel: { viewModel.showPDFPicker = false }
            )
        }
    }

    // MARK: - Header

    private var headerArea: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .leading) {
                HStack(spacing: 10) {
                    identifyLogoView
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Adres Doğrulama")
                            .font(IDFont.bodyMedium(.semibold))
                            .foregroundColor(.white)
                        Text("Adresinizi doğrulamamıza yardımcı olun")
                            .font(IDFont.caption(.regular))
                            .foregroundColor(.white.opacity(0.75))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)

                Button(action: { coordinator.pop() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal, IDSpacing.lg)

            HStack(spacing: IDSpacing.xs) {
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

    // MARK: - Card

    private var cardArea: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleSection
                .padding(.top, IDSpacing.xl)
                .padding(.horizontal, IDSpacing.lg)

            addressEditorSection
                .padding(.top, IDSpacing.xl)
                .padding(.horizontal, IDSpacing.lg)

            documentUploadSection
                .padding(.top, IDSpacing.lg)
                .padding(.horizontal, IDSpacing.lg)

            Spacer()

            errorRow
                .padding(.horizontal, IDSpacing.lg)
                .padding(.bottom, IDSpacing.sm)

            continueButton
                .padding(.horizontal, IDSpacing.lg)
                .padding(.bottom, IDSpacing.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(IDColor.adaptiveSurface(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: IDRadius.card))
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: IDSpacing.sm) {
            Text("Adresinizi girin")
                .font(IDFont.displayMedium(.semibold))
                .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))

            Text("Kimlik tespiti için adresinizi ve bir belge fotoğrafını paylaşın")
                .font(IDFont.bodyRegular(.regular))
                .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                .lineSpacing(4)
        }
    }

    // MARK: - Address Editor

    private var addressEditorSection: some View {
        ZStack(alignment: .topLeading) {
            if viewModel.addressText.isEmpty {
                Text("Adresinizi buraya yazın...")
                    .font(IDFont.bodyRegular(.regular))
                    .foregroundColor(IDColor.inkMid.opacity(0.6))
                    .padding(.top, 9)
                    .padding(.leading, 5)
                    .allowsHitTesting(false)
            }
            addressTextEditor
        }
        .padding(.horizontal, IDSpacing.sm)
        .padding(.vertical, IDSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: 9.5)
                .fill(IDColor.inkBorder.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9.5)
                .stroke(IDColor.inkBorder, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var addressTextEditor: some View {
        if #available(iOS 16.0, *) {
            TextEditor(text: $viewModel.addressText)
                .font(IDFont.bodyRegular(.regular))
                .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                .frame(height: 93)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
        } else {
            TextEditor(text: $viewModel.addressText)
                .font(IDFont.bodyRegular(.regular))
                .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                .frame(height: 93)
                .background(Color.clear)
                .onAppear { UITextView.appearance().backgroundColor = .clear }
        }
    }

    // MARK: - Document Upload Box

    private var documentUploadSection: some View {
        Button(action: { withAnimation { viewModel.showDocumentOptions = true } }) {
            HStack(spacing: IDSpacing.lg) {
                thumbnailView

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.docPhoto != nil ? "Belge eklendi" : "Belge Yükle")
                        .font(IDFont.bodyRegular(.semibold))
                        .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                    Text(viewModel.docPhoto != nil ? "Değiştirmek için dokunun" : "Fotoğraf, galeri veya PDF")
                        .font(IDFont.caption(.regular))
                        .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(IDColor.inkMid)
            }
            .padding(IDSpacing.lg)
            .frame(minHeight: 85)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(IDColor.inkBorder.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                    )
                    .foregroundColor(Color.primary.opacity(0.35))
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: viewModel.docPhoto != nil)
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let img = viewModel.docPhoto {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        } else {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(uiColor: .systemGray5))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "doc.viewfinder")
                        .font(.system(size: 22, weight: .light))
                        .foregroundColor(IDColor.inkMid)
                )
        }
    }

    // MARK: - Error Row

    @ViewBuilder
    private var errorRow: some View {
        if let msg = viewModel.errorMessage {
            Text(msg)
                .font(IDFont.caption(.regular))
                .foregroundColor(IDColor.error)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button(action: { viewModel.submit(appState: appState) }) {
            Text("Devam")
                .font(IDFont.bodyRegular(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    viewModel.canSubmit
                        ? IDColor.primary
                        : IDColor.primary.opacity(0.35)
                )
                .clipShape(Capsule())
        }
        .disabled(!viewModel.canSubmit)
        .animation(.easeInOut(duration: 0.2), value: viewModel.canSubmit)
    }

    // MARK: - Document Options Overlay

    private var documentOptionsOverlay: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation { viewModel.showDocumentOptions = false }
                }

            VStack(spacing: 8) {
                VStack(spacing: 0) {
                    actionRow(
                        icon: "camera",
                        title: "Fotoğraf Çek",
                        action: viewModel.openScanner
                    )
                    Divider()
                        .padding(.leading, IDSpacing.xxl + IDSpacing.lg)
                    actionRow(
                        icon: "photo.on.rectangle",
                        title: "Fotoğraf Seç",
                        action: viewModel.openGallery
                    )
                    Divider()
                        .padding(.leading, IDSpacing.xxl + IDSpacing.lg)
                    actionRow(
                        icon: "folder",
                        title: "Dosya Seç",
                        action: viewModel.openPDFPicker
                    )
                }
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(uiColor: .systemBackground).opacity(0.95))
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, IDSpacing.lg)

                Button(action: {
                    withAnimation { viewModel.showDocumentOptions = false }
                }) {
                    Text("Vazgeç")
                        .font(IDFont.bodyRegular(.semibold))
                        .foregroundColor(IDColor.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 57)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(uiColor: .systemBackground).opacity(0.95))
                        )
                }
                .padding(.horizontal, IDSpacing.lg)
            }
            .padding(.bottom, IDSpacing.xxl)
        }
        .ignoresSafeArea()
    }

    private func actionRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: IDSpacing.lg) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(IDColor.primary)
                    .frame(width: 28)
                Text(title)
                    .font(IDFont.bodyRegular(.regular))
                    .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                Spacer()
            }
            .padding(.horizontal, IDSpacing.lg)
            .frame(height: 57)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Scanner Style

    private var scannerStyle: QuadrilateralStyle {
        QuadrilateralStyle(
            strokeColor: IDColor.primary.opacity(0.55),
            lockedStrokeColor: IDColor.primary,
            lineWidth: 2.5
        )
    }

    // MARK: - Logo

    private var identifyLogoView: some View {
        Image(colorScheme == .dark ? "ic_lang_button_dark" : "ic_lang_button_light")
            .frame(width: 44, height: 44)
    }
}

#Preview {
    AddressConfirmView()
        .environmentObject(AppStateViewModel())
        .environmentObject(AppNavigationCoordinator())
}
