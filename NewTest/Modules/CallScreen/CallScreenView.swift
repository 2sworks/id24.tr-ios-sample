//
//  CallScreenView.swift
//  NewTest
//
//  Video goruntulu gorusme ekrani - TASARIM KULLANICI TARAFINDAN DOLDURULACAK.
//
//  --- KULLANIM REHBERI ---
//
//  DURUM MAKİNASI:
//    viewModel.callState:
//      .waiting        -> kuyruktayiz, bekleme ekrani goster
//      .ringing        -> cagri geliyor, kabul/reddet
//      .connected      -> gorusme devam ediyor
//      .smsVerification-> SMS kodu girisi
//      .ended          -> gorusme bitti
//
//  KUYRUK BİLGİSİ:
//    viewModel.queuePosition         -> siramiz
//    viewModel.estimatedWait         -> tahmini bekleme (dakika)
//
//  WEBRTC KAMERA:
//    viewModel.remoteVideoView       -> UIView (karsı taraf kamerasi)
//    viewModel.localVideoView        -> UIView (bizim kameramiz)
//    UIViewRepresentable ile sar ve layout'a ekle.
//
//  AG KALİTESİ:
//    viewModel.networkQuality        -> .poor / .fair / .good
//
//  SMS DOGRULAMA:
//    $viewModel.smsCode              -> TextField binding (6 hane)
//    viewModel.verifySMS(appState:)  -> dogrula
//
//  AKSIYONLAR:
//    viewModel.acceptCall()          -> cagrıyi kabul et
//    viewModel.terminateCall(appState:) -> cagrıyi bitir + devam
//
//  SOCKET (otomatik dinlenir, state guncellenir):
//    viewModel kurulurken manager.socketMessageListener = viewModel yapilmali
//
//  NOT: CallScreen ekrani active iken manager.socketMessageListener
//       bu viewModel'e set edilmelidir:
//       .onAppear { appState.manager.socketMessageListener = viewModel }
//       .onDisappear { appState.manager.socketMessageListener = appState }
//

import SwiftUI

struct CallScreenView: View {

    @StateObject private var viewModel = CallScreenViewModel()
    @EnvironmentObject private var appState: AppStateViewModel

    var body: some View {
        // TODO: Tasarimi buraya yaz.
        ZStack {
            Color.black.ignoresSafeArea()

            switch viewModel.callState {

            case .waiting:
                VStack(spacing: 12) {
                    ProgressView().tint(.white)
                    Text("Bekleniyor...")
                        .foregroundColor(.white)
                    if !viewModel.queuePosition.isEmpty {
                        Text("Siraniz: \(viewModel.queuePosition)")
                            .foregroundColor(.white.opacity(0.7))
                        Text("Tahmini: \(viewModel.estimatedWait) dk")
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

            case .ringing:
                VStack(spacing: 16) {
                    Text("Cagri Geliyor")
                        .foregroundColor(.white)
                        .font(.title)
                    Button("Kabul Et") { viewModel.acceptCall() }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }

            case .connected:
                VStack {
                    // TODO: WebRTC kamera view'larini buraya ekle
                    // UIViewRepresentable { viewModel.remoteVideoView }
                    // UIViewRepresentable { viewModel.localVideoView }

                    Text("Gorusme Devam Ediyor").foregroundColor(.white)

                    // Ag kalitesi
                    Text("Ag: \(viewModel.networkQualityText)")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.caption)

                    Spacer()

                    if viewModel.endCallEnabled {
                        Button("Bitir") {
                            viewModel.terminateCall(appState: appState)
                        }
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    }
                }

            case .smsVerification:
                VStack(spacing: 12) {
                    Text("SMS Kodunu Girin").foregroundColor(.white)
                    TextField("6 haneli kod", text: $viewModel.smsCode)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 200)
                    Button("Dogrula") {
                        viewModel.verifySMS(appState: appState)
                    }
                    .disabled(!viewModel.isSMSCodeValid)
                }

            case .ended:
                VStack {
                    Text("Gorusme Bitti").foregroundColor(.white).font(.title)
                    Button("Devam") { appState.advanceToNextModule() }
                        .foregroundColor(.white)
                }
            }

            if let msg = viewModel.errorMessage {
                VStack {
                    Spacer()
                    Text(msg)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .clipShape(Capsule())
                        .padding(.bottom)
                }
            }
        }
        .onAppear {
            // CallScreen aktifken socket listener bu viewModel'e devredilir
            appState.manager.socketMessageListener = viewModel
        }
        .onDisappear {
            // Cikista AppStateViewModel'e geri ver
            appState.manager.socketMessageListener = appState
        }
    }
}
