//
//  ServerSettingsViewController.swift
//  NewTest
//
//  Created by Emir Beytekin on 7.09.2023.
//

import UIKit
import CoreData

class ServerSettingsViewController: SDKBaseViewController {

    @IBOutlet weak var apiUrlTxt: UITextField!
    @IBOutlet weak var turnUrlTxt: UITextField!
    @IBOutlet weak var stunUrlTxt: UITextField!
    @IBOutlet weak var turnUserTxt: UITextField!
    @IBOutlet weak var turnPassTxt: UITextField!
    @IBOutlet weak var socketUrlTxt: UITextField!
    @IBOutlet weak var envTitleTxt: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = nil
    }

    @IBAction func saveAct(_ sender: Any) {
        
        let control1 = self.apiUrlTxt.text?.localizedStandardContains("http")
        let control2 = self.apiUrlTxt.text?.localizedStandardContains("https")
        
        
        if (control1 == false || control2 == false) {
            self.showToast(type:.fail, title: "Check URL again!", attachTo: self.view) {
                return
            }
        } else {
            self.saveAllItems()
        }
    }
    
    func saveAllItems() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
                
        let entity = NSEntityDescription.entity(forEntityName: "EnvServers", in: managedContext)!
        
        let item = NSManagedObject(entity: entity, insertInto: managedContext)
        
        item.setValue(self.apiUrlTxt.text ?? "", forKey: "apiUrl")
        item.setValue(self.envTitleTxt.text ?? "", forKey: "envTitle")
        item.setValue(self.turnUrlTxt.text ?? "", forKey: "turnUrl")
        item.setValue(self.stunUrlTxt.text ?? "", forKey: "stunUrl")
        item.setValue(self.turnUserTxt.text ?? "", forKey: "turnUser")
        item.setValue(self.turnPassTxt.text ?? "", forKey: "turnPass")
        item.setValue(self.socketUrlTxt.text ?? "", forKey: "socketUrl")
        
        do {
            try managedContext.save()
        } catch let error {
            print("Item can't be created: \(error.localizedDescription)")
        }
        
        let alert = UIAlertController(title: "Başarılı", message: "Kaydetme işlemi başarılı", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default, handler: {_ in
            self.getItems()
            self.navigationController?.popViewController(animated: true)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func getItems() {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
                
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "EnvServers")
        
        do {
            let fetchResults = try managedContext.fetch(fetchRequest)
            for item in fetchResults as! [NSManagedObject] {
                print(item)
//                shoppingItems.append(item.value(forKey: "item") as! String)
            }
            
        } catch let error{
            print(error.localizedDescription)
        }
    }
    
}
