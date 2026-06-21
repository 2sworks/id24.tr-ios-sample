// SDKDesignTokens.swift

import SwiftUI

// MARK: - Colors

enum IDColor {

    // MARK: Primary
    static let primary          = Color(hex: "#446EF7")
    static let primaryDark      = Color(hex: "#2C5BF6")
    static let primaryLight     = Color(hex: "#F0F5FF")
    static let primaryGradient  = Color(hex: "#446EF7")

    // MARK: Success
    static let success          = Color(hex: "#41D97F")
    static let successAlt       = Color(hex: "#56DD8C")
    static let successBright    = Color(hex: "#30D158")

    // MARK: Error
    static let error            = Color(hex: "#FF453A")

    // MARK: Ink (Metin)
    static let inkDarkest       = Color(hex: "#111827")
    static let inkDark          = Color(hex: "#1A1A1A")
    static let inkMid           = Color(hex: "#5C616F")
    static let inkLight         = Color(hex: "#A7AAB2")
    static let inkBorder        = Color(hex: "#E5E7EB")
    static let inkBackground    = Color(hex: "#F9FAFB")
    static let inkSurface       = Color(hex: "#F6F7F8")
    static let inkSubtitle      = Color(hex: "#9CA3AF")
    static let inkSecondaryText = Color(hex: "#9DA1A1")

    // MARK: Dark Mode
    static let darkBg           = Color(hex: "#111827")
    static let darkBgSecondary  = Color(hex: "#1F2533")
    static let darkMuted        = Color(hex: "#57637F")
    static let darkStepActive   = Color(hex: "#F0F5FF")
    static let darkStepPassive  = Color(hex: "#D9D9D933")

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
        scheme == .dark ? darkMuted : inkLight
    }
    static func adaptiveSubtitleContent(for scheme: ColorScheme) -> Color {
        scheme == .dark ? primaryLight : inkSubtitle
    }
    static func adaptiveBorder(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.08) : inkBorder
    }
}

// MARK: - Typography

enum IDFont {
    private static let familyName = "Inter"

