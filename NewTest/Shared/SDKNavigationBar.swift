// SDKNavigationBar.swift
// NewTest

import SwiftUI

// MARK: - SDKNavigationBar

struct SDKNavigationBar: View {

    // MARK: - Style

    enum Style {
        /// Login screen: menu ← logo → trailing (flag / custom)
        case login
        /// Module / detail screen without progress: ← back | logo + title + subtitle | trailing
        case module
        /// Module screen with step-progress bar on a solid coloured background (always white text)
        case progress(steps: Int, current: Int)
        /// Module screen with step-progress bar, transparent background (adaptive text + coloured dots)
        case progressClear(steps: Int, current: Int)
        /// Camera / scan overlay: black→clear top gradient, ← back | logo | help?
        case overlay
    }

    // MARK: - Parameters

    let style: Style
    var title: String = ""
    var subtitle: String = ""
    var onBack: (() -> Void)? = nil
    var onMenu: (() -> Void)? = nil
    var onHelp: (() -> Void)? = nil
    /// Optional right-side content. Pass AnyView(…) from the call site.
    var trailing: AnyView? = nil

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        switch style {
        case .login:
            loginLayout
                .frame(height: 56)
                .padding(.horizontal, IDSpacing.lg)

        case .module:
            moduleLayout
                .frame(height: 56)
                .padding(.horizontal, IDSpacing.lg)

        case .progress(let steps, let current):
            progressContainer(steps: steps, current: current, forceWhite: true)

        case .progressClear(let steps, let current):
            progressContainer(steps: steps, current: current, forceWhite: false)

        case .overlay:
            overlayLayout
        }
    }

    // MARK: - Login Layout
    // Hamburger left | "identify" text logo center | trailing right

    private var loginLayout: some View {
        HStack {
            circleButton(systemName: "line.horizontal.3") { onMenu?() }

            Spacer()

            Image(.icIdentifyLogoText)
                .renderingMode(.template)
                .foregroundColor(colorScheme == .dark ? .white : IDColor.inkDark)

            Spacer()

            if let trailing {
                trailing
            } else {
                Color.clear.frame(width: 36, height: 36)
            }
        }
    }

    // MARK: - Module Layout
    // ← back | [logo circle + title + subtitle] | trailing

    private var moduleLayout: some View {
        HStack(spacing: IDSpacing.md) {
            circleButton(systemName: "chevron.left") { onBack?() }

            HStack(spacing: IDSpacing.sm) {
                logoCircle
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(IDFont.bodyMedium(.semibold))
                        .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                        .lineLimit(1)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(IDFont.caption(.regular))
                            .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let trailing {
                trailing
            }
        }
    }

    // MARK: - Progress Container
    // Header row + progress strip; forceWhite drives text/dot colour

    private func progressContainer(steps: Int, current: Int, forceWhite: Bool) -> some View {
        VStack(spacing: IDSpacing.sm) {
            progressHeaderRow(forceWhite: forceWhite)
                .frame(height: 56)
                .padding(.horizontal, IDSpacing.lg)
            progressStrip(steps: steps, current: current, forceWhite: forceWhite)
                .padding(.horizontal, IDSpacing.lg)
        }
        .padding(.bottom, IDSpacing.sm)
    }

    private func progressHeaderRow(forceWhite: Bool) -> some View {
        ZStack(alignment: .leading) {
            // Centre: logo circle + title + subtitle
            HStack(spacing: IDSpacing.sm) {
                logoCircle
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(IDFont.bodyMedium(.semibold))
                        .foregroundColor(forceWhite ? .white : IDColor.adaptiveTitle(for: colorScheme))
                        .lineLimit(1)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(IDFont.caption(.regular))
                            .foregroundColor(forceWhite ? .white.opacity(0.75) : IDColor.adaptiveSubtitle(for: colorScheme))
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            // Left: bare chevron (no circle), always white on solid bg
            Button { onBack?() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(forceWhite ? .white : IDColor.adaptiveTitle(for: colorScheme))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
    }

    private func progressStrip(steps: Int, current: Int, forceWhite: Bool) -> some View {
        let safeSteps = max(1, steps)
        return HStack(spacing: 6) {
            ForEach(0..<safeSteps, id: \.self) { i in
                Capsule()
                    .fill(
                        i < current
                            ? (forceWhite ? Color.white            : IDColor.adaptivePrimary(for: colorScheme))
                            : (forceWhite ? Color.white.opacity(0.35) : IDColor.inkBorder)
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 6)
            }
        }
    }

    // MARK: - Overlay Layout
    // Black → clear top gradient | ← back | logo | help?

    private var overlayLayout: some View {
        LinearGradient(
            colors: [.black.opacity(0.72), .black.opacity(0)],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 130)
        .overlay(alignment: .top) {
            HStack {
                circleButton(
                    systemName: "chevron.left",
                    tint: .white,
                    fill: Color.white.opacity(0.15),
                    border: Color.white.opacity(0.2)
                ) { onBack?() }

                Spacer()

                Image(.icIdentifyLogoText)
                    .renderingMode(.template)
                    .foregroundColor(.white)

                Spacer()

                if let onHelp {
                    circleButton(
                        systemName: "questionmark",
                        tint: .white,
                        fill: Color.white.opacity(0.15),
                        border: Color.white.opacity(0.2)
                    ) { onHelp() }
                } else {
                    Color.clear.frame(width: 36, height: 36)
                }
            }
            .frame(height: 56)
            .padding(.horizontal, IDSpacing.lg)
            .padding(.top, IDSpacing.sm)
        }
    }

    // MARK: - Circle Button

    private func circleButton(
        systemName: String,
        tint: Color? = nil,
        fill: Color? = nil,
        border: Color? = nil,
        action: @escaping () -> Void
    ) -> some View {
        let resolvedTint   = tint   ?? (colorScheme == .dark ? Color.white         : IDColor.inkDark)
        let resolvedFill   = fill   ?? (colorScheme == .dark ? Color.white.opacity(0.1) : Color(.systemGray6))
        let resolvedBorder = border ?? (colorScheme == .dark ? Color.white.opacity(0.08) : Color(.systemGray4))
        return Button(action: action) {
            ZStack {
                Circle()
                    .fill(resolvedFill)
                    .overlay(Circle().stroke(resolvedBorder, lineWidth: 1))
                Image(systemName: systemName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(resolvedTint)
            }
            .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Logo Circle

    private var logoCircle: some View {
        Image(colorScheme == .dark ? "ic_lang_button_dark" : "ic_lang_button_light")
            .resizable()
            .scaledToFit()
            .frame(width: 40, height: 40)
    }
}

// MARK: - Previews

#Preview("Login — Light") {
    VStack(spacing: 0) {
        SDKNavigationBar(
            style: .login,
            onMenu: {},
            trailing: AnyView(
                Button {} label: {
                    ZStack {
                        Circle().fill(Color(.systemGray6))
                            .overlay(Circle().stroke(Color(.systemGray4), lineWidth: 1))
                        Image(.tr)
                    }
                    .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
            )
        )
        Spacer()
    }
    .background(Color.white)
}

#Preview("Login — Dark") {
    VStack(spacing: 0) {
        SDKNavigationBar(
            style: .login,
            onMenu: {},
            trailing: AnyView(
                Button {} label: {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.1))
                            .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))
                        Image(.tr)
                    }
                    .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
            )
        )
        Spacer()
    }
    .background(IDColor.darkBg)
    .preferredColorScheme(.dark)
}

#Preview("Module — Light") {
    VStack(spacing: 0) {
        SDKNavigationBar(
            style: .module,
            title: "Modül Seçimi",
            subtitle: "Modül listesi aşağıdaki gibidir",
            onBack: {},
            trailing: AnyView(
                Button {} label: {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Edit")
                            .font(IDFont.caption(.semibold))
                    }
                    .foregroundColor(IDColor.primary)
                    .padding(.horizontal, IDSpacing.md)
                    .padding(.vertical, IDSpacing.xs)
                    .background(IDColor.primaryLight, in: Capsule())
                }
                .buttonStyle(.plain)
            )
        )
        Spacer()
    }
    .background(Color.white)
}

