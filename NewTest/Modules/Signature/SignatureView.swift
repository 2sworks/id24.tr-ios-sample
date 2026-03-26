//
//  SignatureView.swift
//  NewTest
//
//  Imza ekrani - TASARIM KULLANICI TARAFINDAN DOLDURULACAK.
//
//  --- KULLANIM REHBERI ---
//
//  IMZA:
//    SwiftSignatureView'i UIViewRepresentable ile sar:
//      - swiftSignatureViewDidDraw -> viewModel.signatureDidDraw()
//      - Gonder: view.getCroppedSignature() -> UIImage -> viewModel.uploadSignature(image:appState:)
//      - Temizle: view.clear() + viewModel.clearSignature()
//
//  DURUM:
//    viewModel.signatureDrawn        -> imza cizildi mi (gonder aktif)
//    viewModel.uploadCompleted       -> yukleme tamam
//    viewModel.isLoading             -> yukleme devam ediyor
//    viewModel.errorMessage          -> hata
//
//  DEVAM:
//    viewModel.uploadSignature(image:appState:) -> yukle + otomatik devam eder
//

import SwiftUI

struct SignatureView: View {

    @StateObject private var viewModel = SignatureViewModel()
    @EnvironmentObject private var appState: AppStateViewModel

    var body: some View {
        // TODO: Tasarimi buraya yaz.
        // SwiftSignatureView buraya UIViewRepresentable olarak eklenmeli.
        VStack(spacing: 16) {
            Text("Imza")
                .font(.title2)

            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray, lineWidth: 1)
                .frame(height: 200)
                .overlay(Text("Imza alani - SwiftSignatureView eklenecek").foregroundColor(.secondary))

            HStack {
                Button("Temizle") { viewModel.clearSignature() }
                    .foregroundColor(.red)

                Spacer()

                Button("Gonder") {
                    // UIImage'i SwiftSignatureView'den al:
                    // let img = signatureView.getCroppedSignature()
                    // viewModel.uploadSignature(image: img, appState: appState)
                }
                .disabled(!viewModel.signatureDrawn)
            }

            if let msg = viewModel.errorMessage {
                Text(msg).foregroundColor(.red).font(.caption)
            }
        }
        .padding()
        .overlay {
            if viewModel.isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView().tint(.white)
            }
        }
    }
}
