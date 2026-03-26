//
//  ThankYouView.swift
//  NewTest
//
//  Tamamlanma ekrani - TASARIM KULLANICI TARAFINDAN DOLDURULACAK.
//
//  --- KULLANIM REHBERI ---
//
//  DURUM:
//    viewModel.completeStatus:
//      .completed    -> basarili KYC
//      .missedCall   -> cagri cevapsiz
//      .notCompleted -> tamamlanamadi
//
//    viewModel.kycCompleted          -> genel KYC tamamlama flag
//    viewModel.isSelfieIdentification-> selfie ile mi tamamlandi
//
//  CIKIS:
//    appState.resetFlow()            -> ana ekrana don (yeni oturum)
//

import SwiftUI

struct ThankYouView: View {

    @StateObject private var viewModel = ThankYouViewModel()
    @EnvironmentObject private var appState: AppStateViewModel

    var body: some View {
        // TODO: Tasarimi buraya yaz.
        VStack(spacing: 24) {

            switch viewModel.completeStatus {
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
                Text("Tamamlandi")
                    .font(.title)
                Text("Kimlik dogrulama basarili tamamlandi.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

            case .missedCall:
                Image(systemName: "phone.down.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.orange)
                Text("Cagri Cevapsiz")
                    .font(.title)
                Text("Gorusme cevapsiz kaldi.")
                    .foregroundColor(.secondary)

            case .notCompleted:
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.red)
                Text("Tamamlanamadi")
                    .font(.title)
                Text("Islem tamamlanamadi.")
                    .foregroundColor(.secondary)
            }

            Button("Kapat") {
                appState.resetFlow()
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 12)
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(Capsule())
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}
