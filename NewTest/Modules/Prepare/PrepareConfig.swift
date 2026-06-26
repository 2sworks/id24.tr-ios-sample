//
//  PrepareConfig.swift
//  NewTest
//
//  Hazırlık modülü için DIŞARIDAN (developer) ayarlanabilen değişkenler.
//  Host VM (davranış/closure) yanında, BU da bir özelleştirme yolu: deklaratif
//  değerleri `@EnvironmentObject` ile enjekte edip ekranı dışarıdan biçimlendirirsin.
//
//      PrepareExampleReplaced().environmentObject(PrepareConfig())
//

import SwiftUI
import IdentifySDK

@MainActor
final class PrepareConfig: ObservableObject {
    /// Başlık metni (dışarıdan değiştirilebilir).
    @Published var headerTitle: String = "Hazırlık (özel UI + host VM)"
    /// Vurgu rengi (başlık vb.).
    @Published var accentColor: Color = IDColor.primary
    /// Konuşma izni de zorunlu mu? (host iş akışını etkiler)
    @Published var requireSpeechPermission: Bool = true

    /// Rehber/Preview için örnek (env-override'ın etkisini görünür kılar).
    static var preview: PrepareConfig {
        let c = PrepareConfig()
        c.headerTitle = "Hazırlık (env-config ile özelleştirildi)"
        c.accentColor = IDColor.accentTeal
        return c
    }
}
