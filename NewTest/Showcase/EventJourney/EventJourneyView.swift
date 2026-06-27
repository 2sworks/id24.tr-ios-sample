//
//  EventJourneyView.swift
//  NewTest
//
//  "Olay Örgüsü / Telemetri" rehber ekranı: SDK'nın birleşik olay akışını (SDKEvent)
//  canlı bir zaman çizelgesi olarak gösterir. Müşteriye "SDK nerede ne yapıyor, kullanıcı
//  hangi ekranda çıktı, oturum başarılı mı başarısız mı kapandı" sorularını görselleştirir.
//
//  Bu ekran gerçek entegrasyonu birebir yapar:
//      IdentifyManager.shared.eventDelegate = recorder
//  Gerçek bir oturumda olaylar otomatik akar. Rehber ortamında canlı oturum olmadığından,
//  örnek senaryolar simüle edilerek olay örgüsü gösterilir.
//

import SwiftUI
import IdentifySDK

struct EventJourneyView: View {

    @StateObject private var recorder = SDKEventRecorder()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: IDSpacing.lg) {

                outcomeBanner

                Text("Örnek senaryo seç — olay örgüsü canlı çizilir:")
                    .font(IDFont.bodySmall())
                    .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))

                scenarioButtons

                if recorder.events.isEmpty {
                    Text("— henüz olay yok. Gerçek oturumda olaylar otomatik akar; yukarıdan bir senaryo simüle edebilirsin. —")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(IDColor.inkLight)
                        .padding(.vertical, IDSpacing.lg)
                } else {
                    timeline
                    rawJSON
                }
            }
            .padding(IDSpacing.md)
        }
        .background(IDColor.adaptiveBackground(for: colorScheme))
        .onAppear { IdentifyManager.shared.eventDelegate = recorder }
        .onDisappear {
            if IdentifyManager.shared.eventDelegate === recorder {
                IdentifyManager.shared.eventDelegate = nil
            }
        }
    }

    // MARK: Outcome banner

    @ViewBuilder
    private var outcomeBanner: some View {
        if let outcome = recorder.sessionOutcome {
            let style = bannerStyle(for: outcome.status)
            HStack(spacing: IDSpacing.md) {
                Image(systemName: style.icon)
                    .font(.system(size: 26))
                    .foregroundColor(style.color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(style.title)
                        .font(IDFont.bodyLarge(.semibold))
                        .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                    if let screen = recorder.lastScreen {
                        Text("Son ekran: \(screen)")
                            .font(IDFont.bodySmall())
                            .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                    }
                    if let reason = outcome.metadata["reason"] ?? outcome.message {
                        Text("Sebep: \(reason)")
                            .font(IDFont.bodySmall())
                            .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                    }
                }
                Spacer()
            }
            .padding(IDSpacing.md)
            .background(RoundedRectangle(cornerRadius: IDRadius.md).fill(style.color.opacity(0.12)))
            .overlay(RoundedRectangle(cornerRadius: IDRadius.md).stroke(style.color.opacity(0.5), lineWidth: 1))
        }
    }

    private func bannerStyle(for status: SDKEventStatus) -> (icon: String, color: Color, title: String) {
        switch status {
        case .success:   return ("checkmark.seal.fill", .green, "Oturum başarıyla kapandı")
        case .failed:    return ("xmark.seal.fill", .red, "Oturum başarısız kapandı")
        case .abandoned: return ("exclamationmark.triangle.fill", .orange, "Kullanıcı oturumu terk etti")
        default:         return ("info.circle.fill", IDColor.primary, "Oturum sürüyor")
        }
    }

    // MARK: Senaryo butonları

    private var scenarioButtons: some View {
        VStack(spacing: IDSpacing.sm) {
            HStack(spacing: IDSpacing.sm) {
                scenarioButton("Başarılı", "checkmark.circle", .green) { recorder.simulate(.success) }
                scenarioButton("Başarısız", "xmark.circle", .red) { recorder.simulate(.failed) }
            }
            HStack(spacing: IDSpacing.sm) {
                scenarioButton("Terk", "figure.walk.departure", .orange) { recorder.simulate(.abandoned) }
                scenarioButton("Temizle", "trash", IDColor.inkLight) { recorder.reset() }
            }
        }
    }

    private func scenarioButton(_ title: String, _ icon: String, _ color: Color, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(IDFont.bodySmall(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, IDSpacing.sm)
                .background(RoundedRectangle(cornerRadius: IDRadius.md).fill(color.opacity(0.12)))
                .foregroundColor(color)
        }
        .buttonStyle(.plain)
    }

    // MARK: Zaman çizelgesi

    private var timeline: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(recorder.events.enumerated()), id: \.offset) { idx, event in
                eventRow(event, isLast: idx == recorder.events.count - 1)
            }
        }
        .padding(IDSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: IDRadius.md).fill(IDColor.adaptiveSurface(for: colorScheme)))
        .overlay(RoundedRectangle(cornerRadius: IDRadius.md).stroke(IDColor.inkBorder, lineWidth: 1))
    }

    private func eventRow(_ event: SDKEvent, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: IDSpacing.md) {
            VStack(spacing: 0) {
                Image(systemName: categoryIcon(event.category))
                    .font(.system(size: 14))
                    .foregroundColor(statusColor(event.status))
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(statusColor(event.status).opacity(0.12)))
                if !isLast {
                    Rectangle()
                        .fill(IDColor.inkBorder)
                        .frame(width: 1.5)
                        .frame(minHeight: 18)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(event.name)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                HStack(spacing: 6) {
                    chip(event.category.rawValue, IDColor.primary)
                    chip(event.status.rawValue, statusColor(event.status))
                    if let screen = event.screen { chip(screen, IDColor.inkMid) }
                }
                Text(timeString(event.timestampMs))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(IDColor.inkLight)
            }
            .padding(.bottom, isLast ? 0 : IDSpacing.sm)
            Spacer()
        }
    }

    private func chip(_ text: String, _ color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .medium))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Capsule().fill(color.opacity(0.14)))
            .foregroundColor(color)
    }

    // MARK: Ham JSON (köprülerin gördüğü şekil)

    private var rawJSON: some View {
        VStack(alignment: .leading, spacing: IDSpacing.sm) {
            Text("Son olayın JSON'u (RN/Flutter köprüsünün gördüğü şekil)")
                .font(IDFont.bodySmall(.semibold))
                .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
            ScrollView(.horizontal, showsIndicators: false) {
                Text(recorder.events.last?.toJSONString() ?? "{}")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                    .padding(IDSpacing.md)
            }
            .background(RoundedRectangle(cornerRadius: IDRadius.md).fill(IDColor.adaptiveSurface(for: colorScheme)))
            .overlay(RoundedRectangle(cornerRadius: IDRadius.md).stroke(IDColor.inkBorder, lineWidth: 1))
        }
    }

    // MARK: Yardımcılar

    private func categoryIcon(_ cat: SDKEventCategory) -> String {
        switch cat {
        case .session:    return "flag.checkered"
        case .module:     return "square.stack.3d.up"
        case .call:       return "phone"
        case .network:    return "network"
        case .error:      return "exclamationmark.triangle"
        case .navigation: return "arrow.left.arrow.right"
        }
    }

    private func statusColor(_ status: SDKEventStatus) -> Color {
        switch status {
        case .completed, .success: return .green
        case .failed:              return .red
        case .skipped:             return IDColor.inkMid
        case .abandoned:           return .orange
        case .notFound:            return .orange
        case .presented, .info:    return IDColor.primary
        }
    }

    private func timeString(_ ms: Int64) -> String {
        let date = Date(timeIntervalSince1970: Double(ms) / 1000)
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f.string(from: date)
    }
}

#Preview {
    EventJourneyView()
}
