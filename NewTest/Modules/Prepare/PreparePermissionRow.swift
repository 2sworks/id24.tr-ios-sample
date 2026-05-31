//
//  PreparePermissionRow.swift
//  NewTest
//

import SwiftUI

struct PreparePermissionRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let icon: String
    let sf: String
    let title: String
    let isChecked: Bool
    let action: () -> Void

    private var uncheckedCheckboxColor: Color {
        colorScheme == .dark ? Color(hex: "#3A3A5C") : Color(hex: "#D9D9D9")
    }

    private var rowIcon: AnyView {
        if UIImage(named: icon) != nil {
            AnyView(Image(icon).renderingMode(.template).resizable().scaledToFit())
        } else {
            AnyView(Image(systemName: sf))
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                rowIcon
                    .font(.system(size: 16))
                    .foregroundColor(isChecked ? .white : IDColor.inkLight)
                    .frame(width: 24, height: 24)

                Text(title)
                    .font(IDFont.body(.regular))
                    .foregroundColor(isChecked ? .white : IDColor.inkLight)
                    .multilineTextAlignment(.leading)

                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isChecked ? Color.white : uncheckedCheckboxColor)
                        .frame(width: 20, height: 20)
                    if isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(IDColor.primary)
                    }
                }
            }
            .padding(.horizontal, IDSpacing.lg)
            .frame(minHeight: 48)
            .background(
                RoundedRectangle(cornerRadius: IDRadius.md)
                    .fill(isChecked ? IDColor.primary : uncheckedCheckboxColor.opacity(0.6))
            )
        }
        .buttonStyle(.plain)
    }
}

