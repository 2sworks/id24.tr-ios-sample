//
//  PrepareView.swift
//  NewTest
//
//  Hazirlik ekrani - TASARIM KULLANICI TARAFINDAN DOLDURULACAK.
//
//  --- KULLANIM REHBERI ---
//
//  IZIN DURUMLARI:
//    viewModel.cameraAuthorized    -> kamera izni
//    viewModel.micAuthorized       -> mikrofon izni
//    viewModel.speechAuthorized    -> konusma izni
//    viewModel.allPermissionsGranted -> tumu tamam mi
//
//  HIZ TESTİ:
//    viewModel.speedCheckDone      -> tamamlandi mi
//    viewModel.measuredSpeed       -> kbps degeri
//    viewModel.connectionQuality   -> 0=zayif, 1=orta, 2=iyi
//    viewModel.startSpeedTest()    -> yeniden test baslatir
//
//  DEVAM:
//    viewModel.canProceed          -> devam butonu aktif mi
//    viewModel.completePrepare(appState:) -> modulu tamamlar + sonrakine gecer
//
//  YUKLEME:
//    viewModel.isLoading           -> hiz testi suresi
//

import SwiftUI

struct PrepareView: View {

    @StateObject private var viewModel = PrepareViewModel()
    @EnvironmentObject private var appState: AppStateViewModel

    var body: some View {
        // TODO: Tasarimi buraya yaz.
        VStack(spacing: 16) {
            Text("Hazirlik")
                .font(.title)

            // Izin durumu gostergesi
            PermissionRow(title: "Kamera", granted: viewModel.cameraAuthorized) {
                viewModel.checkCamera()
            }
            PermissionRow(title: "Mikrofon", granted: viewModel.micAuthorized) {
                viewModel.checkMicrophone()
            }
            PermissionRow(title: "Konusma Tanima", granted: viewModel.speechAuthorized) {
                viewModel.checkSpeech()
            }

            Divider()

            // Hiz testi
            if viewModel.speedCheckDone {
                Text("Hiz: \(Int(viewModel.measuredSpeed)) kbps")
                    .foregroundColor(viewModel.connectionQuality == .good ? .green : .orange)
            } else {
                Text(viewModel.isLoading ? "Hiz olculuyor..." : "Hiz testi bekliyor")
                    .foregroundColor(.secondary)
            }

            // Devam butonu
            Button("Devam") {
                viewModel.completePrepare(appState: appState)
            }
            .disabled(!viewModel.canProceed)
        }
        .padding()
    }
}

private struct PermissionRow: View {
    let title: String
    let granted: Bool
    let onRetry: () -> Void

    var body: some View {
        HStack {
            Image(systemName: granted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(granted ? .green : .red)
            Text(title)
            Spacer()
            if !granted {
                Button("İzin Ver") { onRetry() }
                    .font(.caption)
            }
        }
    }
}