#Preview("Module — Dark") {
    VStack(spacing: 0) {
        SDKNavigationBar(
            style: .module,
            title: "Modül Seçimi",
            subtitle: "Modül listesi aşağıdaki gibidir",
            onBack: {}
        )
        Spacer()
    }
    .background(IDColor.darkBg)
    .preferredColorScheme(.dark)
}

#Preview("Progress — Dark (solid bg)") {
    VStack(spacing: 0) {
        SDKNavigationBar(
            style: .progress(steps: 4, current: 2),
            title: "İkametgah Doğrulama",
            subtitle: "Adresinizi doğrulamamıza yardımcı olun",
            onBack: {}
        )
        Spacer()
    }
    .background(IDColor.darkBg)
    .preferredColorScheme(.dark)
}

#Preview("Progress — Light (solid bg)") {
    VStack(spacing: 0) {
        SDKNavigationBar(
            style: .progress(steps: 4, current: 2),
            title: "İkametgah Doğrulama",
            subtitle: "Adresinizi doğrulamamıza yardımcı olun",
            onBack: {}
        )
        Spacer()
    }
    .background(IDColor.primary)
}

#Preview("ProgressClear — Light") {
    VStack(spacing: 0) {
        SDKNavigationBar(
            style: .progressClear(steps: 4, current: 1),
            title: "Sunucu Seçimi",
            subtitle: "Test etmek istediğiniz ortamı seçin",
            onBack: {}
        )
        Spacer()
    }
    .background(Color.white)
}

#Preview("ProgressClear — Dark") {
    VStack(spacing: 0) {
        SDKNavigationBar(
            style: .progressClear(steps: 4, current: 1),
            title: "Sunucu Seçimi",
            subtitle: "Test etmek istediğiniz ortamı seçin",
            onBack: {}
        )
        Spacer()
    }
    .background(IDColor.darkBgSecondary)
    .preferredColorScheme(.dark)
}

#Preview("Overlay — No Help") {
    ZStack(alignment: .top) {
        Color.gray.opacity(0.4).ignoresSafeArea()
        SDKNavigationBar(
            style: .overlay,
            onBack: {}
        )
    }
}

#Preview("Overlay — With Help") {
    ZStack(alignment: .top) {
        Color.gray.opacity(0.4).ignoresSafeArea()
        SDKNavigationBar(
            style: .overlay,
            onBack: {},
            onHelp: {}
        )
    }
}
