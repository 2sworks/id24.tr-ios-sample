//
//  PrepareHostViewModel.swift
//  NewTest
//
//  Hazırlık modülü host VM'i. SDKPrepareViewModel'i sarar; dışarıdan event log ekler.
//

import SwiftUI
import IdentifySDK

@MainActor
final class PrepareHostViewModel: HostModuleViewModel {
    let sdk = SDKPrepareViewModel()

    /// Dışarıdan (env-config) ayarlanır: konuşma izni de zorunlu mu?
    var requireSpeech: Bool = true

    override init() {
        super.init()
        bridge(sdk)
        sdk.onCompleted = { [weak self] in
            self?.log("prepare_completed")
            self?.onCompleted?()
        }
    }

    var cameraAuthorized: Bool { sdk.cameraAuthorized }
    var micAuthorized: Bool { sdk.micAuthorized }
    var speechAuthorized: Bool { sdk.speechAuthorized }
    var allPermissionsGranted: Bool {
        requireSpeech ? sdk.allPermissionsGranted : (sdk.cameraAuthorized && sdk.micAuthorized)
    }

    func checkPermissions() {
        log("check_permissions")
        sdk.checkCamera(); sdk.checkMicrophone()
        if requireSpeech { sdk.checkSpeech() }
    }
    func complete() { sdk.completePrepare() }
}
