//
//  ShowcaseSupport.swift
//  NewTest
//
//  SDK Modül Rehberi (Showcase) için paylaşılan yardımcılar.
//
//  Amaç: Bu uygulama bir ENTEGRASYON REHBERİDİR. Geliştirici, SDK'nın her
//  modülünü (1) varsayılan haliyle, (2) tema ile özelleştirilmiş, (3) tamamen
//  kendi view'ı ile değiştirilmiş olarak görür; ayrıca her ekran Xcode #Preview'da
//  canlı görünür.
//
//  SDK modül ekranları (SDKSelfieView vb.) `@EnvironmentObject SDKFlowCoordinator`
//  bekler. Rehber/Preview ortamında gerçek bir backend oturumu olmadığından,
//  ekranları çizebilmek için boş bir "mock" coordinator enjekte ederiz. Bu sayede
//  tasarım/UI görünür; kamera/canlı alanlar yalnızca gerçek akışta çalışır.
//

import SwiftUI
import IdentifySDK

// MARK: - Mock coordinator enjeksiyonu

extension View {
    /// SDK modül ekranını rehber/preview ortamında çizmek için boş bir
    /// `SDKFlowCoordinator` enjekte eder. Gerçek akışta coordinator LoginView'dan gelir.
    @MainActor
    func showcaseHost() -> some View {
        modifier(ShowcaseHostModifier())
    }
}

private struct ShowcaseHostModifier: ViewModifier {
    @StateObject private var coordinator = SDKFlowCoordinator()
    func body(content: Content) -> some View {
        content.environmentObject(coordinator)
    }
}

// MARK: - Örnek girdi (kamera/tarayıcı gerektiren metotlar için)

/// Gerçek bir uygulamada kamera/tarayıcıdan gelen görsel/veriyi SDK ViewModel'ine
/// verirsiniz. Rehber/Preview ortamında gerçek yakalama olmadığından, metot
/// çağrılarını göstermek için yer tutucu bir görsel/veri üretiriz.
enum ShowcaseSample {
    static var image: UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 240, height: 240)).image { ctx in
            UIColor.systemGray5.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 240, height: 240))
        }
    }
    static var videoData: Data { Data() }
}

// MARK: - Özel ekran için ortak satır bileşenleri

