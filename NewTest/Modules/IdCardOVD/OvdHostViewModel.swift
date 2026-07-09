//
//  OvdHostViewModel.swift
//  NewTest
//
//  Kimlik OVD modülü host VM'i. SDKIdCardOVDViewModel'i sarar; adım olaylarını loglar,
//  hologram-adımı zorunluluğunu (host config) uygular.
//

import SwiftUI
import IdentifySDK

@MainActor
final class OvdHostViewModel: HostModuleViewModel {
    let sdk = SDKIdCardOVDViewModel()

    override init() {
        super.init()
        bridge(sdk)
        sdk.onSkipRequested = { [weak self] in self?.log("ovd_skip_requested") }
    }

    /// Dışarıdan (env-config) hologram adımı zorunluluğu + belge tipi.
    func applyConfig(requiresHologram: Bool, documentType: OVDDocumentType = .idCard) {
        sdk.requiresHologramStep = requiresHologram
        sdk.documentType = documentType
        log("ovd_requires_hologram_\(requiresHologram)")
        log("ovd_doc_\(documentType == .passport ? "passport" : "idCard")")
    }

    var instruction: String { sdk.instruction }
    var progress: Double { sdk.progress }
    var canContinue: Bool { sdk.canContinue }
    var stepText: String {
        switch sdk.step {
        case .frontAlign:    return "ön yüz"
        case .frontHologram: return "hologram"
        case .backAlign:     return "arka yüz"
        case .completed:     return "tamamlandı"
        }
    }

    func capture(_ image: UIImage) {
        log("ovd_capture_\(stepText)")
        sdk.capture(image: image)
        if sdk.canContinue { log("ovd_completed") }
    }

    func reset() { log("ovd_reset"); sdk.reset() }
}
