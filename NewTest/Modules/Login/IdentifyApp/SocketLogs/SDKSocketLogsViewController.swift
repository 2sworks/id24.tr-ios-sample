//
//  SDKSocketLogsViewController.swift
//  NewTest
//
//  Created by Emir Beytekin on 7.12.2023.
//

import UIKit
import IdentifySDK

class SDKSocketLogsViewController: SDKBaseViewController {

    var tableCell: SocketLogTableViewCell?
    @IBOutlet weak var tableView: UITableView!
    var socketItems: [SocketLog] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerFromXIB(cellIdentifier: "SocketLogTableViewCell")
        self.socketItems.removeAll()
        self.setupUI()
    }
    
    func setupUI() {
        self.socketItems = self.manager.getSocketLogs()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.reloadData()
    }

}



extension SDKSocketLogsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return socketItems.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SocketLogTableViewCell", for: indexPath) as! SocketLogTableViewCell
        let data = self.socketItems[indexPath.row]
        cell.msgLbl.text = data.socketMsg
        if data.socketType == .incoming {
            cell.actionView.backgroundColor = .green
            cell.msgDirection.text = "IN"
        } else {
            cell.actionView.backgroundColor = .red
            cell.msgDirection.text = "OUT"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = self.socketItems[indexPath.row]
        
        guard let cell = tableView.cellForRow(at: indexPath) as? SocketLogTableViewCell else {
                return
            }

            guard let textToCopy = cell.msgLbl.text else {
                return
            }

            UIPasteboard.general.string = textToCopy

            // UIAlertController kullanarak geri bildirim göster
            let alert = UIAlertController(title: "Kopyalandı", message: "Metin panoya kopyalandı.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Tamam", style: .default, handler: nil))

            present(alert, animated: true, completion: nil)
    
    }
    
    
}


extension UITableView {
    func registerFromXIB(cellIdentifier : String){
        let nib = UINib(nibName: cellIdentifier, bundle: nil)
        self.register(nib, forCellReuseIdentifier: cellIdentifier)
    }
}
