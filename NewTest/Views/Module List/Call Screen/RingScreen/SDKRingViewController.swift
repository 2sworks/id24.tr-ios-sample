//
//  SDKRingViewController.swift
//  NewTest
//
//  Created by Emir Beytekin on 15.11.2022.
//

import UIKit
import IdentifySDK

class SDKRingViewController: SDKBaseViewController {

    @IBOutlet weak var desc1Lbl: UILabel!
    @IBOutlet weak var desc2Lbl: UILabel!
    weak var delegate: CallScreenDelegate?

    /// ⚠️ `socket.onDisconnect` **tek slotlu**. Base sınıf her `viewWillAppear`'da bu slotu
    /// kendi üzerine yazıyor; çalma ekranı da yazsaydı kopma anında yeniden bağlanma ekranını
    /// bu ekran açar ve `SDKListenSocketViewController`'ın delegate'i olurdu. O zaman reconnect
    /// sonucu (`reconnectCompletedWithStatus`) çağrı ekranına hiç ulaşmaz, base sınıftaki boş
    /// implementasyona düşerdi: görüşme ekranı bekleme durumuna dönmeden eski haliyle kalırdı.
    /// Kopmayı zaten çağrı ekranı dinliyor.
    override var listensToSocketDisconnect: Bool { false }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    private func setupUI() {
        self.desc1Lbl.text = self.translate(text: .callTitle)
        self.desc2Lbl.text = self.translate(text: .callDescription)
    }

    @IBAction func acceptAct(_ sender: Any) {
        self.dismiss(animated: true) {
            self.delegate?.acceptCall()
        }
    }
}
