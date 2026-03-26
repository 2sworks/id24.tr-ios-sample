//
//  LivenessView.swift
//  NewTest
//
//  Canlilik testi ekrani - TASARIM KULLANICI TARAFINDAN DOLDURULACAK.
//
//  NOT: ARSCNView UIViewRepresentable ile sarmalanmalidir.
//  ARSCNViewDelegate.renderer(:didUpdate:for:) metodunda
//  viewModel.uploadFrame(image:appState:) cagrilir.
//
//  --- KULLANIM REHBERI ---
//
//  ADIM:
//    viewModel.stepInstruction       -> kullaniciya gosterilen talimat
//    viewModel.currentStep           -> mevcut LivenessTestStep
//    viewModel.allStepsCompleted     -> tum adimlar bitti
//
//  BAYRAKLAR (ARSCNViewDelegate icin):
//    viewModel.allowBlink            -> kirpma adimi aktif mi
//    viewModel.allowSmile            -> gulme adimi aktif mi
//    viewModel.allowLeft / .allowRight -> bas donme adimlari
//
//  ISLEMLER:
//    viewModel.uploadFrame(image:appState:)      -> yakalanan frame'i gonder
//    viewModel.uploadVideo(videoData:appState:)  -> video yukle + sonrakine gec
//    viewModel.resetTest()                       -> testi sifirla
//
//  VIDEO:
//    viewModel.isRecordingEnabled    -> video kayit aktif mi
//    viewModel.maxVideoSize          -> max boyut (byte)
//
//  DURUM:
//    viewModel.isLoading             -> yukleme devam ediyor
//    viewModel.errorMessage          -> hata
//

import SwiftUI

struct LivenessView: View {

    @StateObject private var viewModel = LivenessViewModel()
    @EnvironmentObject private var appState: AppStateViewModel

    var body: some View {
        // TODO: Tasarimi buraya yaz.
        // ARSCNView icin UIViewControllerRepresentable kullan.
        VStack(spacing: 16) {
            Text("Canlilik Testi")
                .font(.title2)

            Text(viewModel.stepInstruction)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            if viewModel.allStepsCompleted {
                Text("Test tamamlandi!")
                    .foregroundColor(.green)
                    .font(.headline)

                Button("Devam") {
                    appState.advanceToNextModule()
                }
            }

            if let msg = viewModel.errorMessage {
                Text(msg).foregroundColor(.orange).font(.caption)
            }

            Button("Yeniden Baslat") {
                viewModel.resetTest()
            }
            .font(.caption)
            .foregroundColor(.secondary)
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
