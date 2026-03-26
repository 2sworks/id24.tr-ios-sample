//
//  VideoRecorderView.swift
//  NewTest
//
//  Video kayit ekrani - TASARIM KULLANICI TARAFINDAN DOLDURULACAK.
//
//  --- KULLANIM REHBERI ---
//
//  VİDEO KAYIT:
//    UIImagePickerController ile video kaydet (sourceType: .camera, mediaTypes: [kUTTypeMovie])
//    Kaydedilen URL'yi: viewModel.videoSelected(url:) ile ilet
//
//  ONIZLEME:
//    viewModel.videoURL              -> AVPlayer icin URL
//    viewModel.videoTimeLimit        -> 5.0 saniye (max)
//
//  ISLEM:
//    viewModel.uploadVideo(appState:) -> yukle + otomatik devam eder
//
//  DURUM:
//    viewModel.videoData             -> video Data (nil = secilmedi)
//    viewModel.uploadCompleted       -> yukleme tamam
//    viewModel.isLoading             -> yukleme devam ediyor
//    viewModel.errorMessage          -> hata
//
//  DEVAM:
//    viewModel.uploadVideo() otomatik olarak appState.advanceToNextModule() cagirir
//

import SwiftUI
import AVKit

struct VideoRecorderView: View {

    @StateObject private var viewModel = VideoRecorderViewModel()
    @EnvironmentObject private var appState: AppStateViewModel

    @State private var showVideoPicker = false

    var body: some View {
        // TODO: Tasarimi buraya yaz.
        VStack(spacing: 16) {
            Text("Video Kayit")
                .font(.title2)

            Text("Maks sure: \(Int(viewModel.videoTimeLimit)) saniye")
                .foregroundColor(.secondary)
                .font(.caption)

            if let url = viewModel.videoURL {
                VideoPlayer(player: AVPlayer(url: url))
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 200)
                    .overlay(Text("Video secilmedi").foregroundColor(.secondary))
            }

            Button("Video Cek / Sec") { showVideoPicker = true }

            Button("Yukle") {
                viewModel.uploadVideo(appState: appState)
            }
            .disabled(viewModel.videoData == nil)

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
        .sheet(isPresented: $showVideoPicker) {
            // UIImagePickerController ile video sec/kaydet
            // Secilen URL'yi: viewModel.videoSelected(url: secilenURL)
            Text("Kamera entegrasyonu eklenecek")
        }
    }
}
