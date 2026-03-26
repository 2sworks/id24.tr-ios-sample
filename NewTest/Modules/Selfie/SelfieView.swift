//
//  SelfieView.swift
//  NewTest
//
//  Selfie ekrani - TASARIM KULLANICI TARAFINDAN DOLDURULACAK.
//
//  --- KULLANIM REHBERI ---
//
//  FOTOGRAF:
//    viewModel.selfieImage           -> cekilen UIImage
//
//  ISLEM:
//    viewModel.processSelfie(image:appState:)
//      -> yuz tespit + yukleme yapar, basarida canContinue=true
//
//  KAMERA ACMA:
//    UIImagePickerController veya PHPickerViewController kullanilabilir.
//    Secilen fotografi viewModel.processSelfie(...) ile isle.
//
//  DURUM:
//    viewModel.faceDetected          -> yuz tespit edildi mi
//    viewModel.canContinue           -> devam butonu aktif mi
//    viewModel.resultText            -> sonuc metni
//    viewModel.isLoading             -> islem devam ediyor
//    viewModel.errorMessage          -> hata mesaji
//
//  DEVAM:
//    appState.advanceToNextModule()
//    appState.skipCurrentModule()
//

import SwiftUI

struct SelfieView: View {

    @StateObject private var viewModel = SelfieViewModel()
    @EnvironmentObject private var appState: AppStateViewModel

    @State private var showImagePicker = false

    var body: some View {
        // TODO: Tasarimi buraya yaz.
        VStack(spacing: 16) {
            Text("Selfie")
                .font(.title2)

            if let img = viewModel.selfieImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 200)
                    .overlay(Text("Foto yok").foregroundColor(.secondary))
            }

            Button("Selfie Cek") { showImagePicker = true }

            if !viewModel.resultText.isEmpty {
                Text(viewModel.resultText).foregroundColor(.green)
            }
            if let msg = viewModel.errorMessage {
                Text(msg).foregroundColor(.red).font(.caption)
            }

            Button("Devam") { appState.advanceToNextModule() }
                .disabled(!viewModel.canContinue)
        }
        .padding()
        .overlay {
            if viewModel.isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView().tint(.white)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            // UIImagePickerController veya PHPickerViewController
            // Secilen fotografi: viewModel.processSelfie(image: secilenFoto, appState: appState)
            Text("Kamera entegrasyonu eklenecek")
        }
    }
}
