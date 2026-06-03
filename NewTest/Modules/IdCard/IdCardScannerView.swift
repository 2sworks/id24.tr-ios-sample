//
//  IdCardScannerView.swift
//  NewTest
//
//  Gerçek zamanlı kimlik tarayıcı. SDK'daki IdentityScannerView (otomatik
//  yakalama: dikdörtgen tespiti + kalite + kararlılık) kullanılır. Yakalanan
//  kart görüntüsü coordinator.onScanComplete ile geri verilir ve pop edilir.
//

import SwiftUI
import IdentifySDK

// MARK: - IdCardScannerView

struct IdCardScannerView: View {

    let side: IdCardSide
    @EnvironmentObject private var coordinator: AppNavigationCoordinator

    var body: some View {
        ZStack(alignment: .topLeading) {
            IdentityScannerView(config: scannerConfig) { result in
                finish(with: result.cardImage)
            }
            .ignoresSafeArea()

            closeButton
                .padding(.leading, IDSpacing.lg)
                .padding(.top, IDSpacing.lg)
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Config

    private var scannerConfig: IdentityScannerConfig {
        var config = IdentityScannerConfig()
        // Arka yüzde TR anahtar kelimeleri (TÜRKİYE CUMHURİYETİ) bulunmaz; MRZ
        // tarafında metin teyidini zorunlu tutma.
        if side == .back {
            config.requireTurkishKeyword = false
        }
        return config
    }

    // MARK: - Actions

    private func finish(with image: UIImage?) {
        guard let image = image else { return }   // yakalama başarısız: ekranda kal
        coordinator.onScanComplete?(image)
        coordinator.onScanComplete = nil
        coordinator.pop()
    }

    private func cancel() {
        coordinator.onScanComplete = nil
        coordinator.pop()
    }

    // MARK: - UI

    private var closeButton: some View {
        Button(action: cancel) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.black.opacity(0.45)))
        }
    }
}
