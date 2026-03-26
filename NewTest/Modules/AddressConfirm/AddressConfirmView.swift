//
//  AddressConfirmView.swift
//  NewTest
//
//  Adres dogrulama ekrani - TASARIM KULLANICI TARAFINDAN DOLDURULACAK.
//
//  --- KULLANIM REHBERI ---
//
//  ADRES METNİ:
//    $viewModel.addressText          -> TextEditor binding
//    viewModel.isAddressValid        -> min 10 karakter
//
//  BELGE:
//    viewModel.photoSelected(image)  -> foto secildi
//    viewModel.pdfSelected(data:preview:) -> PDF secildi
//    viewModel.docPhoto              -> onizleme UIImage
//    viewModel.showPDFOption         -> PDF modu toggle
//    viewModel.maxPDFSizeMB          -> max PDF boyutu
//
//  BELGE SECİM:
//    UIDocumentPickerViewController  -> PDF (UTType.pdf)
//    UIImagePickerController         -> foto / galeri
//    ImageScannerController          -> belge tarama
//
//  GONDER:
//    viewModel.canSubmit             -> gonder butonu aktif mi
//    viewModel.submit(appState:)     -> yukle + otomatik devam eder
//
//  DURUM:
//    viewModel.isLoading             -> yukleme devam ediyor
//    viewModel.errorMessage          -> hata
//

import SwiftUI

struct AddressConfirmView: View {

    @StateObject private var viewModel = AddressConfirmViewModel()
    @EnvironmentObject private var appState: AppStateViewModel

    @State private var showPhotoPicker = false
    @State private var showDocPicker = false

    var body: some View {
        // TODO: Tasarimi buraya yaz.
        ScrollView {
            VStack(spacing: 16) {
                Text("Adres Dogrulama")
                    .font(.title2)

                // Adres metin alani
                TextEditor(text: $viewModel.addressText)
                    .frame(height: 100)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4)))

                // PDF / foto secim
                Toggle("PDF yukle", isOn: $viewModel.showPDFOption)

                HStack {
                    Button("Foto Sec") { showPhotoPicker = true }
                    Spacer()
                    if viewModel.showPDFOption {
                        Button("PDF Sec") { showDocPicker = true }
                    }
                }

                // Onizleme
                if let img = viewModel.docPhoto {
                    Image(uiImage: img)
                        .resizable().scaledToFit()
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                if let msg = viewModel.errorMessage {
                    Text(msg).foregroundColor(.red).font(.caption)
                }

                Button("Gonder") {
                    viewModel.submit(appState: appState)
                }
                .disabled(!viewModel.canSubmit)
            }
            .padding()
        }
        .overlay {
            if viewModel.isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView().tint(.white)
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            Text("Foto picker entegrasyonu eklenecek")
            // Secilen: viewModel.photoSelected(image)
        }
        .sheet(isPresented: $showDocPicker) {
            Text("PDF picker entegrasyonu eklenecek")
            // Secilen: viewModel.pdfSelected(data:preview:)
        }
    }
}
