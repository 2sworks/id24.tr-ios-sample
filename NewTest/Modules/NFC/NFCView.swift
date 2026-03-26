//
//  NFCView.swift
//  NewTest
//
//  NFC okuma ekrani - TASARIM KULLANICI TARAFINDAN DOLDURULACAK.
//
//  --- KULLANIM REHBERI ---
//
//  VERİ:
//    viewModel.serialNo    -> belge no (TextField binding)
//    viewModel.birthDate   -> dogum tarihi (TextField binding)
//    viewModel.validDate   -> gecerlilik tarihi (TextField binding)
//
//  NFC BASLAT:
//    viewModel.startNFC(appState:) -> NFC okumayı baslat
//
//  DURUM:
//    viewModel.nfcStatus         -> durum metni ("Okuma tamamlandi" vb.)
//    viewModel.nfcCompleted      -> tamamlandi mi
//    viewModel.showEditScreen    -> tarih duzeltme ekrani
//    viewModel.isLoading         -> islem devam ediyor
//    viewModel.errorMessage      -> hata
//
//  MANUEL DUZELTME:
//    viewModel.isBirthdayPicker  -> dogum/gecerlilik picker secimi
//    viewModel.saveManualDates() -> duzeltilmis tarihleri kaydet + NFC yeniden dene
//
//  DEVAM:
//    appState.advanceToNextModule()   (viewModel.startNFC otomatik tetikler)
//    appState.skipCurrentModule()
//

import SwiftUI

struct NFCView: View {

    @StateObject private var viewModel = NFCViewModel()
    @EnvironmentObject private var appState: AppStateViewModel

    var body: some View {
        // TODO: Tasarimi buraya yaz.
        VStack(spacing: 16) {
            Text("NFC Okuma")
                .font(.title2)

            Group {
                TextField("Belge No", text: $viewModel.serialNo)
                TextField("Dogum Tarihi (YYMMDD)", text: $viewModel.birthDate)
                TextField("Gecerlilik (YYMMDD)", text: $viewModel.validDate)
            }
            .textFieldStyle(.roundedBorder)
            .autocapitalization(.allCharacters)
            .disableAutocorrection(true)

            if !viewModel.nfcStatus.isEmpty {
                Text(viewModel.nfcStatus)
                    .foregroundColor(viewModel.nfcCompleted ? .green : .secondary)
            }
            if let msg = viewModel.errorMessage {
                Text(msg).foregroundColor(.red).font(.caption)
            }

            Button("NFC Baslat") {
                viewModel.startNFC(appState: appState)
            }
            .disabled(viewModel.isLoading)
        }
        .padding()
        .overlay {
            if viewModel.isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView().tint(.white)
            }
        }
        .sheet(isPresented: $viewModel.showEditScreen) {
            NFCEditView(viewModel: viewModel, appState: appState)
        }
    }
}

// MARK: - NFC Manuel Duzeltme Sheet

struct NFCEditView: View {
    @ObservedObject var viewModel: NFCViewModel
    let appState: AppStateViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Belge Bilgileri") {
                    TextField("Belge No", text: $viewModel.serialNo)
                    TextField("Dogum Tarihi", text: $viewModel.birthDate)
                    TextField("Gecerlilik Tarihi", text: $viewModel.validDate)
                }
            }
            .navigationTitle("Bilgileri Duzeltin")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        viewModel.saveManualDates()
                        dismiss()
                        viewModel.startNFC(appState: appState)
                    }
                }
            }
        }
    }
}
