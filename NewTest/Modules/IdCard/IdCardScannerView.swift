//
//  IdCardScannerView.swift
//  NewTest
//
//  Gerçek zamanlı kimlik tarayıcı. SDK'daki IdentityScannerView kullanılır.
//
//  Tarayıcı pipeline:
//    Kamera → Dikdörtgen tespiti (Quadrilateral) → Kararlılık analizi
//    → Profil stratejisi (MRZ / imageOnly) → RecognizedDocument
//
//  Kart tipi → DocumentProfile eşlemesi:
//    .idCard    → .turkishID   (TC Kimlik, MRZ tabanlı)
//    .passport  → .passport    (ICAO MRZ)
//    .oldSchool → .generic     (eski kimlik, sadece görüntü)
//
//  Yakalanan kart görüntüsü coordinator.onScanComplete ile geri verilir.
//

import SwiftUI
import IdentifySDK

// MARK: - IdCardScannerView

struct IdCardScannerView: View {

    let side: IdCardSide
    @EnvironmentObject private var coordinator: AppNavigationCoordinator

    var body: some View {
        ZStack(alignment: .topLeading) {
            IdentityScannerView(
                profile: documentProfile,
                style: quadStyle,
                configuration: .default
            ) { result in
                switch result {
                case .success(let doc):
                    finish(with: doc.croppedImage)
                case .failure:
                    cancel()
                }
            }
            .ignoresSafeArea()

            closeButton
                .padding(.leading, IDSpacing.lg)
                .padding(.top, IDSpacing.lg)
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Document Profile

    private var documentProfile: DocumentProfile {
        switch IdentifyManager.shared.selectedCardType {
        case .passport:
            return .passport
        case .oldSchool:
            return .generic
        default:
            return side == .back ? .turkishIDBack : .turkishIDFront
        }
    }

    // MARK: - Quad Style

    private var quadStyle: QuadrilateralStyle {
        QuadrilateralStyle(
            strokeColor: IDColor.primary.opacity(0.55),
            lockedStrokeColor: IDColor.primary,
            lineWidth: 2.5
        )
    }

    // MARK: - Actions

    private func finish(with image: UIImage) {
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
