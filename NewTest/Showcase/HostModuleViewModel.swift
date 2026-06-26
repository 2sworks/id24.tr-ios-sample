//
//  HostModuleViewModel.swift
//  NewTest
//
//  Host (uygulama) tarafı modül ViewModel'lerinin ORTAK temeli.
//
//  Amaç: "Dışarıdan neler eklenebilir?" sorusunu göstermek. SDK her modül için
//  iş mantığını `SDKxxxViewModel` ile sağlar. Geliştirici, bu SDK ViewModel'ini
//  SARAN kendi host ViewModel'ini yazarak ŞUNLARI EKLEYEBİLİR:
//    • Kendi @Published state'i (deneme sayısı, zamanlayıcı, özel bayraklar)
//    • Enjekte edilebilen davranışlar (analytics/event hook, özel doğrulama, config)
//    • SDK olaylarını yakalayıp kendi iş akışını çalıştırma
//
//  Önemli (SwiftUI gotcha): host VM içindeki SDK ViewModel'i de bir ObservableObject'tir.
//  İç içe ObservableObject değişiklikleri View'a OTOMATİK yansımaz; `bridge(_:)` ile
//  SDK VM'in objectWillChange'ini host VM'e köprülüyoruz.
//

import SwiftUI
import Combine
import IdentifySDK

@MainActor
class HostModuleViewModel: ObservableObject {

    /// Host'un dışarıdan EKLEDİĞİ state — SDK'da olmayan, uygulamana özel.
    @Published var events: [String] = []
    @Published var attemptCount: Int = 0

    /// Dışarıdan ENJEKTE edilebilen davranışlar.
    var onEvent: ((String) -> Void)?
    var onCompleted: (() -> Void)?

    var bag = Set<AnyCancellable>()

    /// İç içe SDK ViewModel değişikliklerini View'a yansıtmak için köprüle.
    func bridge<T: ObservableObject>(_ child: T) where T.ObjectWillChangePublisher == ObservableObjectPublisher {
        child.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &bag)
    }

    /// Olay kaydı + dışarı bildirim (analytics entegrasyonu için).
    func log(_ event: String) {
        events.append(event)
        onEvent?(event)
    }
}
