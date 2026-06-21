import SwiftUI
import UIKit

// MARK: - SDKButtonStyle

enum SDKButtonStyle {
    case primary
    case cancel
    case secondary
    case success
}

// MARK: - SDKButton

struct SDKButton: View {
    let title: String
    var style: SDKButtonStyle = .primary
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            HStack(spacing: IDSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                        .scaleEffect(0.9)
                }
                Text(title)
                    .font(IDFont.bodyMedium(.semibold))
                    .foregroundColor(foregroundColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, IDSpacing.lg)
            .background(
                Capsule()
                    .fill(isDisabled ? backgroundColor.opacity(0.45) : backgroundColor)
            )
        }
        .buttonStyle(SDKPressButtonStyle())
        .disabled(isDisabled || isLoading)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:   return IDColor.primary
        case .cancel:    return IDColor.error
        case .secondary: return IDColor.adaptiveSurface(for: colorScheme)
        case .success:   return IDColor.successBright
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary, .cancel, .success: return .white
        case .secondary:                  return IDColor.adaptiveTitle(for: colorScheme)
        }
    }
}

// MARK: - SDKPressButtonStyle

private struct SDKPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            Group {
                Text("Normal").font(.caption).foregroundStyle(.secondary)
                SDKButton(title: "Primary", style: .primary) {}
                SDKButton(title: "Cancel", style: .cancel) {}
                SDKButton(title: "Secondary", style: .secondary) {}
                SDKButton(title: "Success", style: .success) {}
            }
            Group {
                Text("Loading").font(.caption).foregroundStyle(.secondary)
                SDKButton(title: "Primary", style: .primary, isLoading: true) {}
                SDKButton(title: "Cancel", style: .cancel, isLoading: true) {}
                SDKButton(title: "Secondary", style: .secondary, isLoading: true) {}
                SDKButton(title: "Success", style: .success, isLoading: true) {}
            }
            Group {
                Text("Disabled").font(.caption).foregroundStyle(.secondary)
                SDKButton(title: "Primary", style: .primary, isDisabled: true) {}
                SDKButton(title: "Cancel", style: .cancel, isDisabled: true) {}
                SDKButton(title: "Secondary", style: .secondary, isDisabled: true) {}
                SDKButton(title: "Success", style: .success, isDisabled: true) {}
            }
        }
        .padding()
    }
}