/// Replace örneklerinde VM state'ini göstermek için basit etiket/durum satırı.
struct ShowcaseStatusRow: View {
    let label: String
    let value: String
    var ok: Bool? = nil
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            if let ok {
                Image(systemName: ok ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(ok ? .green : IDColor.inkLight)
            }
            Text(label)
                .font(IDFont.bodyRegular())
                .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
            Spacer()
            Text(value)
                .font(IDFont.bodySmall())
                .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Event log (host VM'in dışarıdan eklediği analytics/olay kaydı)

/// Host ViewModel'in topladığı olay/analytics kaydını gösterir.
/// "Dışarıdan neler eklenebilir" örneklerinde kullanılır.
struct ShowcaseEventLog: View {
    let events: [String]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Host event log (dışarıdan eklendi)")
                .font(IDFont.bodySmall(.semibold))
                .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
            if events.isEmpty {
                Text("— henüz olay yok —")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(IDColor.inkLight)
            } else {
                ForEach(Array(events.enumerated()), id: \.offset) { _, e in
                    Text("• \(e)")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(IDSpacing.md)
        .background(RoundedRectangle(cornerRadius: IDRadius.md).fill(IDColor.adaptiveSurface(for: colorScheme)))
        .overlay(RoundedRectangle(cornerRadius: IDRadius.md).stroke(IDColor.inkBorder, lineWidth: 1))
    }
}

// MARK: - Tema override (özelleştirme örneği)

extension View {
    /// Bu ekran görünürken SDKTheme primary rengini geçici olarak değiştirir,
    /// çıkışta eski rengi geri yükler. (SDKTheme observable olmadığından `.id` ile
    /// tek seferlik yeniden çizim tetiklenir.) Tema-override örneği için kullanılır.
    @MainActor
    func showcaseThemed(primary: Color) -> some View {
        modifier(ShowcaseThemeOverride(primary: primary))
    }
}

private struct ShowcaseThemeOverride: ViewModifier {
    let primary: Color
    @State private var applied = false
    @State private var original: Color? = nil

    func body(content: Content) -> some View {
        content
            .id(applied)
            .onAppear {
                if original == nil { original = SDKTheme.shared.colors.primary }
                SDKTheme.shared.colors.primary = primary
                applied = true
            }
            .onDisappear {
                if let original { SDKTheme.shared.colors.primary = original }
            }
    }
}

// MARK: - "Kendi tasarımın" iskeleti (tam view-replace örneği)

/// Bir SDK ekranını TAMAMEN kendi view'ınla değiştirdiğinde nasıl görünebileceğini
/// temsil eden örnek iskelet. Gerçekte burada kendi UI'ını yazar, iş mantığını
/// SDK'nın ilgili ViewModel'i ile yürütürsün.
struct ShowcaseCustomScaffold: View {
    let title: String
    let systemIcon: String
    var note: String = "Kendi tasarımın burada. İş mantığını SDK'nın ViewModel'i ile yürüt."
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: IDSpacing.xl) {
            Spacer()
            Image(systemName: systemIcon)
                .font(.system(size: 56, weight: .light))
                .foregroundColor(IDColor.primary)
            Text("Özel \(title) Ekranı")
                .font(IDFont.bodyLarge(.semibold))
                .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
            Text(note)
                .font(IDFont.bodySmall())
                .foregroundColor(IDColor.adaptiveSubtitle(for: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, IDSpacing.xl)
            Spacer()
            Text("registry.override(...) { ... }")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(IDColor.inkLight)
                .padding(.bottom, IDSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(IDColor.adaptiveBackground(for: colorScheme).ignoresSafeArea())
    }
}

// MARK: - Canlı önizleme kutusu

/// SDK modül ekranını sabit yükseklikte, çerçeveli bir "cihaz önizlemesi" içinde gösterir.
/// (Tam ekran göstermek katalog navigasyonu ile çakışırdı; modülün kendi geri butonu
///  mock coordinator üzerinde çalışır, kataloğu etkilemez.)
struct ShowcaseLivePreview<Content: View>: View {
    private let content: () -> Content
    @Environment(\.colorScheme) private var colorScheme

    init(@ViewBuilder _ content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .showcaseHost()
            .frame(height: 540)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(IDColor.inkBorder, lineWidth: 1)
            )
            .overlay(alignment: .topTrailing) {
                Text("CANLI")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(IDColor.primary, in: Capsule())
                    .foregroundColor(.white)
                    .padding(10)
            }
    }
}

// MARK: - Kod bloğu

/// Entegrasyon/özelleştirme kod parçacığını monospace bir kart içinde gösterir (kopyalanabilir).
struct ShowcaseCodeBlock: View {
    let title: String
    let code: String
    @Environment(\.colorScheme) private var colorScheme
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: IDSpacing.sm) {
            HStack {
                Text(title)
                    .font(IDFont.bodyRegular(.semibold))
                    .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                Spacer()
                Button {
                    UIPasteboard.general.string = code
                    withAnimation { copied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        withAnimation { copied = false }
                    }
                } label: {
                    Label(copied ? "Kopyalandı" : "Kopyala",
                          systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 12, weight: .medium))
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(IDColor.adaptiveTitle(for: colorScheme))
                    .padding(IDSpacing.md)
            }
            .background(
                RoundedRectangle(cornerRadius: IDRadius.md)
                    .fill(IDColor.adaptiveSurface(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: IDRadius.md)
                    .stroke(IDColor.inkBorder, lineWidth: 1)
            )
        }
    }
}
