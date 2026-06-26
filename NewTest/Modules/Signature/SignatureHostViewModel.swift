//
//  SignatureHostViewModel.swift
//  NewTest
//
//  İmza modülü host VM'i. SDKSignatureViewModel'i sarar; imza olaylarını loglar.
//

import SwiftUI
import IdentifySDK

@MainActor
final class SignatureHostViewModel: HostModuleViewModel {
    let sdk = SDKSignatureViewModel()

    override init() {
        super.init()
        bridge(sdk)
        sdk.onCompleted = { [weak self] in self?.log("signature_uploaded"); self?.onCompleted?() }
    }

    var signatureDrawn: Bool { sdk.signatureDrawn }
    var uploadCompleted: Bool { sdk.uploadCompleted }

    func markDrawn() { log("signature_drawn"); sdk.signatureDidDraw() }
    func clear() { log("signature_cleared"); sdk.clearSignature() }
    func upload(_ image: UIImage) { log("upload_signature"); sdk.uploadSignature(image: image) }
}
