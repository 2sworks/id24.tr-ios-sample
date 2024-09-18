//
//  SDKModuleListViewController.swift
//  NewTest
//
//  Created by Emir Beytekin on 17.11.2023.
//

import UIKit
import IdentifySDK

protocol SDKManualModulDelegate: AnyObject {
    func updateModules(moduleList: [SdkModules])
}

class SDKModuleListViewController: SDKBaseViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var saveBtn: IdentifyButton!
    weak var updateDelegate: SDKManualModulDelegate?
    
    var identifyModules:[SdkModules]? = [.prepare, .idCard, .nfc, .livenessDetection, .speech, .addressConf, .signature, .videoRecord, .selfie, .waitScreen]
    var list = [SdkModules]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.list = identifyModules ?? []
        self.tableView.delegate = self
        self.tableView.dataSource = self
        tableView.reloadData()
        navigationItem.rightBarButtonItem = nil
        self.setupUI()
    }
    
    private func addEditBtn() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Düzenle", style: .plain, target: self, action: #selector(setEditTableView))
    }
    
    @objc func setEditTableView() {
        self.tableView.setEditing(!self.tableView.isEditing, animated: true)
    }
    
    private func setupUI() {
        saveBtn.setTitle("Listeyi Kaydet", for: .normal)
        saveBtn.type = .submit
        saveBtn.onTap = {
            self.updateDelegate?.updateModules(moduleList: self.list)
            self.navigationController?.popToRootViewController(animated: true)
        }
        saveBtn.populate()
        self.addEditBtn()
    }
    
    private func appendAllModules() {
        self.identifyModules = [.prepare, .idCard, .nfc, .livenessDetection, .speech, .addressConf, .signature, .videoRecord, .selfie, .waitScreen]
    }
    
    private func removeAllModules() {
        self.identifyModules = []
    }

}

extension SDKModuleListViewController: UITableViewDelegate, UITableViewDataSource {
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.list.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let data = list[indexPath.row]
        cell.textLabel?.text = data.rawValue
        return cell
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            list.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
        }
    }
    
    func tableView(_ tableView: UITableView, moveRowAt indexPath: IndexPath, to: IndexPath) {
        let itemToMove = list[indexPath.row]
        list.remove(at: indexPath.row)
        list.insert(itemToMove, at: to.row)
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
    }

    // Override to support conditional rearranging of the table view.
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Modül listesi aşağıdaki gibidir."
        }
        return ""
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return "Değişiklikler için kaydetmeyi unutmayın, aksi halde web modül listesinden devam edecektir"
        }
        return ""
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 50
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
}