    static func displayLarge(_ weight: Font.Weight = .bold) -> Font {
        .custom(familyName, size: 28).weight(weight)
    }
    static func displayMedium(_ weight: Font.Weight = .bold) -> Font {
        .custom(familyName, size: 24).weight(weight)
    }
    static func displaySmall(_ weight: Font.Weight = .bold) -> Font {
        .custom(familyName, size: 20).weight(weight)
    }
    static func bodyLarge(_ weight: Font.Weight = .semibold) -> Font {
        .custom(familyName, size: 18).weight(weight)
    }
    static func bodyMediumPlus(_ weight: Font.Weight = .medium) -> Font {
        .custom(familyName, size: 17).weight(weight)
    }
    static func bodyMedium(_ weight: Font.Weight = .medium) -> Font {
        .custom(familyName, size: 16).weight(weight)
    }
    static func bodyRegular(_ weight: Font.Weight = .medium) -> Font {
        .custom(familyName, size: 15).weight(weight)
    }
    static func bodySmall(_ weight: Font.Weight = .medium) -> Font {
        .custom(familyName, size: 14).weight(weight)
    }
    static func caption(_ weight: Font.Weight = .medium) -> Font {
        .custom(familyName, size: 13).weight(weight)
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
        case 6:  (r, g, b, a) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF, 255)
        case 8:  (r, g, b, a) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default: (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(.sRGB,
                  red:     Double(r) / 255,
                  green:   Double(g) / 255,
                  blue:    Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Preview: Colors

private struct ColorsPreview: View {
    @State private var filterHex = ""

    private let tokens: [(call: String, hex: String, color: Color)] = [
        ("IDColor.primary",        "#446EF7", IDColor.primary),
        ("IDColor.primaryDark",    "#2C5BF6", IDColor.primaryDark),
        ("IDColor.primaryLight",   "#F0F5FF", IDColor.primaryLight),
        ("IDColor.primaryGradient","#446EF7", IDColor.primaryGradient),
        ("IDColor.success",        "#41D97F", IDColor.success),
        ("IDColor.successAlt",     "#56DD8C", IDColor.successAlt),
        ("IDColor.successBright",  "#30D158", IDColor.successBright),
        ("IDColor.error",          "#FF453A", IDColor.error),
        ("IDColor.inkDarkest",     "#111827", IDColor.inkDarkest),
        ("IDColor.inkDark",        "#1A1A1A", IDColor.inkDark),
        ("IDColor.inkMid",         "#5C616F", IDColor.inkMid),
        ("IDColor.inkLight",       "#A7AAB2", IDColor.inkLight),
        ("IDColor.inkBorder",      "#E5E7EB", IDColor.inkBorder),
        ("IDColor.inkBackground",  "#F9FAFB", IDColor.inkBackground),
        ("IDColor.inkSurface",      "#F6F7F8",   IDColor.inkSurface),
        ("IDColor.inkSubtitle",     "#9CA3AF",   IDColor.inkSubtitle),
        ("IDColor.inkSecondaryText","#9DA1A1",   IDColor.inkSecondaryText),
        ("IDColor.darkBg",          "#111827",   IDColor.darkBg),
        ("IDColor.darkBgSecondary", "#1F2533",   IDColor.darkBgSecondary),
        ("IDColor.darkMuted",       "#57637F",   IDColor.darkMuted),
        ("IDColor.darkStepActive",  "#F0F5FF",   IDColor.darkStepActive),
        ("IDColor.darkStepPassive", "#D9D9D933", IDColor.darkStepPassive),
        ("IDColor.divider",         "#D1D5DB",   IDColor.divider),
    ]

    private var filtered: [(call: String, hex: String, color: Color)] {
        let query = filterHex.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "#", with: "")
            .lowercased()
        guard !query.isEmpty else { return tokens }
        return tokens.filter { $0.hex.replacingOccurrences(of: "#", with: "").lowercased().contains(query) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Arama
            HStack(spacing: IDSpacing.sm) {
                Image(systemName: "number")
                    .foregroundStyle(IDColor.inkMid)
                TextField("Hex ara — ör. 446EF7", text: $filterHex)
                    .font(.system(size: 14, design: .monospaced))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                if !filterHex.isEmpty {
                    Button { filterHex = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(IDColor.inkLight)
                    }
                }
            }
            .padding(IDSpacing.md)
            .background(IDColor.inkSurface, in: RoundedRectangle(cornerRadius: IDRadius.md))
            .padding([.horizontal, .top], IDSpacing.lg)
            .padding(.bottom, IDSpacing.sm)

            ScrollView {
                VStack(alignment: .leading, spacing: IDSpacing.sm) {
                    if filtered.isEmpty {
                        Text("Eşleşen renk yok")
                            .font(IDFont.bodyRegular())
                            .foregroundStyle(IDColor.inkMid)
                            .padding(.top, IDSpacing.xl)
                            .frame(maxWidth: .infinity)
                    } else {
                        previewSectionTitle("IDColor — Static")
                        ForEach(filtered, id: \.call) { token in
                            colorRow(token.call, token.hex, token.color)
                        }
                    }
                }
                .padding(IDSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Preview: Adaptive

private struct AdaptiveColorsPreview: View {
    @State private var filterHex = ""

    private let tokens: [(call: String, lightHex: String, darkHex: String, light: Color, dark: Color)] = [
        ("IDColor.adaptivePrimary(for:)",    "#446EF7", "#2C5BF6", IDColor.adaptivePrimary(for: .light),    IDColor.adaptivePrimary(for: .dark)),
        ("IDColor.adaptiveBackground(for:)", "#FFFFFF", "#111827", IDColor.adaptiveBackground(for: .light), IDColor.adaptiveBackground(for: .dark)),
        ("IDColor.adaptiveSurface(for:)",    "#F6F7F8", "#1F2533", IDColor.adaptiveSurface(for: .light),    IDColor.adaptiveSurface(for: .dark)),
        ("IDColor.adaptiveTitle(for:)",      "#111827", "#FFFFFF", IDColor.adaptiveTitle(for: .light),      IDColor.adaptiveTitle(for: .dark)),
        ("IDColor.adaptiveSubtitle(for:)",   "#A7AAB2", "#57637F", IDColor.adaptiveSubtitle(for: .light),   IDColor.adaptiveSubtitle(for: .dark)),
        ("IDColor.adaptiveSubtitleContent(for:)", "#9CA3AF", "#F0F5FF", IDColor.adaptiveSubtitleContent(for: .light), IDColor.adaptiveSubtitleContent(for: .dark)),
    ]

    private var filtered: [(call: String, lightHex: String, darkHex: String, light: Color, dark: Color)] {
        let query = filterHex.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "#", with: "")
            .lowercased()
        guard !query.isEmpty else { return tokens }
        return tokens.filter {
            $0.lightHex.replacingOccurrences(of: "#", with: "").lowercased().contains(query) ||
            $0.darkHex.replacingOccurrences(of: "#", with: "").lowercased().contains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: IDSpacing.sm) {
                Image(systemName: "number")
                    .foregroundStyle(IDColor.inkMid)
                TextField("Hex ara — ör. 446EF7", text: $filterHex)
                    .font(.system(size: 14, design: .monospaced))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                if !filterHex.isEmpty {
                    Button { filterHex = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(IDColor.inkLight)
                    }
                }
            }
            .padding(IDSpacing.md)
            .background(IDColor.inkSurface, in: RoundedRectangle(cornerRadius: IDRadius.md))
            .padding([.horizontal, .top], IDSpacing.lg)
            .padding(.bottom, IDSpacing.sm)

            ScrollView {
                VStack(alignment: .leading, spacing: IDSpacing.sm) {
                    if filtered.isEmpty {
                        Text("Eşleşen renk yok")
                            .font(IDFont.bodyRegular())
                            .foregroundStyle(IDColor.inkMid)
                            .padding(.top, IDSpacing.xl)
                            .frame(maxWidth: .infinity)
                    } else {
                        previewSectionTitle("IDColor — Adaptive(for: colorScheme)")

                        // Tablo sütun başlıkları
                        HStack(spacing: IDSpacing.md) {
                            Text("Light")
                                .font(IDFont.caption(.semibold))
                                .foregroundStyle(IDColor.inkMid)
                                .frame(width: 60, alignment: .center)
                            Text("Dark")
                                .font(IDFont.caption(.semibold))
                                .foregroundStyle(IDColor.inkMid)
                                .frame(width: 60, alignment: .center)
                            Spacer()
                        }
                        .padding(.bottom, IDSpacing.xs)

                        ForEach(filtered, id: \.call) { token in
                            adaptiveColorRow(token.call, token.lightHex, token.darkHex, token.light, token.dark)
                        }
                    }
                }
                .padding(IDSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Preview: Spacing

private struct SpacingPreview: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: IDSpacing.xl) {
                previewSectionTitle("IDSpacing")
                spacingRow("IDSpacing.xs",  IDSpacing.xs)
                spacingRow("IDSpacing.sm",  IDSpacing.sm)
                spacingRow("IDSpacing.md",  IDSpacing.md)
                spacingRow("IDSpacing.lg",  IDSpacing.lg)
                spacingRow("IDSpacing.xl",  IDSpacing.xl)
                spacingRow("IDSpacing.xxl", IDSpacing.xxl)
            }
            .padding(IDSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Preview: Corner Radius

private struct CornerRadiusPreview: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: IDSpacing.lg) {
                previewSectionTitle("IDRadius")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: IDSpacing.lg) {
                    radiusCell("IDRadius.sm",     IDRadius.sm)
                    radiusCell("IDRadius.md",     IDRadius.md)
                    radiusCell("IDRadius.lg",     IDRadius.lg)
                    radiusCell("IDRadius.xl",     IDRadius.xl)
                    radiusCell("IDRadius.card",   IDRadius.card)
                    radiusCell("IDRadius.pill",   IDRadius.pill)
                    radiusCell("IDRadius.circle", IDRadius.circle)
                }
            }
            .padding(IDSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Preview: Typography

private struct TypographyPreview: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: IDSpacing.sm) {
                previewSectionTitle("IDFont")
                typographyRow("IDFont.displayLarge()",   IDFont.displayLarge())
                typographyRow("IDFont.displayMedium()",  IDFont.displayMedium())
                typographyRow("IDFont.displaySmall()",   IDFont.displaySmall())
                Divider().padding(.vertical, IDSpacing.xs)
                typographyRow("IDFont.bodyLarge()",      IDFont.bodyLarge())
                typographyRow("IDFont.bodyMediumPlus()", IDFont.bodyMediumPlus())
                typographyRow("IDFont.bodyMedium()",     IDFont.bodyMedium())
                typographyRow("IDFont.bodyRegular()",    IDFont.bodyRegular())
                typographyRow("IDFont.bodySmall()",      IDFont.bodySmall())
                Divider().padding(.vertical, IDSpacing.xs)
                typographyRow("IDFont.caption()",        IDFont.caption())
            }
            .padding(IDSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Combined Preview

#Preview("Design Tokens") {
    TabView {
        ColorsPreview()
            .tabItem { Label("Colors", systemImage: "paintpalette") }
        AdaptiveColorsPreview()
            .tabItem { Label("Adaptive", systemImage: "circle.lefthalf.filled") }
        SpacingPreview()
            .tabItem { Label("Spacing", systemImage: "arrow.left.and.right") }
        CornerRadiusPreview()
            .tabItem { Label("Radius", systemImage: "square.on.circle") }
        TypographyPreview()
            .tabItem { Label("Type", systemImage: "textformat") }
    }
}

// MARK: - Shared Preview Helpers

@ViewBuilder
private func previewSectionTitle(_ title: String) -> some View {
    Text(title)
        .font(IDFont.caption(.semibold))
        .foregroundStyle(IDColor.primary)
        .padding(.horizontal, IDSpacing.sm)
        .padding(.vertical, IDSpacing.xs)
        .background(IDColor.primaryLight, in: RoundedRectangle(cornerRadius: IDRadius.sm))
        .padding(.bottom, IDSpacing.xs)
}

@ViewBuilder
private func colorRow(_ call: String, _ hex: String, _ color: Color) -> some View {
    HStack(spacing: IDSpacing.md) {
        RoundedRectangle(cornerRadius: IDRadius.sm)
            .fill(color)
            .frame(width: 44, height: 44)
            .overlay(RoundedRectangle(cornerRadius: IDRadius.sm).stroke(IDColor.inkBorder, lineWidth: 1))
        VStack(alignment: .leading, spacing: 2) {
            Text(call)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(IDColor.inkDark)
            Text(hex.uppercased())
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(IDColor.inkMid)
        }
        Spacer()
    }
}

@ViewBuilder
private func adaptiveColorRow(_ call: String, _ lightHex: String, _ darkHex: String, _ light: Color, _ dark: Color) -> some View {
    HStack(spacing: IDSpacing.md) {
        // Light kolonu (60pt — başlıkla hizalı)
        VStack(spacing: IDSpacing.xs) {
            RoundedRectangle(cornerRadius: IDRadius.sm)
                .fill(light)
                .frame(width: 44, height: 44)
                .overlay(RoundedRectangle(cornerRadius: IDRadius.sm).stroke(IDColor.inkBorder, lineWidth: 1))
            Text(lightHex.uppercased())
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(IDColor.inkMid)
        }
        .frame(width: 60, alignment: .center)

        // Dark kolonu (60pt — başlıkla hizalı)
        VStack(spacing: IDSpacing.xs) {
            RoundedRectangle(cornerRadius: IDRadius.sm)
                .fill(Color(hex: "#1C1C1E"))
                .frame(width: 44, height: 44)
                .overlay(RoundedRectangle(cornerRadius: IDRadius.sm).fill(dark).padding(4))
                .overlay(RoundedRectangle(cornerRadius: IDRadius.sm).stroke(Color(hex: "#3A3A3C"), lineWidth: 1))
            Text(darkHex.uppercased())
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(IDColor.inkMid)
        }
        .frame(width: 60, alignment: .center)

        // Token adı — sağda
        Text(call)
            .font(.system(size: 12, design: .monospaced))
            .foregroundStyle(IDColor.inkDark)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}


@ViewBuilder
private func spacingRow(_ call: String, _ value: CGFloat) -> some View {
    VStack(alignment: .leading, spacing: IDSpacing.sm) {

        // Token etiketi
        HStack(spacing: IDSpacing.xs) {
            Text(call)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(IDColor.inkDark)
            Text("→ \(Int(value))pt")
                .font(IDFont.caption(.semibold))
                .foregroundStyle(IDColor.primary)
        }

        // 1) Gap — iki element arasında spacing olarak uygulama
        VStack(alignment: .leading, spacing: IDSpacing.xs) {
            Text("gap / spacing")
                .font(IDFont.caption())
                .foregroundStyle(IDColor.inkMid)

            HStack(spacing: value) {
                RoundedRectangle(cornerRadius: IDRadius.sm)
                    .fill(IDColor.primary.opacity(0.15))
                    .frame(width: 56, height: 40)
                    .overlay(
                        Text("A").font(IDFont.bodySmall()).foregroundStyle(IDColor.primary)
                    )

                // gap göstergesi
                ZStack {
                    Rectangle()
                        .fill(IDColor.primary.opacity(0.08))
                        .frame(width: value, height: 40)
                    Rectangle()
                        .fill(IDColor.primary)
                        .frame(width: 1, height: 40)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Rectangle()
                        .fill(IDColor.primary)
                        .frame(width: 1, height: 40)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    Text("\(Int(value))")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(IDColor.primary)
                        .padding(.horizontal, 2)
                        .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 3))
                }
                .frame(width: 0)
                .zIndex(1)

                RoundedRectangle(cornerRadius: IDRadius.sm)
                    .fill(IDColor.primary.opacity(0.15))
                    .frame(width: 56, height: 40)
                    .overlay(
                        Text("B").font(IDFont.bodySmall()).foregroundStyle(IDColor.primary)
                    )

                Spacer()
            }
        }

        // 2) Padding — bir elemanın içinde padding olarak uygulama
        VStack(alignment: .leading, spacing: IDSpacing.xs) {
            Text("padding")
                .font(IDFont.caption())
                .foregroundStyle(IDColor.inkMid)

            ZStack(alignment: .topLeading) {
                // Padding alanı
                RoundedRectangle(cornerRadius: IDRadius.sm)
                    .fill(IDColor.primary.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: IDRadius.sm)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                            .foregroundStyle(IDColor.primary.opacity(0.4))
                    )

                // İç içerik
                RoundedRectangle(cornerRadius: IDRadius.sm - 2)
                    .fill(IDColor.primary.opacity(0.2))
                    .overlay(
                        Text("Content").font(IDFont.bodySmall(.semibold)).foregroundStyle(IDColor.primary)
                    )
                    .padding(value)
            }
            .frame(height: 40 + value * 2)
        }
    }
    .padding(IDSpacing.md)
    .background(IDColor.inkSurface, in: RoundedRectangle(cornerRadius: IDRadius.md))
}

@ViewBuilder
private func radiusCell(_ call: String, _ radius: CGFloat) -> some View {
    VStack(spacing: IDSpacing.sm) {
        RoundedRectangle(cornerRadius: min(radius, 36))
            .fill(IDColor.primaryLight)
            .frame(height: 60)
            .overlay(RoundedRectangle(cornerRadius: min(radius, 36)).stroke(IDColor.primary.opacity(0.4), lineWidth: 1.5))
        Text(call)
            .font(.system(size: 10, design: .monospaced))
            .foregroundStyle(IDColor.inkDark)
            .multilineTextAlignment(.center)
        Text(radius >= 9999 ? "∞" : "\(Int(radius))pt")
            .font(IDFont.caption())
            .foregroundStyle(IDColor.inkMid)
    }
}

@ViewBuilder
private func typographyRow(_ call: String, _ font: Font) -> some View {
    VStack(alignment: .leading, spacing: 2) {
        Text(call)
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(IDColor.primary.opacity(0.7))
        HStack {
            Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit.")
                .font(font)
                .foregroundStyle(IDColor.inkDark)
            Spacer()
        }
    }
    .padding(.bottom, IDSpacing.xs)
}
