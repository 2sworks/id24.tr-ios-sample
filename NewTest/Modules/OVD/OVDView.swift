//
//  OVDView.swift
//  NewTest
//
//  OVD ekrani - TASARIM KULLANICI TARAFINDAN DOLDURULACAK.
//
//  --- KULLANIM REHBERI ---
//
//  FOTOGRAF:
//    viewModel.frontPhoto            -> UIImage (on yuz)
//    viewModel.backPhoto             -> UIImage (arka yuz)
//    viewModel.ovdCaptured           -> OVD yakalama tamamlandi mi
//
//  ISLEMLER:
//    viewModel.processFrontOCR(image:appState:)  -> on yuz OCR + upload
//    viewModel.processBackOCR(image:appState:)   -> arka yuz OCR + upload
//    viewModel.uploadFrontOVD(image:appState:)   -> OVD foto yukleme
//
//  DURUM:
//    viewModel.ocrResultText         -> islem sonucu
//    viewModel.canContinue           -> devam butonu
//    viewModel.isLoading             -> islem devam ediyor
//    viewModel.errorMessage          -> hata
//
//  DEVAM:
//    appState.advanceToNextModule()
//    appState.skipCurrentModule()
//

import SwiftUI

struct OVDView: View {

    @StateObject private var viewModel = OVDViewModel()
    @EnvironmentObject private var appState: AppStateViewModel

    var body: some View {
        // TODO: Tasarimi buraya yaz.
        VStack(spacing: 16) {
            Text("OVD Dogrulama")
                .font(.title2)

            if !viewModel.ocrResultText.isEmpty {
                Text(viewModel.ocrResultText).foregroundColor(.green)
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
    }
}
