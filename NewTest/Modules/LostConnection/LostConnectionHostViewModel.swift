//
//  LostConnectionHostViewModel.swift
//  NewTest
//
//  Bağlantı Koptu modülü host VM'i. SDKLostConnectionViewModel'i sarar; ağ/yeniden
//  bağlanma olaylarını loglar. SDK: reconnect, isNetworkAvailable, isReconnecting.
//

import SwiftUI
import IdentifySDK

@MainActor
final class LostConnectionHostViewModel: HostModuleViewModel {
    let sdk = SDKLostConnectionViewModel()

    /// Ağ geri geldiğinde otomatik yeniden bağlan (env-config'ten gelir).
    var autoReconnect: Bool = false

    override init() {
        super.init()
        bridge(sdk)
        sdk.onReconnectCompleted = { [weak self] in
            self?.log("reconnected")
            self?.onCompleted?()
        }
        sdk.onReconnectCompletedWithStatus = { [weak self] isWaitingRoom, statusType in
            self?.log("reconnected_status(waiting=\(isWaitingRoom), type=\(statusType ?? "—"))")
        }
    }

    var isReconnecting: Bool { sdk.isReconnecting }
    var isNetworkAvailable: Bool { sdk.isNetworkAvailable }
    var canReconnect: Bool { sdk.canReconnect }

    var statusText: String {
        if sdk.isReconnecting { return "bağlanıyor…" }
        if !sdk.isNetworkAvailable { return "internet yok" }
        return "hazır"
    }

    func reconnect() {
        log("reconnect_tapped")
        sdk.reconnect()
    }

    /// Ağ erişilebilir olduğunda autoReconnect açıksa otomatik dene.
    func networkBecameAvailable() {
        guard autoReconnect, sdk.canReconnect else { return }
        log("auto_reconnect")
        sdk.reconnect()
    }
}

