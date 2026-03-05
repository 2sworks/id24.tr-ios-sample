//
//  SDKListenSocketViewController.swift
//  NewTest
//
//  Created by Emir Beytekin on 22.11.2022.
//

import UIKit

protocol SDKNoConnectionDelegate: AnyObject {
    func reconnectCompleted()
    func reconnectCompletedWithStatus(isWaitingRoom: Bool, statusType: String?)
}

class SDKListenSocketViewController: SDKBaseViewController {

    @IBOutlet weak var reConnectBtn: UIButton!
    weak var delegate: SDKNoConnectionDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleReachabilityChanged(_:)),
                                               name: .reachabilityChanged,
                                               object: nil)
    }
    
    private func setupUI() {
        reConnectBtn.setTitle(self.translate(text: .coreReConnect), for: .normal)
        reConnectBtn.cornerRadius = 3
        reConnectBtn.backgroundColor = IdentifyTheme.whiteColor
        reConnectBtn.setTitleColor(IdentifyTheme.submitBlueColor, for: .normal)
        reConnectBtn.dropShadow(color: .black, opacity: 0.3, offSet: CGSize(width: -1, height: 1), radius: 9, scale: true)
        reConnectBtn.addTarget(self, action: #selector(tapButton), for: .touchUpInside)
        
        if SDKReachabilityHelper.shared.reachability.connection == .unavailable {
            reConnectBtn.setTitle(self.translate(text: .coreNoInternet), for: .normal)
            toggleButton(disabled: true)
        }
        
    }
    
    @objc func tapButton() {
        
        reConnectBtn.setTitle(self.translate(text: .coreReconnecting), for: .normal)
        toggleButton(disabled: true)
        if manager.socket.isConnected {
            manager.socket.disconnect()
            reConnectBtn.setTitle("*****", for: .normal)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                self.reconnectSocket()
            })
            
        } else {
            reconnectSocket()
        }
        
        
    }
    
    func reconnectSocket() {
        
        self.manager.reconnectToSocket(callback: { [weak self] socket in
            guard let self = self else { return }
            if socket.isConnected {
                reConnectBtn.setTitle("!!!!!!", for: .normal)
                self.delegate?.reconnectCompleted()
                print("tekrar bağlantı kuruldu")
                self.dismiss(animated: true)
            } else {
                self.toggleButton(disabled: false)
                reConnectBtn.setTitle("#####", for: .normal)
            }
        }, statusCallback: { [weak self] statusSummary in
            guard let self = self else { return }
            let isWaitingRoom = statusSummary?.id == -3
            DispatchQueue.main.async {
                self.delegate?.reconnectCompletedWithStatus(isWaitingRoom: isWaitingRoom, statusType: statusSummary?.type)
            }
        })
    }
    
    func toggleButton(disabled: Bool) {
        if disabled {
            reConnectBtn.alpha = 0.2
            reConnectBtn.isUserInteractionEnabled = false
        } else {
            reConnectBtn.alpha = 1.0
            reConnectBtn.isUserInteractionEnabled = true
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .reachabilityChanged, object: nil)
    }
    
    @objc private func handleReachabilityChanged(_ note: Notification) {
        guard let reachability = note.object as? Reachability else { return }
        DispatchQueue.main.async { [weak self] in
            switch reachability.connection {
            case .wifi, .cellular:
                // Network available; enable reconnect
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    self?.reConnectBtn.setTitle(self?.translate(text: .coreReConnect), for: .normal)
                    self?.toggleButton(disabled: false)
                })
            case .unavailable:
                // No network; disable reconnect
                self?.reConnectBtn.setTitle(self?.translate(text: .coreNoInternet), for: .normal)
                self?.toggleButton(disabled: true)
            }
        }
    }

}
