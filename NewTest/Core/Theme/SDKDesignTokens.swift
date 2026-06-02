// SDKDesignTokens.swift

import SwiftUI

// MARK: - Colors

enum IDColor {

    // MARK: Primary
    static let primary          = Color(hex: "#446EF7")   // Ana marka rengi, butonlar
    static let primaryDark      = Color(hex: "#2C5BF6")   // Gradient, hover
    static let primaryLight     = Color(hex: "#F0F5FF")   // Arka planlar, vurgular

    // MARK: Success
    static let success          = Color(hex: "#41D97F")   // Onay, başarı durumları
    static let successAlt       = Color(hex: "#56DD8C")   // Bildirimler, rozetler
    static let successBright    = Color(hex: "#30D158")   // İkonlar, vurgular

    // MARK: Error
    static let error            = Color(hex: "#FF453A")   // Hatalar, silme

    // MARK: Ink (Metin)
    static let inkDarkest       = Color(hex: "#111827")   // Birincil metin (light mode)
    static let inkDark          = Color(hex: "#1A1A1A")   // Koyu varyant
    static let inkMid           = Color(hex: "#5C616F")   // İkincil metin
    static let inkLight         = Color(hex: "#A7AAB2")   // Yer tutucu, devre dışı
    static let inkBorder        = Color(hex: "#E5E7EB")   // Kenarlıklar, ayraçlar
    static let inkBackground    = Color(hex: "#F9FAFB")   // Sayfa arka planı
    static let inkSurface       = Color(hex: "#F6F7F8")   // Kart yüzeyi

    // MARK: Dark Mode — Arka Plan Katmanları
    static let darkBg           = Color(hex: "#111827")   // Ana arka plan
    static let darkBgSecondary  = Color(hex: "#1F2533")   // İkincil katman
    static let darkMuted        = Color(hex: "#57637F")   // Susturulmuş/pasif

    // MARK: Misc
    static let divider          = Color(hex: "#D1D5DB")
}

// MARK: - Adaptive (Light / Dark)

extension IDColor {
    static func adaptivePrimary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? primaryDark : primary
    }

    static func adaptiveBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? darkBg : .white
    }

    static func adaptiveSurface(for scheme: ColorScheme) -> Color {
        scheme == .dark ? darkBgSecondary : inkSurface
    }

    static func adaptiveTitle(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .white : inkDarkest
    }

    static func adaptiveSubtitle(for scheme: ColorScheme) -> Color {
        scheme == .dark ? darkMuted : inkMid
    }
}

// MARK: - Typography

enum IDFont {
    // Display — InterDisplay, büyük başlıklar
    static func displayLarge(_ weight: Font.Weight = .bold) -> Font {
        .custom(interDisplayName(weight), size: 28)
    }
    static func displayMedium(_ weight: Font.Weight = .bold) -> Font {
        .custom(interDisplayName(weight), size: 24)
    }
    static func displaySmall(_ weight: Font.Weight = .bold) -> Font {
        .custom(interDisplayName(weight), size: 20)
    }

    // Body — Inter, içerik metinleri
    static func bodyLarge(_ weight: Font.Weight = .semibold) -> Font {
        .custom(interName(weight), size: 18)
    }
    static func bodyMediumLg(_ weight: Font.Weight = .medium) -> Font {
        .custom(interName(weight), size: 17)
    }
    static func bodyMedium(_ weight: Font.Weight = .medium) -> Font {
        .custom(interName(weight), size: 16)
    }
    static func body(_ weight: Font.Weight = .medium) -> Font {
        .custom(interName(weight), size: 15)
    }
    static func bodySmall(_ weight: Font.Weight = .medium) -> Font {
        .custom(interName(weight), size: 14)
    }
    static func caption(_ weight: Font.Weight = .medium) -> Font {
        .custom(interName(weight), size: 13)
    }

    // MARK: Font name helpers

    static func interName(_ weight: Font.Weight) -> String {
        switch weight {
        case .bold:     return "Inter-Bold"
        case .semibold: return "Inter-SemiBold"
        case .medium:   return "Inter-Medium"
        case .heavy:    return "Inter-ExtraBold"
        default:        return "Inter-Regular"
        }
    }

    static func interDisplayName(_ weight: Font.Weight) -> String {
        switch weight {
        case .bold:     return "InterDisplay-Bold"
        case .semibold: return "InterDisplay-SemiBold"
        case .medium:   return "InterDisplay-Medium"
        default:        return "InterDisplay-Regular"
        }
    }
}

// MARK: - Spacing

enum IDSpacing {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 12
    static let lg:  CGFloat = 16
    static let xl:  CGFloat = 24
    static let xxl: CGFloat = 32
}

// MARK: - Corner Radius

enum IDRadius {
    static let sm:     CGFloat = 8
    static let md:     CGFloat = 12
    static let lg:     CGFloat = 16
    static let xl:     CGFloat = 24
    static let card:   CGFloat = 36
    static let pill:   CGFloat = 40
    static let circle: CGFloat = 9999
}

// MARK: - Color(hex:) initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 6:
            (r, g, b, a) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF, 255)
        case 8:
            (r, g, b, a) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(
            .sRGB,
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

#Preview("Design Tokens") {
    ScrollView {
        VStack(alignment: .leading, spacing: IDSpacing.xl) {

            // MARK: Colors
            Group {
                Text("Colors")
                    .font(IDFont.displaySmall())

                colorRow("primary", IDColor.primary)
                colorRow("primaryDark", IDColor.primaryDark)
                colorRow("primaryLight", IDColor.primaryLight)
                colorRow("success", IDColor.success)
                colorRow("successAlt", IDColor.successAlt)
                colorRow("successBright", IDColor.successBright)
                colorRow("error", IDColor.error)
                colorRow("inkDarkest", IDColor.inkDarkest)
                colorRow("inkDark", IDColor.inkDark)
                colorRow("inkMid", IDColor.inkMid)
                colorRow("inkLight", IDColor.inkLight)
                colorRow("inkBorder", IDColor.inkBorder)
                colorRow("inkBackground", IDColor.inkBackground)
                colorRow("inkSurface", IDColor.inkSurface)
                colorRow("darkBg", IDColor.darkBg)
                colorRow("darkBgSecondary", IDColor.darkBgSecondary)
                colorRow("darkMuted", IDColor.darkMuted)
                colorRow("divider", IDColor.divider)
            }

            Divider()

            // MARK: Typography
            Group {
                Text("Typography")
                    .font(IDFont.displaySmall())

                Text("displayLarge").font(IDFont.displayLarge())
                Text("displayMedium").font(IDFont.displayMedium())
                Text("displaySmall").font(IDFont.displaySmall())
                Text("bodyLarge").font(IDFont.bodyLarge())
                Text("bodyMediumLg").font(IDFont.bodyMediumLg())
                Text("bodyMedium").font(IDFont.bodyMedium())
                Text("body").font(IDFont.body())
                Text("bodySmall").font(IDFont.bodySmall())
                Text("caption").font(IDFont.caption())
            }
        }
        .padding(IDSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@ViewBuilder
private func colorRow(_ name: String, _ color: Color) -> some View {
    HStack(spacing: IDSpacing.md) {
        RoundedRectangle(cornerRadius: IDRadius.sm)
            .fill(color)
            .frame(width: 44, height: 44)
            .overlay(
                RoundedRectangle(cornerRadius: IDRadius.sm)
                    .stroke(IDColor.inkBorder, lineWidth: 1)
            )
        Text(name)
            .font(IDFont.body())
        Spacer()
    }
}
