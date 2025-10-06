//
//  SDKSignLangViewController.swift
//  NewTest
//
//  Created by Emir Beytekin on 21.11.2022.
//

import UIKit

protocol SDKSignLangViewControllerDelegate: AnyObject {
    func sdkSignLangViewControllerDidFinish(_ controller: SDKSignLangViewController)
}

class SDKSignLangViewController: SDKBaseViewController {
    
    weak var delegate: SDKSignLangViewControllerDelegate?

    @IBOutlet weak var signSwitch: UISwitch!
    @IBOutlet weak var acceptBtn: IdentifyButton!
    @IBOutlet weak var descLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    private func setupUI() {
        self.descLbl.text = self.translate(text: .coreSignLang)
        self.acceptBtn.type = .submit
        self.acceptBtn.setTitle(self.translate(text: .continuePage), for: .normal)
        self.acceptBtn.onTap = {
            self.manager.connectToSignLang = self.signSwitch.isOn
            self.manager.sendStep()
            self.delegate?.sdkSignLangViewControllerDidFinish(self)
            self.navigationController?.popViewController(animated: false)
        }
        self.acceptBtn.populate()
    }

}
