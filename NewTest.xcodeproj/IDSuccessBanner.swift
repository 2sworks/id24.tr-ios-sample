//
//  IDSuccessBanner.swift
//  NewTest
//
//  Yeniden kullanilabilir basari banner bileseni.
//
//  Kullanim ornekleri:
//    IDSuccessBanner(message: "Bağlantı uygun.")
//
//    someView
//      .successBanner("Bağlantı uygun.", isVisible: viewModel.speedCheckDone)
//

import SwiftUI

// MARK: - Standalone View

struct IDSuccessBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: IDRadius.sm)
                    .fill(IDColor.success.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(IDColor.success)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Başarılı")
                    .font(IDFont.body(.semibold))
                    .foregroundColor(IDColor.success)
                Text(message)
                    .font(IDFont.caption(.regular))
                    .foregroundColor(IDColor.success)
            }
            Spacer()
        }
        .padding(10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: IDRadius.lg))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - View Modifier

private struct SuccessBannerModifier: ViewModifier {
    let message: String
    let isVisible: Bool

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            if isVisible {
                IDSuccessBanner(message: message)
                    .padding(.horizontal, IDSpacing.lg)
                    .padding(.top, IDSpacing.sm)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isVisible)
    }
}

extension View {
    func successBanner(_ message: String, isVisible: Bool) -> some View {
        modifier(SuccessBannerModifier(message: message, isVisible: isVisible))
    }
}

#Preview {
    VStack(spacing: 16) {
        IDSuccessBanner(message: "Bağlantı için uygun internet hızına sahipsiniz.")
            .padding()

        Color.gray.opacity(0.1)
            .frame(height: 200)
            .successBanner("Bağlantı uygun.", isVisible: true)
    }
    .padding()
}
