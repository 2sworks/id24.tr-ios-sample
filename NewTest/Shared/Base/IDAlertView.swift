import SwiftUI

// MARK: - IDAlertType

enum IDAlertType {
    case normal
    case error
    case info
    case success
}

extension IDAlertType {
    var iconName: String {
        switch self {
        case .normal:  return "exclamationmark.circle.fill"
        case .error:   return "xmark.circle.fill"
        case .info:    return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .normal:  return IDColor.inkMid
        case .error:   return IDColor.error
        case .info:    return IDColor.primary
        case .success: return IDColor.success
        }
    }
}

// MARK: - IDAlertActionStyle

enum IDAlertActionStyle {
    case primary
    case cancel
    case destructive
}

// MARK: - IDAlertAction

struct IDAlertAction: Identifiable {
    let id = UUID()
    let title: String
    let style: IDAlertActionStyle
    var action: (() -> Void)?

    init(title: String, style: IDAlertActionStyle = .primary, action: (() -> Void)? = nil) {
        self.title = title
        self.style = style
        self.action = action
    }
}

// MARK: - IDAlertModel

struct IDAlertModel: Identifiable {
    let id = UUID()
    let type: IDAlertType
    let title: String
    let message: String
    let actions: [IDAlertAction]

    init(
        type: IDAlertType = .normal,
        title: String,
        message: String,
        actions: [IDAlertAction]
    ) {
        self.type = type
        self.title = title
        self.message = message
        self.actions = actions
    }
}

extension IDAlertModel: Equatable {
    static func == (lhs: IDAlertModel, rhs: IDAlertModel) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - IDAlertPopup

private struct IDAlertPopup: View {
    @Environment(\.colorScheme) private var colorScheme

    let model: IDAlertModel
    let dismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            iconSection

            Text(model.title)
                .font(IDFont.displaySmall(.semibold))
                .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, IDSpacing.xl)

            Text(model.message)
                .font(IDFont.bodyRegular(.regular))
                .foregroundColor(IDColor.adaptiveSubtitleContent(for: colorScheme))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, IDSpacing.xl)
                .padding(.top, IDSpacing.sm)
                .padding(.bottom, IDSpacing.xl)

            Rectangle()
                .fill(IDColor.adaptiveBorder(for: colorScheme))
                .frame(height: 1)

            actionSection
                .padding(IDSpacing.lg)
        }
        .frame(maxWidth: 360)
        .background(
            RoundedRectangle(cornerRadius: IDRadius.xl)
                .fill(IDColor.adaptiveBackground(for: colorScheme))
                .shadow(
                    color: .black.opacity(colorScheme == .dark ? 0.4 : 0.12),
                    radius: 24, x: 0, y: 8
                )
        )
        .padding(.horizontal, IDSpacing.xl)
    }

    private var iconSection: some View {
        ZStack {
            Circle()
                .fill(model.type.accentColor.opacity(0.12))
                .frame(width: 64, height: 64)
            Image(systemName: model.type.iconName)
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(model.type.accentColor)
        }
        .padding(.top, IDSpacing.xl)
        .padding(.bottom, IDSpacing.lg)
    }

    @ViewBuilder
    private var actionSection: some View {
        if model.actions.count == 2 {
            HStack(spacing: IDSpacing.sm) {
                ForEach(model.actions) { action in
                    alertButton(action)
                }
            }
        } else {
            VStack(spacing: IDSpacing.sm) {
                ForEach(model.actions) { action in
                    alertButton(action)
                }
            }
        }
    }

    private func alertButton(_ action: IDAlertAction) -> some View {
        Button {
            action.action?()
            dismiss()
        } label: {
            Text(action.title)
                .font(IDFont.bodyMedium(.semibold))
                .foregroundColor(buttonForeground(action.style))
                .frame(maxWidth: .infinity)
                .padding(.vertical, IDSpacing.md)
                .background(
                    Capsule().fill(buttonBackground(action.style))
                )
        }
        .buttonStyle(.plain)
    }

    private func buttonBackground(_ style: IDAlertActionStyle) -> Color {
        switch style {
        case .primary:     return model.type.accentColor
        case .cancel:      return IDColor.adaptiveSurface(for: colorScheme)
        case .destructive: return IDColor.error
        }
    }

    private func buttonForeground(_ style: IDAlertActionStyle) -> Color {
        switch style {
        case .primary, .destructive: return .white
        case .cancel:                return IDColor.adaptiveTitle(for: colorScheme)
        }
    }
}

// MARK: - IDAlertModifier

private struct IDAlertModifier: ViewModifier {
    @Binding var item: IDAlertModel?

    func body(content: Content) -> some View {
        ZStack {
            content

            if let model = item {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture { }
                    .transition(.opacity)
                    .zIndex(1)

                IDAlertPopup(model: model) {
                    item = nil
                }
                .transition(.scale(scale: 0.92).combined(with: .opacity))
                .zIndex(2)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.78), value: item == nil)
    }
}

// MARK: - View Extension

extension View {
    func sdkAlert(item: Binding<IDAlertModel?>) -> some View {
        modifier(IDAlertModifier(item: item))
    }
}

// MARK: - Preview

#Preview("Tek Buton — Info") {
    IDColor.inkBackground.ignoresSafeArea()
        .sdkAlert(
            item: .constant(IDAlertModel(
                type: .info,
                title: "Bilgi",
                message: "Bu işlem geri alınamaz. Devam etmek istediğinizden emin misiniz?",
                actions: [
                    IDAlertAction(title: "Tamam", style: .primary)
                ]
            ))
        )
}

#Preview("İki Buton — Hata") {
    IDColor.inkBackground.ignoresSafeArea()
        .sdkAlert(
            item: .constant(IDAlertModel(
                type: .error,
                title: "Bağlantı Hatası",
                message: "Sunucuya ulaşılamıyor. Lütfen internet bağlantınızı kontrol edin.",
                actions: [
                    IDAlertAction(title: "İptal", style: .cancel),
                    IDAlertAction(title: "Tekrar Dene", style: .primary)
                ]
            ))
        )
}

#Preview("İki Buton — Normal") {
    IDColor.inkBackground.ignoresSafeArea()
        .sdkAlert(
            item: .constant(IDAlertModel(
                type: .normal,
                title: "Oturum Süresi Doldu",
                message: "Oturumunuz sona eriyor. Devam etmek istiyor musunuz?",
                actions: [
                    IDAlertAction(title: "Çıkış", style: .cancel),
                    IDAlertAction(title: "Devam Et", style: .primary)
                ]
            ))
        )
}

#Preview("İki Buton — Başarı") {
    IDColor.inkBackground.ignoresSafeArea()
        .sdkAlert(
            item: .constant(IDAlertModel(
                type: .success,
                title: "Kimlik Doğrulandı",
                message: "Kimlik doğrulama işleminiz başarıyla tamamlandı.",
                actions: [
                    IDAlertAction(title: "Kapat", style: .cancel),
                    IDAlertAction(title: "Devam Et", style: .primary)
                ]
            ))
        )
}
