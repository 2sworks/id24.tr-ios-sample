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

    @State private var isTorchOn = false
    @State private var isTorchAvailable = false

    var body: some View {
        ZStack(alignment: .top) {
            IdentityScannerView(
                profile: documentProfile,
                style: quadStyle,
                configuration: .default,
                externalTorchOn: $isTorchOn,
                onTorchAvailability: { available in isTorchAvailable = available }
            ) { result in
                switch result {
                case .success(let doc):
                    finish(with: doc.croppedImage)
                case .failure:
                    cancel()
                }
            }
            .ignoresSafeArea()

            SDKNavigationBar(
                style: .overlay,
                onBack: { cancel() },
                trailing: isTorchAvailable ? AnyView(torchButton) : nil
            )
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .onDisappear {
            coordinator.onScanComplete = nil
        }
    }

    // MARK: - Torch Button

    private var torchButton: some View {
        Button { isTorchOn.toggle() } label: {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                Image(systemName: isTorchOn ? "bolt.fill" : "bolt.slash.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
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

}

