//
//  SDKNetworkLogger.swift
//  NewTest
//

import Foundation
import UIKit

// MARK: - NFXDebugState

final class NFXDebugState: ObservableObject {
    static let shared = NFXDebugState()
    @Published var isEnabled = false
    private init() {}
}

// MARK: - SDKWindow

class SDKWindow: UIWindow {
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        guard motion == .motionShake, NFXDebugState.shared.isEnabled else { return }
        NotificationCenter.default.post(name: .sdkNetworkDebugShake, object: nil)
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let sdkNetworkDebugShake = Notification.Name("SDKNetworkDebugShake")
}
