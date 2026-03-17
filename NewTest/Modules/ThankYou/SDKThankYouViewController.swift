//
//  SDKThankYouViewController.swift
//  NewTest
//
//  Created by Emir Beytekin on 18.11.2022.
//

import UIKit

class SDKThankYouViewController: SDKBaseViewController {

    @IBOutlet weak var closeBtn: IdentifyButton!
    @IBOutlet weak var successLbl: UILabel!
    @IBOutlet weak var desc1Lbl: UILabel!
    @IBOutlet weak var desc2Lbl: UILabel!
    @IBOutlet weak var statusImg: UIImageView!
    
    var completeStatus: CallStatus?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItem = nil
    }
    
    private func setupUI() {
        self.manager.kycIsCompleted = true
        closeBtn.type = .submit
        closeBtn.setTitle(self.translate(text: .coreOk), for: .normal)
        closeBtn.onTap = {
            self.dismiss(animated: true)
        }
        closeBtn.populate()
        
        switch completeStatus {
        case .completed:
            self.statusImg.image = UIImage(named: "successTick")
            self.successLbl.text = self.translate(text: .thankU)
            if manager.isSelfieIdent {
                self.desc1Lbl.text = self.translate(text: .selfieIdentInfo1)
                self.desc2Lbl.text = self.translate(text: .selfieIdentInfo2)
            } else {
                self.desc1Lbl.text = self.translate(text: .selfieIdentInfo3)
                self.desc2Lbl.text = ""
            }
        case .missedCall:
            self.statusImg.image = UIImage(named: "missedCall")
            self.successLbl.text = self.translate(text: .missedCallTitle)
            self.desc1Lbl.text = self.translate(text: .missedCallSubTitle)
            self.desc2Lbl.text = ""
        case .notCompleted:
            self.statusImg.image = UIImage(named: "sadFace")
            self.successLbl.text = self.translate(text: .identifyFailedTitle)
            self.desc1Lbl.text = self.translate(text: .identifyFailedDesc)
            self.desc2Lbl.text = ""
        default:
            return
        }
        
        UIApplication.shared.isIdleTimerDisabled = false
    }
}
