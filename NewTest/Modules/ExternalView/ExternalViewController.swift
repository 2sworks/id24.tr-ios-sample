//
//  ExternalViewController.swift
//  NewTest
//
//  Created by Emir Beytekin on 24.07.2023.
//

import UIKit

class ExternalViewController: SDKBaseViewController {

    @IBOutlet weak var continueBtn: IdentifyButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.isExternalScreen = true
        self.setupUI()
    }
    
    func setupUI() {
        self.continueBtn.type = .submit
        self.continueBtn.onTap = {
            self.manager.getNextModule { nextVC in
                self.navigationController?.pushViewController(nextVC, animated: true)
            }
        }
        self.continueBtn.populate()
    }

}
