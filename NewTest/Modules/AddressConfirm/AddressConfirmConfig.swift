//
//  AddressConfirmConfig.swift
//  NewTest
//
//  Adres Onayı modülü için DIŞARIDAN ayarlanabilen değişkenler (`@EnvironmentObject`).
//  minWordCount, host VM'in extraValidation'ını besler.
//

import SwiftUI
import IdentifySDK

@MainActor
final class AddressConfirmConfig: ObservableObject {
    @Published var headerTitle: String = "Adres Onayı (özel UI + host VM)"
    @Published var accentColor: Color = IDColor.primary
    /// Adreste en az kaç kelime zorunlu (ekstra doğrulama).
    @Published var minWordCount: Int = 2

    static var preview: AddressConfirmConfig {
        let c = AddressConfirmConfig()
        c.headerTitle = "Adres (env-config ile özelleştirildi)"
        c.accentColor = IDColor.accentTeal
        c.minWordCount = 3
        return c
    }
}
