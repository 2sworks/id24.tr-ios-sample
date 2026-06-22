//
//  AddressConfirmView.swift
//  NewTest
//

import SwiftUI
import PhotosUI
import IdentifySDK

struct AddressConfirmView: View {

    @StateObject private var viewModel = AddressConfirmViewModel()
    @EnvironmentObject private var appState: AppStateViewModel
    @EnvironmentObject private var coordinator: AppNavigationCoordinator
    @Environment(\.colorScheme) private var colorScheme
    @State private var showGallerySheet = false

    var body: some View {
        ZStack(alignment: .top) {
            (colorScheme == .dark ? IDColor.darkBg : IDColor.primary).ignoresSafeArea()
            VStack(spacing: 0) {
                SDKNavigationBar(
                    style: .progress(steps: appState.progressTotal, current: appState.progressStep),
                    title: "Adres Doğrulama",
                    subtitle: "Adresinizi doğrulamamıza yardımcı olun",
                    onBack: { coordinator.pop() }
                )
                cardArea
            }
        }
        .overlay {
            if viewModel.isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView().tint(.white)
            }
        }
        .confirmationDialog("Belge Ekle", isPresented: $viewModel.showDocumentOptions, titleVisibility: .visible) {
            Button("Fotoğraf Çek") { viewModel.openScanner() }
            Button("Fotoğraf Seç") { showGallerySheet = true }
            Button("Dosya Seç") { viewModel.openPDFPicker() }
            Button("Vazgeç", role: .cancel) {}
        }
        .sheet(isPresented: $showGallerySheet) {
            PHPickerView { image in
                viewModel.photoSelected(image)
                showGallerySheet = false
            }
        }
        .documentScanner(isPresented: $viewModel.showScanner, profile: .generic, style: scannerStyle, configuration: .document) { result in
            if case .success(let doc) = result {
                viewModel.photoSelected(doc.croppedImage)
            }
        }
        .fileImporter(
            isPresented: $viewModel.showPDFPicker,
            allowedContentTypes: [.pdf]
        ) { result in
            if case .success(let url) = result {
                let accessing = url.startAccessingSecurityScopedResource()
                viewModel.pdfSelectedFromURL(url)
                if accessing { url.stopAccessingSecurityScopedResource() }
            }
        }
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

            Text("PDF, JPG, JPEG, PNG, WEBP, TIFF 15MB'den az")
                .font(IDFont.caption(.regular))
                .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, IDSpacing.sm)
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
            Text("İkmaetgah adresinizi yazın")
                .font(IDFont.displayMedium(.semibold))
                .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))

            Text("Adresinizi doğrulayabilmemiz için lütfen herhangi bir faturanızın fotoğrafını çekin veya seçin.")
                .font(IDFont.bodyRegular(.regular))
                .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                .lineSpacing(4)
        }
    }

    // MARK: - Address Editor

    private var addressEditorSection: some View {
        ZStack(alignment: .topLeading) {
            if viewModel.addressText.isEmpty {
                Text("Lütfen ikametgah adresinizi yazın..")
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
                    Text(viewModel.docPhoto != nil ? "Belge eklendi" : "Dosya Yükle")
                        .font(IDFont.bodyRegular(.semibold))
                        .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                    Text(viewModel.docPhoto != nil ? "Değiştirmek için dokunun" : "Cihazınızdan seçin")
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
                    Image(.uploadFile)
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
        SDKButton(
            title: "Devam",
            isDisabled: !viewModel.canSubmit
        ) {
            viewModel.submit(appState: appState)
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.canSubmit)
    }

    // MARK: - Scanner Style

    private var scannerStyle: QuadrilateralStyle {
        QuadrilateralStyle(
            strokeColor: IDColor.primary.opacity(0.55),
            lockedStrokeColor: IDColor.primary,
            lineWidth: 2.5
        )
    }
}

// MARK: - PHPickerView

private struct PHPickerView: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PHPickerView
        init(parent: PHPickerView) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            guard let result = results.first,
                  result.itemProvider.canLoadObject(ofClass: UIImage.self) else { return }
            result.itemProvider.loadObject(ofClass: UIImage.self) { obj, _ in
                if let image = obj as? UIImage {
                    DispatchQueue.main.async { self.parent.onImage(image) }
                }
            }
        }
    }
}

#Preview {
    AddressConfirmView()
        .environmentObject(AppStateViewModel())
        .environmentObject(AppNavigationCoordinator())
}
