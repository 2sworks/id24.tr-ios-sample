//
//  IdCardView.swift
//  NewTest
//
//  Kimlik karti tarama ekrani - TASARIM KULLANICI TARAFINDAN DOLDURULACAK.
//
//  --- KULLANIM REHBERI ---
//
//  FOTOGRAF:
//    viewModel.frontPhoto            -> UIImage (on yuz)
//    viewModel.backPhoto             -> UIImage (arka yuz)
//    viewModel.currentSide           -> .front / .back / .passport
//
//  TARAMA:
//    viewModel.scanFront(image:appState:)       -> on yuz OCR
//    viewModel.scanBack(image:appState:)        -> arka yuz OCR + upload
//    viewModel.scanPassport(image:comingData:appState:) -> pasaport MRZ
//
//  DURUM:
//    viewModel.resultText            -> OCR/upload sonucu
//    viewModel.canContinue           -> devam butonu
//    viewModel.allowedCardTypes      -> desteklenen kart tipleri
//    viewModel.nfcRetryExceeded      -> NFC deneme asildiysa devami kisitla
//    viewModel.isLoading             -> islem devam ediyor
//    viewModel.errorMessage          -> hata mesaji
//
//  DEVAM:
//    appState.advanceToNextModule()  -> bir sonraki module gec
//    appState.skipCurrentModule()    -> modulu atla
//

import SwiftUI

struct IdCardView: View {

    @StateObject private var viewModel = IdCardViewModel()
    @EnvironmentObject private var appState: AppStateViewModel

    var body: some View {
        // TODO: Tasarimi buraya yaz.
        VStack(spacing: 16) {
            Text("Kimlik Karti Tarama")
                .font(.title2)

            Text("Taraf: \(String(describing: viewModel.currentSide))")
                .foregroundColor(.secondary)

            if !viewModel.resultText.isEmpty {
                Text(viewModel.resultText)
                    .foregroundColor(.green)
            }

            if let msg = viewModel.errorMessage {
                Text(msg).foregroundColor(.red).font(.caption)
            }

            Button("Devam") {
                appState.advanceToNextModule()
            }
            .disabled(!viewModel.canContinue)
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
