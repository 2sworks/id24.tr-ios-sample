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
            circleButton(image: Image(.hamburger)) { onMenu?() }

            Spacer()

            Image(.icIdentifyLogoText)

            Spacer()

            if let trailing {
                trailing
            } else {
                Color.clear.frame(width: 36, height: 36)
            }
        }
    }

    // MARK: - Module Layout
    // ← back (bare) | [logo circle + title + subtitle] | trailing

    private var moduleLayout: some View {
        HStack(spacing: IDSpacing.md) {
            Button { onBack?() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)

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
        .padding(.bottom, IDSpacing.lg)
    }

    private func progressHeaderRow(forceWhite: Bool) -> some View {
        HStack(spacing: IDSpacing.md) {
            Button { onBack?() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(forceWhite ? .white : IDColor.adaptiveTitle(for: colorScheme))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)

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

            Spacer()
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

    private var overlayLayout: some View {
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

            if let trailing {
                trailing
            } else if let onHelp {
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
        .background(alignment: .top) {
            LinearGradient(
                colors: [.black.opacity(0.72), .black.opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 130)
            .ignoresSafeArea(edges: .top)
        }
    }

    // MARK: - Circle Button

    private func circleButton(
        image: Image,
        tint: Color? = nil,
        fill: Color? = nil,
        border: Color? = nil,
        action: @escaping () -> Void
    ) -> some View {
        let resolvedTint   = tint   ?? (IDColor.adaptiveTitle(for: colorScheme))
        let resolvedFill   = fill   ?? (IDColor.adaptiveSurface(for: colorScheme))
        let resolvedBorder = border ?? (IDColor.adaptiveSurface(for: colorScheme))
        return Button(action: action) {
            ZStack {
                Circle()
                    .fill(resolvedFill)
                    .overlay(Circle().stroke(resolvedBorder, lineWidth: 1))
                image
                    .renderingMode(.template)
                    .foregroundColor(resolvedTint)
            }
            .frame(width: 48, height: 48)
        }
        .buttonStyle(.plain)
    }

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
                        Image("turkey")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 22, height: 22)
                            .clipShape(Circle())
                    }
                    .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
            )
        )
        Spacer()
    }
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
