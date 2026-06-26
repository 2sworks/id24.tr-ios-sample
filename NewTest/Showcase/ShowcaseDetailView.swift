//
//  ShowcaseDetailView.swift
//  NewTest
//
//  Bir SDK modülünün rehber detayı: canlı ekran (mock coordinator ile) +
//  entegrasyon kodu + özelleştirme kodu.
//

import SwiftUI
import IdentifySDK

struct ShowcaseDetailView: View {

    let item: ShowcaseItem
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: IDSpacing.xl) {

                Text(item.subtitle)
                    .font(IDFont.bodyRegular())
                    .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))

                section("Canlı Ekran") {
                    ShowcaseLivePreview { item.liveView() }
                    Text("Not: Kamera/NFC/WebRTC gibi canlı alanlar yalnızca gerçek backend oturumunda çalışır; burada tasarımı görürsünüz.")
                        .font(IDFont.bodySmall())
                        .foregroundColor(IDColor.inkLight)
                }

                section("Entegrasyon") {
                    ShowcaseCodeBlock(title: "Akışta kullanım", code: item.integrationCode)
                }

                section("Özelleştirme") {
                    ShowcaseCodeBlock(title: "Tema + tam view replace", code: item.customizationCode)
                }
            }
            .padding(IDSpacing.xl)
        }
        .background(IDColor.adaptiveBackground(for: colorScheme).ignoresSafeArea())
        .navigationTitle(item.title)
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: IDSpacing.md) {
            Text(title)
                .font(IDFont.bodyLarge(.semibold))
                .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
            content()
        }
    }
}
