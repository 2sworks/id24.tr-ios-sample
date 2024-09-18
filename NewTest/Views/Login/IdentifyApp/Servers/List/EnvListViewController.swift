//
//  EnvListViewController.swift
//  NewTest
//
//  Created by Emir Beytekin on 7.09.2023.
//

import UIKit
import CoreData

class EnvListViewController: SDKBaseViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var serverList = [SelectedServerSettings]()
    
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    
    var manageObjectContext: NSManagedObjectContext!
    
    var cominData: [NSManagedObject]? = [NSManagedObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.title = "Kayıtlı Sunucular"
        manageObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        navigationItem.rightBarButtonItem = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.getItems()
    }
    
    func getItems() {
        
        serverList.removeAll()
        cominData?.removeAll()
        
        let managedContext = appDelegate?.persistentContainer.viewContext
                
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "EnvServers")
        
        do {
            let fetchResults = try managedContext?.fetch(fetchRequest)
            for item in fetchResults as! [NSManagedObject] {
                self.cominData?.append(item)
                var selectedServer = SelectedServerSettings()
                selectedServer.apiUrl = item.value(forKey: "apiUrl") as! String
                selectedServer.websocketUrl = item.value(forKey: "socketUrl") as! String
                selectedServer.turnUrl = item.value(forKey: "turnUrl") as! String
                selectedServer.stunUrl = item.value(forKey: "stunUrl") as! String
                selectedServer.turnUser = item.value(forKey: "turnUser") as! String
                selectedServer.turnPassword = item.value(forKey: "turnPass") as! String
                selectedServer.envTitle = item.value(forKey: "envTitle") as! String

                self.serverList.append(selectedServer)
            }
            self.tableView.reloadData()
            if self.serverList.count == 0 {
                let alert = UIAlertController(title: "Identify", message: "Bu alanda kendinize ait test sunucularını ekleyip/çıkartabilirsiniz.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Tamam", style: .default, handler: {_ in
                    print("")
                }))
                self.present(alert, animated: true, completion: nil)
            }
            
        } catch let error{
            print(error.localizedDescription)
        }
    }
    
    
    @IBAction func addNewAct(_ sender: Any) {
        let next = ServerSettingsViewController()
        self.navigationController?.pushViewController(next, animated: true)
    }
    
}

extension EnvListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return serverList.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        if indexPath.row % 2 == 0 {
            cell.backgroundColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        } else {
            cell.backgroundColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
        }
        
        let data = serverList[indexPath.row]
        if data.envTitle == "" {
            cell.textLabel?.text = "Not Defined Env Name"
        } else {
            cell.textLabel?.text = data.envTitle
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let data = cominData![indexPath.row]
        if editingStyle == .delete {
            manageObjectContext.delete(data)
            do {
                try manageObjectContext.save()
                self.serverList.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
    }
    
    
    
}
