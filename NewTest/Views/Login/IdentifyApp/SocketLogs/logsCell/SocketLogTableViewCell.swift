//
//  SocketLogTableViewCell.swift
//  NewTest
//
//  Created by Emir Beytekin on 7.12.2023.
//

import UIKit

class SocketLogTableViewCell: UITableViewCell {

    @IBOutlet weak var actionView: UIView!
    @IBOutlet weak var msgLbl: UILabel!
    @IBOutlet weak var msgDirection: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
