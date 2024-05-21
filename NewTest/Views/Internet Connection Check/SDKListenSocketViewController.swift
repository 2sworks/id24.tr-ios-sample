//
//  SDKListenSocketViewController.swift
//  NewTest
//
//  Created by Emir Beytekin on 22.11.2022.
//

import UIKit

protocol SDKNoConnectionDelegate: class {
    func reconnectCompleted()
}

class SDKListenSocketViewController: SDKBaseViewController {

    @IBOutlet weak var reConnectBtn: IdentifyButton!
    weak var delegate: SDKNoConnectionDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    private func setupUI() {
        reConnectBtn.setTitle(self.translate(text: .coreReConnect), for: .normal)
        reConnectBtn.type = .submit
        reConnectBtn.onTap = {
            self.reConnectBtn.type = .loader
            self.reConnectBtn.populate()
            self.disableConnButton(setDisable: true)
            self.manager.reconnectToSocket { [weak self] resp in
                guard let self = `self` else { return }
                if resp.isConnected {
                    self.delegate?.reconnectCompleted()
                    print("tekrar bağlantı kuruldu")
                    self.dismiss(animated: resp.isConnected)
                } else {
                    self.disableConnButton(setDisable: resp.isConnected)
                    self.reConnectBtn.type = .submit
                    self.reConnectBtn.populate()
                }
            }
        }
        reConnectBtn.populate()
    }
    
    private func disableConnButton(setDisable: Bool) {
        self.reConnectBtn.isEnabled = !setDisable
        if setDisable {
            self.reConnectBtn.setTitle(self.translate(text: .coreReconnecting), for: .normal)
            self.reConnectBtn.alpha = 1.0
            self.reConnectBtn.populate()
        } else {
            self.reConnectBtn.setTitle(self.translate(text: .coreReConnect), for: .normal)
            self.reConnectBtn.alpha = 1
            self.reConnectBtn.populate()
        }
    }

}
