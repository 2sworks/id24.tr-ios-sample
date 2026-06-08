//
//  IdCardScannerView.swift
//  NewTest
//
//  Gerçek zamanlı kimlik tarayıcı. SDK'daki IdentityScannerView kullanılır.
//
//  Tarayıcı pipeline:
//    Kamera → Dikdörtgen tespiti (Quadrilateral) → Kalite analizi
//    → Güven/Kararlılık → Türkçe doğrulama → OCR → IdentityResult
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
                config: scannerConfig,
                uiConfig: scannerUIConfig
            ) { result in
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

    // MARK: - Pipeline config

    private var scannerConfig: IdentityScannerConfig {
        var config = IdentityScannerConfig()
        config.documentType = side == .back ? TurkishIDBackSpec() : TurkishIDFrontSpec()
        return config
    }

    // MARK: - UI config
    //
    // IdentityScannerUIConfig ile tarayıcının tüm görsel ve metin özellikleri
    // bu katmandan özelleştirilebilir. Quadrilateral overlay, hint banner,
    // sonuç paneli ve renk teması burada tanımlanır.
    //
    // Özelleştirilebilir tüm alanlar:
    //   - idleGuideColor / activeGuideColor     → kart çerçevesi renkleri
    //   - guideLineWidth / activeGuideLineWidth  → çizgi kalınlığı
    //   - guideCornerRadius                     → statik rehber köşe yuvarlama
    //   - hintSearching / hintDetected / …      → banner metinleri
    //   - showsResultPanel                      → yerleşik sonuç paneli açık/kapalı
    //   - resultPanelTitle / rescanButtonTitle   → panel başlık/buton metinleri

    private var scannerUIConfig: IdentityScannerUIConfig {
        var ui = IdentityScannerUIConfig()

        // Quadrilateral overlay renkleri — uygulama ana rengine uyarla
        ui.idleGuideColor       = IDColor.primary.opacity(0.55)
        ui.activeGuideColor     = IDColor.primary
        ui.guideLineWidth       = 2
        ui.activeGuideLineWidth = 3.5

        // Hint metinleri — uygulamanın dil sistemine göre güncellenebilir
        let lang = IdentifyManager.shared.sdkLang ?? .tr
        switch lang {
        case .eng:
            ui.hintSearching  = "Place your ID card in the frame"
            ui.hintDetected   = "Hold still…"
            ui.hintBlurry     = "Move closer / hold steady"
            ui.hintGlare      = "Tilt to reduce glare"
            ui.hintTooDark    = "More light needed"
            ui.hintTooBright  = "Too bright"
            ui.hintCapturing  = "Capturing…"
            ui.hintProcessing = "Processing…"
            ui.hintDone       = "Done"
        default: // Türkçe varsayılan
            break  // IdentityScannerUIConfig zaten Türkçe varsayılanlarla gelir
        }

        // Sonuç panelini gösterme — sonuç coordinator üzerinden işleniyor
        ui.showsResultPanel = false

        return ui
    }

    // MARK: - Actions

    private func finish(with image: UIImage?) {
        guard let image = image else { return }
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
