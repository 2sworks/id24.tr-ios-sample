//
//  SwlExample.swift
//  NewTest
//
//  SDK "Canlılıkla Selfie" (ARKit yüz canlılığı) modülü — ENTEGRASYON REHBERİ.
//  1) SwlExample         → SDK hazır ekranı (ARKit ARFaceTracking)
//  2) SwlExampleThemed   → tema override
//  3) SwlExampleReplaced → kendi başlık/temanı bindirip SDK ekranını kullanma
//
//  Devreye alma: registry.override(.selfieWithLiveness) { SwlExampleReplaced() }
//  ⚠️ ARFaceTracking yalnızca TrueDepth kameralı GERÇEK cihazda çalışır (simülatör değil).
//

import SwiftUI
import IdentifySDK

// MARK: - 1) Varsayılan
struct SwlExample: View {
    var body: some View { SDKSelfieWithLivenessView() }
}

// MARK: - 2) Tema
struct SwlExampleThemed: View {
    var body: some View {
        SDKSelfieWithLivenessView().showcaseThemed(primary: IDColor.accentPurple)
    }
}

// MARK: - 3) Tam replace — env-config ile başlık/tema bindirme
struct SwlExampleReplaced: View {
    @EnvironmentObject private var config: SwlConfig

    var body: some View {
        ZStack(alignment: .top) {
            SDKSelfieWithLivenessView()
            Text(config.headerTitle)
                .font(IDFont.bodySmall(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, IDSpacing.md)
                .padding(.vertical, 6)
                .background(config.accentColor.opacity(0.85), in: Capsule())
                .padding(.top, 60)
        }
    }
}

// MARK: - Previews
#Preview("Canlılıkla Selfie — Varsayılan") { SwlExample().showcaseHost() }
#Preview("Canlılıkla Selfie — Tema") { SwlExampleThemed().showcaseHost() }
#Preview("Canlılıkla Selfie — Tam Replace") {
    SwlExampleReplaced().showcaseHost().environmentObject(SwlConfig.preview)
}
