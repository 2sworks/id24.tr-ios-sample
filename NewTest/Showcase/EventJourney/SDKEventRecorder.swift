//
//  SDKEventRecorder.swift
//  NewTest
//
//  SDK'nın birleşik olay akışını (SDKEventListener) dinleyip bir zaman çizelgesine
//  toplayan host-tarafı kaydedici. "Olay Örgüsü / Telemetri" ekranı bunu görselleştirir.
//
//  Gerçek entegrasyonda developer tam olarak bunu yapar:
//      IdentifyManager.shared.eventDelegate = recorder
//  ve onSDKEvent(_:) içinde olayları kendi analytics/loglama sistemine iletir
//  (Firebase, Sentry, kendi backend'i vb.).
//

import Foundation
import Combine
import IdentifySDK

@MainActor
final class SDKEventRecorder: ObservableObject, SDKEventListener {

    /// Gelen tüm olaylar (en eskiden en yeniye).
    @Published private(set) var events: [SDKEvent] = []

    // MARK: SDKEventListener

    /// SDK olayları arka plan (socket) thread'inden gelebilir → ana akışa taşı.
    nonisolated func onSDKEvent(_ event: SDKEvent) {
        Task { @MainActor in self.append(event) }
    }

    private func append(_ event: SDKEvent) {
        events.append(event)
    }

    func reset() {
        events.removeAll()
    }

    // MARK: Türetilmiş oturum sonucu

    /// Oturumun nihai sonucu (varsa): son session.* olayı.
    var sessionOutcome: SDKEvent? {
        events.last {
            $0.category == .session &&
            ($0.status == .success || $0.status == .failed || $0.status == .abandoned)
        }
    }

    /// Kullanıcının en son bulunduğu ekran (terk/sonuç anında "nerede kaldı").
    var lastScreen: String? {
        sessionOutcome?.metadata["lastScreen"]
            ?? sessionOutcome?.screen
            ?? events.last(where: { $0.screen != nil })?.screen
    }

    // MARK: Demo / showcase üreticisi

    /// Rehber ekranında "olay örgüsü"nü göstermek için temsilî bir akış simüle eder.
    /// (Gerçek oturumda bu olaylar SDK tarafından otomatik yayınlanır.)
    func simulate(_ scenario: DemoScenario) {
        reset()
        let session = UUID().uuidString
        var steps: [SDKEvent] = []

        func ev(_ name: String, _ cat: SDKEventCategory, _ status: SDKEventStatus,
                module: String? = nil, screen: String? = nil,
                message: String? = nil, meta: [String: String] = [:]) -> SDKEvent {
            SDKEvent(name: name, category: cat, status: status, module: module,
                     screen: screen, sessionId: session, message: message, metadata: meta)
        }

        steps.append(ev("session.started", .session, .info))
        steps.append(ev("module.Prepare.presented", .module, .presented, module: "Prepare", screen: "Prepare"))
        steps.append(ev("module.Prepare.completed", .module, .completed, module: "Prepare", screen: "Prepare"))
        steps.append(ev("module.Id Card.presented", .module, .presented, module: "Id Card", screen: "Id Card"))
        steps.append(ev("module.Id Card.completed", .module, .completed, module: "Id Card", screen: "Id Card"))
        steps.append(ev("module.Mrz & Nfc Screen.presented", .module, .presented, module: "Mrz & Nfc Screen", screen: "Mrz & Nfc Screen"))

        switch scenario {
        case .success:
            steps.append(ev("module.Mrz & Nfc Screen.completed", .module, .completed, module: "Mrz & Nfc Screen", screen: "Mrz & Nfc Screen"))
            steps.append(ev("module.Selfie.presented", .module, .presented, module: "Selfie", screen: "Selfie"))
            steps.append(ev("module.Selfie.completed", .module, .completed, module: "Selfie", screen: "Selfie"))
            steps.append(ev("call.connected", .call, .info, screen: "Call Wait Screen"))
            steps.append(ev("call.ended", .call, .info, screen: "Call Wait Screen", message: "approved",
                            meta: ["statusSummary": "success"]))
            steps.append(ev("session.completed", .session, .success, screen: "Call Wait Screen",
                            message: "approved", meta: ["statusSummary": "success", "lastScreen": "Call Wait Screen"]))

        case .failed:
            steps.append(ev("module.Mrz & Nfc Screen.failed", .module, .failed, module: "Mrz & Nfc Screen",
                            screen: "Mrz & Nfc Screen", message: "chip_read_error"))
            steps.append(ev("call.connected", .call, .info, screen: "Call Wait Screen"))
            steps.append(ev("call.ended", .call, .info, screen: "Call Wait Screen", message: "rejected",
                            meta: ["statusSummary": "fail"]))
            steps.append(ev("session.failed", .session, .failed, screen: "Call Wait Screen",
                            message: "rejected", meta: ["statusSummary": "fail", "lastScreen": "Call Wait Screen", "reason": "rejected"]))

        case .abandoned:
            steps.append(ev("session.abandoned", .session, .abandoned, screen: "Mrz & Nfc Screen",
                            message: "user_left", meta: ["lastScreen": "Mrz & Nfc Screen", "reason": "user_left"]))
        }

        events = steps
    }

    enum DemoScenario {
        case success, failed, abandoned
    }
}
