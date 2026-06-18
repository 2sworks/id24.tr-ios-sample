//
//  LostConnectionViewModel.swift
//  NewTest
//

import Foundation
import IdentifySDK

@MainActor
final class LostConnectionViewModel: BaseModuleViewModel {

    @Published private(set) var isReconnecting: Bool = false
    @Published private(set) var isNetworkAvailable: Bool = true

    var onReconnectCompleted: (() -> Void)?
    var onReconnectCompletedWithStatus: ((Bool, String?) -> Void)?

    private var reachabilityTask: Task<Void, Never>?

    override init() {
        super.init()
        isNetworkAvailable = SDKReachabilityHelper.shared.connection != .unavailable
        observeReachability()
    }

    var canReconnect: Bool {
        !isReconnecting && isNetworkAvailable
    }

    func reconnect() {
        guard canReconnect else { return }
        isReconnecting = true

        if manager.socket.isConnected {
            manager.socket.disconnect()
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                doReconnect()
            }
        } else {
            doReconnect()
        }
    }

    private func doReconnect() {
        manager.reconnectToSocket(callback: { [weak self] socket in
            guard let self else { return }
            Task { @MainActor in
                self.isReconnecting = false
                if socket.isConnected {
                    self.onReconnectCompleted?()
                }
            }
        }, statusCallback: { [weak self] statusSummary in
            guard let self else { return }
            let isWaitingRoom = statusSummary?.id == -3
            Task { @MainActor in
                self.onReconnectCompletedWithStatus?(isWaitingRoom, statusSummary?.type)
            }
        })
    }

    private func observeReachability() {
        reachabilityTask = Task {
            for await notification in NotificationCenter.default.notifications(named: .reachabilityChanged) {
                guard let reachability = notification.object as? Reachability else { continue }
                switch reachability.connection {
                case .wifi, .cellular:
                    isNetworkAvailable = true
                case .unavailable:
                    isNetworkAvailable = false
                }
            }
        }
    }

    deinit {
        reachabilityTask?.cancel()
    }
}
