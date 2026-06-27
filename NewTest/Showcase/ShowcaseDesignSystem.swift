//
//  ShowcaseDesignSystem.swift
//  NewTest
//
//  SDK'nın TASARIM SİSTEMİ yetenekleri — modüllerin ötesinde, SDK'nın sunduğu
//  ortak UI primitifleri. Geliştirici bunları görüp kendi temasını/override'ını kurar:
//    • Renkler   → IDColor / SDKTheme.shared.colors
//    • Tipografi → IDFont   / SDKTheme.shared.fonts (registerFont)
//    • Nav Bar   → SDKNavigationBar (5 stil)
//    • Buton     → SDKButton (4 stil + durumlar)
//

import SwiftUI
import IdentifySDK

// MARK: - Renkler

struct ColorsShowcaseView: View {
    @Environment(\.colorScheme) private var colorScheme

    private var swatches: [(String, Color)] {
        [
            ("primary", IDColor.primary), ("primaryDark", IDColor.primaryDark), ("primaryLight", IDColor.primaryLight),
            ("success", IDColor.success), ("successBright", IDColor.successBright), ("error", IDColor.error),
            ("accentPurple", IDColor.accentPurple), ("accentTeal", IDColor.accentTeal),
            ("inkDarkest", IDColor.inkDarkest), ("inkMid", IDColor.inkMid), ("inkLight", IDColor.inkLight),
            ("inkBorder", IDColor.inkBorder), ("inkSurface", IDColor.inkSurface), ("divider", IDColor.divider)
        ]
    }
    private let cols = [GridItem(.adaptive(minimum: 120), spacing: IDSpacing.md)]

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: cols, spacing: IDSpacing.md) {
                ForEach(swatches, id: \.0) { name, color in
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: IDRadius.md)
                            .fill(color)
                            .frame(height: 56)
                            .overlay(RoundedRectangle(cornerRadius: IDRadius.md).stroke(IDColor.inkBorder, lineWidth: 1))
                        Text("IDColor." + name)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                            .lineLimit(1).minimumScaleFactor(0.7)
                    }
                }
            }
            .padding(IDSpacing.lg)
        }
        .background(IDColor.adaptiveBackground(for: colorScheme).ignoresSafeArea())
    }
}

// MARK: - Tipografi

struct FontsShowcaseView: View {
    @Environment(\.colorScheme) private var colorScheme

    private var scale: [(String, Font)] {
        [
            ("displayLarge", IDFont.displayLarge()), ("displayMedium", IDFont.displayMedium()),
            ("displaySmall", IDFont.displaySmall()), ("bodyLarge", IDFont.bodyLarge()),
            ("bodyMedium", IDFont.bodyMedium()), ("bodyRegular", IDFont.bodyRegular()),
            ("bodySmall", IDFont.bodySmall()), ("caption", IDFont.caption())
        ]
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: IDSpacing.lg) {
                ForEach(scale, id: \.0) { name, font in
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Identify SDK")
                            .font(font)
                            .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                        Text("IDFont." + name + "  (aktif aile: " + (SDKTheme.shared.fonts.familyName ?? "sistem") + ")")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(IDSpacing.xl)
        }
        .background(IDColor.adaptiveBackground(for: colorScheme).ignoresSafeArea())
    }
}

// MARK: - Navigation Bar

struct NavBarShowcaseView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: IDSpacing.xl) {
                labeled(".login") {
                    SDKNavigationBar(style: .login, onMenu: {})
                }
                labeled(".module") {
                    SDKNavigationBar(style: .module, title: "Kimlik Doğrulama", subtitle: "Adım 2/5", onBack: {})
                }
                labeled(".progress(steps: 5, current: 2)") {
                    SDKNavigationBar(style: .progress(steps: 5, current: 2), title: "Süreç", onBack: {})
                        .background(IDColor.primary)
                }
                labeled(".overlay (görüntü üstü)") {
                    SDKNavigationBar(style: .overlay, onBack: {}, onHelp: {})
                        .frame(height: 120)
                        .background(IDColor.inkDarkest)
                }
            }
            .padding(.vertical, IDSpacing.lg)
        }
        .background(IDColor.adaptiveBackground(for: colorScheme).ignoresSafeArea())
    }

    private func labeled<V: View>(_ title: String, @ViewBuilder _ content: () -> V) -> some View {
        VStack(alignment: .leading, spacing: IDSpacing.sm) {
            Text(title)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                .padding(.horizontal, IDSpacing.lg)
            content()
        }
    }
}

// MARK: - Buton

struct ButtonsShowcaseView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: IDSpacing.lg) {
                SDKButton(title: ".primary", style: .primary) {}
                SDKButton(title: ".secondary", style: .secondary) {}
                SDKButton(title: ".success", style: .success) {}
                SDKButton(title: ".cancel", style: .cancel) {}
                SDKButton(title: "isLoading", style: .primary, isLoading: true) {}
                SDKButton(title: "isDisabled", style: .primary, isDisabled: true) {}
            }
            .padding(IDSpacing.xl)
        }
        .background(IDColor.adaptiveBackground(for: colorScheme).ignoresSafeArea())
    }
}

// MARK: - Uyarı (Alert)

struct AlertsShowcaseView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var active: IDAlertModel?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: IDSpacing.lg) {
                SDKButton(title: ".info — tek buton", style: .secondary) {
                    active = IDAlertModel(
                        type: .info, title: "Bilgi",
                        message: "Bu işlem geri alınamaz. Devam etmek istediğinizden emin misiniz?",
                        actions: [IDAlertAction(title: "Tamam", style: .primary)]
                    )
                }
                SDKButton(title: ".error — iki buton", style: .cancel) {
                    active = IDAlertModel(
                        type: .error, title: "Bağlantı Hatası",
                        message: "Sunucuya ulaşılamıyor. Lütfen internet bağlantınızı kontrol edin.",
                        actions: [
                            IDAlertAction(title: "İptal", style: .cancel),
                            IDAlertAction(title: "Tekrar Dene", style: .primary)
                        ]
                    )
                }
                SDKButton(title: ".success", style: .success) {
                    active = IDAlertModel(
                        type: .success, title: "Kimlik Doğrulandı",
                        message: "Kimlik doğrulama işleminiz başarıyla tamamlandı.",
                        actions: [IDAlertAction(title: "Devam Et", style: .primary)]
                    )
                }
                SDKButton(title: ".normal — destructive", style: .primary) {
                    active = IDAlertModel(
                        type: .normal, title: "Görüşmeyi bitir",
                        message: "Görüşmeyi sonlandırmak istediğinize emin misiniz?",
                        actions: [
                            IDAlertAction(title: "Vazgeç", style: .cancel),
                            IDAlertAction(title: "Bitir", style: .destructive)
                        ]
                    )
                }
            }
            .padding(IDSpacing.xl)
        }
        .background(IDColor.adaptiveBackground(for: colorScheme).ignoresSafeArea())
        .idAlert(item: $active)
    }
}

// MARK: - Previews
#Preview("Renkler") { ColorsShowcaseView() }
#Preview("Tipografi") { FontsShowcaseView() }
#Preview("Nav Bar") { NavBarShowcaseView() }
#Preview("Buton") { ButtonsShowcaseView() }
#Preview("Uyarı") { AlertsShowcaseView() }
