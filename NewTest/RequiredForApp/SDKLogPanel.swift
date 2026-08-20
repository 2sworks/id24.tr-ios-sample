//
//  SDKLogPanel.swift
//  NewTest
//
//  netfox panelinin kurulumu: HTTP, konsol ve WebSocket logları tek yerde.
//

import Foundation
import UIKit
import netfox
import IdentifySDK

/// Uygulama açılışında netfox panelini kurar.
///
/// Panel sallayarak açılır ve üç sekme taşır:
/// - **Network**: netfox'un kendi `URLSession` kaydı.
/// - **Console**: yakalanan `stdout`/`stderr` satırları ile SDK'nın yapısal log akışı.
/// - **Socket**: `IdentifyManager.getSocketLogs()` üzerinden WebSocket trafiği.
enum SDKLogPanel {

    /// Paneli kurar ve hangi sekmelerin açılacağını belirler.
    ///
    /// - Parameters:
    ///   - requests: HTTP trafiği sekmesi. Kapalıyken istek kaydı hiç tutulmaz.
    ///   - console: Konsol sekmesi. Kapalıyken `stdout`/`stderr` yakalanmaz.
    ///   - socket: WebSocket sekmesi.
    static func start(requests: Bool = true, console: Bool = true, socket: Bool = true) {
        NFX.sharedInstance().isRequestsTabEnabled = requests
        NFX.sharedInstance().isConsoleTabEnabled = console
        NFX.sharedInstance().isExternalTabEnabled = socket

        // Konsol yakalama netfox'tan önce açılır; netfox'un kendi başlangıç
        // satırları da panele düşsün.
        if console {
            NFX.sharedInstance().startConsoleCapture()
        }
        if socket {
            NFX.sharedInstance().externalLogSource = socketLogSource()
        }
        NFX.sharedInstance().start()

        if console {
            bindSDKLogHandler()
        }
    }

    /// SDK'nın yapısal log akışını konsol sekmesine bağlar.
    ///
    /// Aynı satır `stdout` üzerinden de yakalanır; `NFXLogStore` yinelenen kaydı
    /// eler ve tür bilgisi taşıyan yapısal olanı tutar.
    private static func bindSDKLogHandler() {
        IdentifyManager.shared.logHandler = { entry in
            NFX.sharedInstance().log(entry.message, type: entry.type)
        }
    }

    /// WebSocket kayıtlarını panelin anlayacağı biçime çevirir.
    private static func socketLogSource() -> NFXExternalLogSource {
        return NFXExternalLogSource(title: "Socket") {
            IdentifyManager.shared.getSocketLogs().map { log in
                let isIncoming = log.socketType == .incoming
                return NFXExternalLogEntry(
                    label: isIncoming ? "IN" : "OUT",
                    message: log.socketMsg ?? "",
                    tint: isIncoming
                        ? UIColor(red: 0.30, green: 0.62, blue: 0.95, alpha: 1.0)
                        : UIColor(red: 0.95, green: 0.60, blue: 0.20, alpha: 1.0)
                )
            }
        }
    }
}
