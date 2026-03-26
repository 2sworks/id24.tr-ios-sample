//
//  LoginView.swift
//  NewTest
//
//  Login ekrani - TASARIM KULLANICI TARAFINDAN DOLDURULACAK.
//
//  --- KULLANIM REHBERI ---
//
//  BAGLANTI:
//    appState.setupSDK(
//        identId: viewModel.resolveIdentId(),
//        apiUrl: viewModel.selectedServer.apiUrl,
//        idLang: viewModel.selectedIdLang,
//        signLangSupport: viewModel.useSignLang,
//        bigCustomerCam: viewModel.useBigCustomerCam,
//        useSSLPinning: viewModel.useSSLPinning,
//        useNewLiveness: viewModel.useNewLiveness,
//        selectedModules: viewModel.selectedModules
//    )
//
//  DİL SEÇİMİ:
//    viewModel.setSDKLanguage(.tr)   // .eng / .tr / .de / .ru / .az
//
//  SUNUCU SEÇİMİ:
//    viewModel.serverList            -> [ServerOption]
//    viewModel.selectServer(server)  -> selectedServer günceller
//    viewModel.loadSavedServers()    -> Core Data'dan yeniden yükler
//
//  MODUL LİSTESİ:
//    viewModel.availableModules      -> [SdkModules] tam liste
//    viewModel.selectedModules       -> secilen moduller (bos = SDK varsayilani)
//    viewModel.updateModules([...])  -> listeyi guncelle
//
//  TOGGLE'LAR:
//    $viewModel.useBigCustomerCam
//    $viewModel.useSignLang
//    $viewModel.useNewLiveness
//    $viewModel.useSSLPinning
//
//  DURUM:
//    appState.isLoading    -> baglanti devam ediyor
//    appState.sdkError     -> hata mesaji (nil degilse goster)
//    viewModel.isJailbroken -> jailbreak uyarisi
//    viewModel.buildNumber  -> build no etiketi
//

import SwiftUI
import IdentifySDK

struct LoginView: View {

    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject private var appState: AppStateViewModel

    // MARK: - Alt sheet/navigation state'leri

    @State private var showModuleList = false
    @State private var showServerList = false

    var body: some View {
        // TODO: Tasarimi buraya yaz.
        // Asagidaki VStack yerine kendi layoutunu kullan.
        VStack(spacing: 16) {

            // Build no
            Text("Build: \(viewModel.buildNumber)")
                .font(.caption)
                .foregroundColor(.secondary)

            // Jailbreak uyarisi
            if viewModel.isJailbroken {
                Text("Cihazda jailbreak tespit edildi")
                    .foregroundColor(.red)
                    .font(.caption)
            }

            // Ident ID girisi
            TextField("Ident ID", text: $viewModel.identId)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            // Secili sunucu
            Text("Sunucu: \(viewModel.selectedServer.title)")
                .font(.subheadline)

            // Ayarlar / modul listesi butonlari
            HStack {
                Button("Sunucu Sec") { showServerList = true }
                Spacer()
                Button("Modul Sec") { showModuleList = true }
            }
            .font(.subheadline)

            // Toggle'lar
            Toggle("Buyuk Kamera", isOn: $viewModel.useBigCustomerCam)
            Toggle("Isaret Dili", isOn: $viewModel.useSignLang)
            Toggle("Yeni Liveness", isOn: $viewModel.useNewLiveness)
            Toggle("SSL Pinning", isOn: $viewModel.useSSLPinning)

            // Baglan butonu
            Button("Baglan") {
                appState.setupSDK(
                    identId: viewModel.resolveIdentId(),
                    apiUrl: viewModel.selectedServer.apiUrl,
                    idLang: viewModel.selectedIdLang,
                    signLangSupport: viewModel.useSignLang,
                    bigCustomerCam: viewModel.useBigCustomerCam,
                    useSSLPinning: viewModel.useSSLPinning,
                    useNewLiveness: viewModel.useNewLiveness,
                    selectedModules: viewModel.selectedModules
                )
            }
            .disabled(viewModel.identId.isEmpty || appState.isLoading)
        }
        .padding()
        // Yukleme overlay'i
        .overlay {
            if appState.isLoading {
                Color.black.opacity(0.35).ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
        }
        // Hata alert'i
        .alert("Hata", isPresented: Binding(
            get: { appState.sdkError != nil },
            set: { if !$0 { appState.sdkError = nil } }
        )) {
            Button("Tamam") { appState.sdkError = nil }
        } message: {
            Text(appState.sdkError ?? "")
        }
        // Sunucu secim sheet'i
        .sheet(isPresented: $showServerList, onDismiss: { viewModel.loadSavedServers() }) {
            ServerListView(viewModel: viewModel)
        }
        // Modul listesi sheet'i
        .sheet(isPresented: $showModuleList) {
            ModuleListView(viewModel: viewModel)
        }
        .navigationBarHidden(true)
    }
}

// MARK: - ServerListView (sunucu secimi - CoreData + sabit liste)

struct ServerListView: View {
    @ObservedObject var viewModel: LoginViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List(viewModel.serverList) { server in
                Button {
                    viewModel.selectServer(server)
                    dismiss()
                } label: {
                    VStack(alignment: .leading) {
                        Text(server.title).bold()
                        Text(server.apiUrl).font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Sunucu Sec")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}

// MARK: - ModuleListView (manuel modul secimi)

struct ModuleListView: View {
    @ObservedObject var viewModel: LoginViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Set<SdkModules> = []

    var body: some View {
        NavigationView {
            List(viewModel.availableModules, id: \.self) { module in
                Button {
                    if selected.contains(module) {
                        selected.remove(module)
                    } else {
                        selected.insert(module)
                    }
                } label: {
                    HStack {
                        Text(module.rawValue)
                        Spacer()
                        if selected.contains(module) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.primary)
            }
            .navigationTitle("Modul Sec")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Iptal") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        viewModel.updateModules(Array(selected))
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            selected = Set(viewModel.selectedModules)
        }
    }
}
