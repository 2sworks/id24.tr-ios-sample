//
//  ExternalViewModel.swift
//  NewTest
//
//  SDK modülleri arasına eklenen özel (harici) ekranın ViewModel'i.
//  Bu ekran moduleStepOrder'ı etkilemez — sadece bir sonraki SDK modülüne geçişi tetikler.
//

import Foundation
import IdentifySDK

@MainActor
final class ExternalViewModel: BaseModuleViewModel {

    // MARK: - Content

    let title: String
    let subtitle: String
    let iconName: String

    init(
        title: String = "Bilgilendirme",
        subtitle: String = "Devam etmeden önce lütfen aşağıdaki bilgileri dikkatlice okuyun.",
        iconName: String = "info.circle.fill"
    ) {
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
    }

    // MARK: - Actions

    /// Bir sonraki SDK modülüne geçer. moduleStepOrder bu ekranda değişmemiş olduğundan
    /// getNextModule() doğru sıradaki modülü döndürür.
    func proceed(appState: AppStateViewModel) {
        appState.advanceToNextModule()
    }
}
