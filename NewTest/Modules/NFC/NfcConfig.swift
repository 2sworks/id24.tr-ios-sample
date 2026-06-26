//
//  NfcConfig.swift
//  NewTest
//
//  NFC modülü için DIŞARIDAN ayarlanabilen değişkenler (`@EnvironmentObject`).
//  MRZ ön-doldurma değerleri host VM'in prefill'ini besler.
//

import SwiftUI
import IdentifySDK

@MainActor
final class NfcConfig: ObservableObject {
    @Published var headerTitle: String = "NFC (özel UI + host VM)"
    @Published var accentColor: Color = IDColor.primary
    /// Açılışta MRZ alanlarını ön-doldur.
    @Published var autoPrefill: Bool = false
    @Published var prefillSerial: String = ""
    @Published var prefillBirth: String = ""
    @Published var prefillValid: String = ""

    static var preview: NfcConfig {
        let c = NfcConfig()
        c.headerTitle = "NFC (env-config ile ön-dolduruldu)"
        c.accentColor = IDColor.accentTeal
        c.autoPrefill = true
        c.prefillSerial = "A12345678"
        c.prefillBirth = "900101"
        c.prefillValid = "300101"
        return c
    }
}
