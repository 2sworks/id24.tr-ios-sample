//
//  SpeechRecView.swift
//  NewTest
//
//  Konusma tanima ekrani - TASARIM KULLANICI TARAFINDAN DOLDURULACAK.
//
//  --- KULLANIM REHBERI ---
//
//  HEDEF KELIME:
//    viewModel.targetWord            -> kullanicinin soymesi gereken kelime
//
//  KAYIT:
//    viewModel.startRecording()      -> uzun basilinca / buton ile baslat
//    viewModel.stopRecording()       -> birak / buton ile durdur
//    viewModel.isRecording           -> kayit devam ediyor mu
//
//  SONUC:
//    viewModel.recognizedText        -> tanima sonucu
//    viewModel.speechSuccess         -> basarili mi
//    viewModel.errorMessage          -> hata (yanlis kelime vb.)
//
//  DEVAM:
//    viewModel.confirmSpeech(appState:) -> SDK'ya bildir + sonrakine gec
//

import SwiftUI

struct SpeechRecView: View {

    @StateObject private var viewModel = SpeechRecViewModel()
    @EnvironmentObject private var appState: AppStateViewModel

    var body: some View {
        // TODO: Tasarimi buraya yaz.
        VStack(spacing: 20) {
            Text("Konusma Tanima")
                .font(.title2)

            Text("Soyleyin: \"\(viewModel.targetWord)\"")
                .font(.headline)
                .foregroundColor(.secondary)

            // Kayit butonu (uzun basma ornegi)
            Button(action: {}) {
                Circle()
                    .fill(viewModel.isRecording ? Color.red : Color.blue)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                            .foregroundColor(.white)
                            .font(.title)
                    )
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !viewModel.isRecording { viewModel.startRecording() }
                    }
                    .onEnded { _ in viewModel.stopRecording() }
            )

            if !viewModel.recognizedText.isEmpty {
                Text("Duyulan: \(viewModel.recognizedText)")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            if viewModel.speechSuccess {
                Text("Basarili!")
                    .foregroundColor(.green)
                    .font(.headline)

                Button("Devam") {
                    viewModel.confirmSpeech(appState: appState)
                }
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
