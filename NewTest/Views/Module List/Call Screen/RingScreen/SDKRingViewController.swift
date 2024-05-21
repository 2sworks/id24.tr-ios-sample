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
