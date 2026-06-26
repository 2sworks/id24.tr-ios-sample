//
//  AddressConfirmHostViewModel.swift
//  NewTest
//
//  Adres modülü host VM'i. SDKAddressConfirmViewModel'i sarar; özel doğrulama + event log.
//

import SwiftUI
import IdentifySDK

@MainActor
final class AddressConfirmHostViewModel: HostModuleViewModel {
    let sdk = SDKAddressConfirmViewModel()

    /// Dışarıdan eklenen ekstra doğrulama (örn. adreste şehir adı zorunlu).
    var extraValidation: ((String) -> Bool)?

    override init() {
        super.init()
        bridge(sdk)
        sdk.onCompleted = { [weak self] in self?.log("address_submitted"); self?.onCompleted?() }
    }

    var isAddressValid: Bool { sdk.isAddressValid }
    var hasDocument: Bool { sdk.docPhoto != nil || sdk.pdfData != nil }
    var canSubmit: Bool { sdk.canSubmit && (extraValidation?(sdk.addressText) ?? true) }
    var addressText: String { get { sdk.addressText } set { sdk.addressText = newValue } }

    func selectDocument(_ image: UIImage) { log("document_selected"); sdk.photoSelected(image) }
    func submit() {
        if let extraValidation, extraValidation(sdk.addressText) == false { log("extra_validation_failed"); return }
        log("submit"); sdk.submit()
    }
}
