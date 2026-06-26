//
//  SignLangHostViewModel.swift
//  NewTest
//
//  İşaret Dili modülü host VM'i. SDKSignLangViewModel'i sarar; tercih + olay kaydı ekler.
//

import SwiftUI
import IdentifySDK

@MainActor
final class SignLangHostViewModel: HostModuleViewModel {
    let sdk = SDKSignLangViewModel()

    override init() {
        super.init()
        bridge(sdk)
    }

    /// Toggle binding'i için iki yönlü erişim.
    var isEnabled: Bool {
        get { sdk.isSignLangEnabled }
        set { sdk.isSignLangEnabled = newValue; log("signlang_toggle_\(newValue)") }
    }

    /// Dışarıdan (env-config) varsayılan tercih.
    func applyDefault(_ enabled: Bool) {
        sdk.isSignLangEnabled = enabled
        log("signlang_default_\(enabled)")
    }

    func proceed() {
        log("signlang_continue(\(sdk.isSignLangEnabled))")
        sdk.continueAction(onFinish: { [weak self] in self?.onCompleted?() })
    }
}
