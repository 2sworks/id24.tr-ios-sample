//
//  ShowcaseCatalogView.swift
//  NewTest
//
//  SDK Modül Rehberi giriş ekranı: tüm modülleri listeler. Bir modüle dokununca
//  ShowcaseDetailView açılır (canlı ekran + entegrasyon/özelleştirme kodu).
//
//  iOS 15 uyumu: NavigationView + NavigationLink (NavigationStack iOS 16+).
//

import SwiftUI
import IdentifySDK

struct ShowcaseCatalogView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    /// Debug/test: `SHOWCASE_ITEM` env değişkeni verilen id'nin detayını otomatik açar
    /// (örn. SIMCTL_CHILD_SHOWCASE_ITEM=liveness). UI otomasyonu olmadan detay
    /// sayfalarının (back button dahil) test edilebilmesi için.
    @State private var autoOpenItem: ShowcaseItem? =
        ProcessInfo.processInfo.environment["SHOWCASE_ITEM"]
            .flatMap { id in ShowcaseCatalog.items.first { $0.id == id } }
    @State private var autoOpenActive = false

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: IDSpacing.md) {
                    if let item = autoOpenItem {
                        NavigationLink(isActive: $autoOpenActive) {
                            ShowcaseDetailView(item: item)
                        } label: { EmptyView() }
                        .onAppear { autoOpenActive = true }
                    }
                    header
                    ForEach(showcaseCategories, id: \.self) { category in
                        let items = ShowcaseCatalog.items.filter { $0.category == category }
                        if !items.isEmpty {
                            sectionHeader(category)
                            ForEach(items) { item in
                                NavigationLink {
                                    ShowcaseDetailView(item: item)
                                } label: {
                                    row(item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(IDSpacing.xl)
            }
            .background(IDColor.adaptiveBackground(for: colorScheme).ignoresSafeArea())
            .navigationTitle("SDK Modül Rehberi")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
        .navigationViewStyle(.stack)
        // Mock oturum verisi: katalog açıkken SDK ekranları gerçekçi içerikle çizilir
        // (konuşma cümlesi, NFC ön-doldurma, sıra bilgisi...). Kapanışta geri yüklenir
        // ki mock değerler sonraki gerçek oturuma sızmasın.
        .onAppear { ShowcaseMockData.apply() }
        .onDisappear { ShowcaseMockData.restore() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: IDSpacing.sm) {
            Text("Entegrasyon Rehberi")
                .font(IDFont.bodyLarge(.semibold))
                .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
            Text("Her SDK modülünü canlı görün, entegrasyon ve özelleştirme kodunu inceleyin. Modüller gerçek akışta backend'in döndürdüğü sıraya göre otomatik gelir.")
                .font(IDFont.bodyRegular())
                .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, IDSpacing.sm)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(IDFont.caption(.semibold))
            .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
            .padding(.top, IDSpacing.md)
            .padding(.leading, 2)
    }

    private func row(_ item: ShowcaseItem) -> some View {
        HStack(spacing: IDSpacing.md) {
            Image(systemName: item.icon)
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(IDColor.primary)
                .frame(width: 44, height: 44)
                .background(IDColor.primary.opacity(0.10), in: RoundedRectangle(cornerRadius: IDRadius.md))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(IDFont.bodyRegular(.semibold))
                    .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                Text(item.subtitle)
                    .font(IDFont.bodySmall())
                    .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                    .multilineTextAlignment(.leading)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(IDColor.inkLight)
        }
        .padding(IDSpacing.lg)
        .background(IDColor.adaptiveSurface(for: colorScheme), in: RoundedRectangle(cornerRadius: IDRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: IDRadius.md)
                .stroke(IDColor.inkBorder, lineWidth: 1)
        )
    }
}

#Preview {
    ShowcaseCatalogView()
}
