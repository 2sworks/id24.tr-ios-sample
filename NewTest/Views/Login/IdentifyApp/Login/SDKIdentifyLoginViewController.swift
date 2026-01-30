//
//  SDKIdentifyLoginViewController.swift
//  NewTest
//
//  Created by Emir Beytekin on 17.11.2023.
//

import UIKit
import IdentifySDK
import CoreData

class SDKIdentifyLoginViewController: SDKBaseViewController {

    @IBOutlet weak var langBtn: IdentifyButton!
    @IBOutlet weak var loginBtn: IdentifyButton!
    @IBOutlet weak var identIdArea: UITextField!
    @IBOutlet weak var selfIdentBtn: IdentifyButton!
    var subRejected = false
    @IBOutlet weak var versionNo: UILabel!
    @IBOutlet weak var jbView: UIView!
    var selectedServer = SelectedServerSettings()
    var envList = [SelectedServerSettings]()
    @IBOutlet weak var serverSettingsBtn: IdentifyButton!
    var userDefaults = UserDefaults.standard
    
    var selectedModuleList = [SdkModules]()
    @IBOutlet weak var bigCustomerBtn: IdentifyButton!
    @IBOutlet weak var signLangBtn: IdentifyButton!
    var editedShowBigCustomer = false
    var editedSignLang = false
    @IBOutlet weak var newLivenessBtn: IdentifyButton!
    @IBOutlet weak var sslPinningBtn: IdentifyButton!
    
    var idLang: IDLang? = .TR
    var useSSLPinning = false
    
    @IBOutlet weak var serverSelector: IdentifyButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupSDK()
    }
    
    // MARK:  Modül - Controller eşleşmesi yapıyoruz
    
    private func setupSDK() { // Modül - Controller eşleşmesi yapıyoruz
        self.manager.setSDKLang(lang: .eng)
        self.manager.loginModuleController = SDKLoginViewController.instantiate()
        self.manager.selfieModuleController = SDKSelfieViewController.instantiate()
        self.manager.idCardModuleController = SDKCardReaderViewController.instantiate()
        self.manager.idCardOVDModuleController = SDKOVDViewController.instantiate()
        self.manager.nfcModuleController = SDKNfcViewController.instantiate()
        self.manager.signatureModuleController = SDKSignatureViewController.instantiate()
        self.manager.videoRecorderModuleController = SDKVideoRecorderViewController.instantiate()
        self.manager.livenessModuleController = SDKLivenessViewController.instantiate()
        self.manager.addressModuleController = SDKAddressConfirmViewController.instantiate()
        self.manager.liveStreamModuleController = SDKCallScreenViewController.instantiate()
        self.manager.speechModuleController = SDKSpeechRecViewController.instantiate()
        self.manager.thankYouViewController = SDKThankYouViewController.instantiate()
        self.manager.prepareViewController = SDKPrepareViewController.instantiate()
        self.manager.socketMessageListener = self // eğer odada farklı bir kişi varsa listener sayesinde detect edebiliyoruz.
        self.setupUI()
        if manager.jailBreakStatus {
            self.jbView.isHidden = false
            print("cihazda jb tespit edildi, bu durumu yönetebilirsiniz.")
        }
        self.selectedServer.apiUrl = "https://v2api.identify.com.tr"
        self.selectedServer.websocketUrl = "wss://v2ws.identify.com.tr"
    }
    
    private func setupUI() {
        self.loginBtn.setTitle(self.translate(text: .connect), for: .normal)
        self.loginBtn.type = .submit
        self.loginBtn.onTap = {
            self.loginSystem()
        }
        self.loginBtn.populate()
        
        self.langBtn.setTitle("Select SDK Language", for: .normal)
        self.langBtn.type = .cancel
        self.langBtn.onTap = {
            self.showLangOptions()
        }
        self.serverSettingsBtn.setTitle(self.translate(text: .coreSettings), for: .normal)
        self.serverSettingsBtn.type = .submit
        self.serverSettingsBtn.onTap = {
            self.showSettingsOptions()
        }
        self.serverSettingsBtn.populate()
        self.langBtn.populate()
        self.versionNo.text = "Build No: \(Bundle.main.buildVersionNumber ?? "")"
        self.navigationItem.rightBarButtonItem = nil
        self.identIdArea.delegate = self
        self.identIdArea.tag = 0
        self.identIdArea.returnKeyType = .go
        
        self.bigCustomerBtn.type = .info
        self.signLangBtn.type = .info
        self.newLivenessBtn.type = .info
        self.sslPinningBtn.type = .info
        self.bigCustomerBtn.populate()
        self.signLangBtn.populate()
        self.newLivenessBtn.populate()
        self.sslPinningBtn.populate()
        
        self.setupOptionButtons()
    }
    
    private func setupOptionButtons() {
        bigCustomerBtn.titleLabel?.numberOfLines = 0
        bigCustomerBtn.titleLabel?.lineBreakMode = .byWordWrapping
        bigCustomerBtn.setImage(UIImage(named: "emptyTick"), for: .normal)
        bigCustomerBtn.setImage(UIImage(named: "checkTick"), for: .selected)
        bigCustomerBtn.tag = 1
        bigCustomerBtn.addTarget(self, action: #selector(checkBoxTapped(_ :)), for: .touchUpInside)
        
        
        signLangBtn.titleLabel?.numberOfLines = 0
        signLangBtn.titleLabel?.lineBreakMode = .byWordWrapping
        signLangBtn.setImage(UIImage(named: "emptyTick"), for: .normal)
        signLangBtn.setImage(UIImage(named: "checkTick"), for: .selected)
        signLangBtn.tag = 2
        signLangBtn.addTarget(self, action: #selector(checkBoxTapped(_ :)), for: .touchUpInside)
        
        newLivenessBtn.titleLabel?.numberOfLines = 0
        newLivenessBtn.titleLabel?.lineBreakMode = .byWordWrapping
        newLivenessBtn.setImage(UIImage(named: "emptyTick"), for: .normal)
        newLivenessBtn.setImage(UIImage(named: "checkTick"), for: .selected)
        newLivenessBtn.tag = 3
        newLivenessBtn.addTarget(self, action: #selector(checkBoxTapped(_ :)), for: .touchUpInside)
        
        sslPinningBtn.titleLabel?.numberOfLines = 0
        sslPinningBtn.titleLabel?.lineBreakMode = .byWordWrapping
        sslPinningBtn.setImage(UIImage(named: "emptyTick"), for: .normal)
        sslPinningBtn.setImage(UIImage(named: "checkTick"), for: .selected)
        sslPinningBtn.tag = 4
        sslPinningBtn.addTarget(self, action: #selector(checkBoxTapped(_ :)), for: .touchUpInside)
    }
    
    
    @objc func checkBoxTapped(_ sender: UIButton) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        switch sender.tag {
            case 1:
                bigCustomerBtn.isSelected = !bigCustomerBtn.isSelected
                self.editedShowBigCustomer = bigCustomerBtn.isSelected
            case 2:
                signLangBtn.isSelected = !signLangBtn.isSelected
                self.editedSignLang = signLangBtn.isSelected
            case 3:
                newLivenessBtn.isSelected = !newLivenessBtn.isSelected
                if (newLivenessBtn.isSelected) {
                    self.manager.livenessModuleController = SDKNewLivenessViewController.instantiate()
                } else {
                    self.manager.livenessModuleController = SDKLivenessViewController.instantiate()
                }
            case 4:
                sslPinningBtn.isSelected = !sslPinningBtn.isSelected
                self.useSSLPinning = sslPinningBtn.isSelected
            default:
                return
        }
    }
    
    // MARK:  Sisteme giriş yapıyoruz
    
    private func connectSDK() {
        self.view.endEditing(true)
        if identIdArea.text == "xxx" {
            self.identIdArea.text = "eaebe29505c8c27ab68a626f8c0a8bb61e61d3f9"
        } else if identIdArea.text == "x" {
            self.identIdArea.text = "1404df9c1cbd6c66bbb3c9217ea4bbfc1157fd33"
        } else if identIdArea.text == "y" {
            self.identIdArea.text = "7fc133f53bb05aa7547b671db589dff994c62fcc"
        } else if identIdArea.text == "oo" {
            self.identIdArea.text = "87b9dc12bc003f80ab47c8d80d500349e6a31c5a"
        } else if identIdArea.text == "tahsin" {
            self.identIdArea.text = "70a156b19356e600c7ccce3bb3061886091c39b7"
        } else if identIdArea.text == "h" {
            self.identIdArea.text = "600d7388a82294f712147672ef56965c77d92f41"
        } else if identIdArea.text == "qa" {
            self.identIdArea.text = "1404df9c1cbd6c66bbb3c9217ea4bbfc1157fd33"
        } else if identIdArea.text == "busra" {
            self.identIdArea.text = "14412dd4616298aabbd80c9628860ed8d214c288"
        } else if identIdArea.text == "c" {
            self.identIdArea.text = "3e72ce1cd9872ccdd7dca0affad6abb57a9ca73e"
        } else if identIdArea.text == "c2" {
            self.identIdArea.text = "a170357f1ed311b3c49880a5ec2f1d78d0bf624d"
        }
        
        self.showLoader()
        
        self.manager.enableDebugPrint = true
        self.manager.setupSDK(
            identId: identIdArea.text!,
            baseApiUrl: self.selectedServer.apiUrl,
            networkOptions: SDKNetworkOptions(timeoutIntervalForRequest: 30,
                                              timeoutIntervalForResource: 30,
                                              useSslPinning: self.useSSLPinning),
            kpsData: nil, // EĞER ELİNİZDE KPS DEN GELEN KİMLİK DATALARI VARSA ALTTAKİ KODU AKTİF EDİP BU SATIRI SİLEBİLİRSİNİZ.
//                kpsData: SDKKpsData(birthDate: "860704", validDate: "130627", serialNo: "YZM33MR63"),
            identCardType: [.idCard, .passport, .oldSchool], // destekleyeceğiniz kart tipleri
            signLangSupport: editedSignLang, // işitme engelliler için müşteri temsilcisi desteği
            nfcMaxErrorCount: 3,
            logLevel: .online,
            logOnlineSecretKey: "dGhpc19pc19qdXN0X2R1bW15X3NlY3JldF9mb3JfZGVtbw==",
            bigCustomerCam: editedShowBigCustomer,
            selectedModules: self.selectedModuleList,
            idCardLang: self.idLang,
            turnKey: "AEdHh9OZu1kg+nSBSd2UNMu9y4Kc3xVfgTsvw+PTAic=",
            showThankYouPage: true,
            showNFCNotFoundPage: true,
            supportU18: true,
            AESKey: "SEATSJ8kk0v8+A1LeQsAMbOgL+fSj9pOaUKI5cDMITU=",
            enableAutoRotateOCR: true
        ) { socketStats, apiResp, webErr in
                
            print("socket resp : \(socketStats)")
            if let err = webErr, err.errorMessages != "" { // web servisten hata gelirse
                self.showToast(type:. fail, title: self.translate(text: .coreError), subTitle: apiResp.response_status == 409 ? apiResp.messages?.first : err.errorMessages, attachTo: self.view) {
                    self.hideLoader()
                }
            } else { // hata yoksa işlemlere devam ediyoruz
                if socketStats?.isConnected ==  true {
                    if apiResp.result ?? false {
                        self.manager.moduleStepOrder = 0
                        self.hideLoader()
                        self.manager.getNextModule { nextVC in
                            if !self.subRejected {
                                let navigationC = UINavigationController(rootViewController: nextVC)
                                navigationC.isModalInPresentation = true
                                self.showToast(title: self.translate(text: .coreSuccess), subTitle: self.translate(text: .loadingFirstModule), attachTo: self.view, callback: {
                                    DispatchQueue.main.async {
                                        self.navigationController?.present(navigationC, animated: true) // İlk modül başlıyor
                                    }
                                })
                            }
                        }
                    } else if (socketStats?.isConnected == false) {
                        self.showToast(title: "Socket not connected", attachTo: self.view) {
                            self.hideLoader()
                        }
                        print("socket down")
                    }
                } else {
                    self.hideLoader()
                }
            }
        }
    }
    
    private func loginSystem() {
        if identIdArea.text == "" {
            self.showToast(type: .fail, title: self.translate(text: .coreError), subTitle: "Ident ID Girmediniz", attachTo: self.view) {
                return
            }
        } else {
            self.showIdLang()
//            self.showNetworkOptions()
        }
    }
    
    func getCustomList() {
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

extension SDKIdentifyLoginViewController: SDKSocketListener {
    
    func listenSocketMessage(message: SDKCallActions) {
        switch message {
            case .wrongSocketActionErr(let error):
                self.hideLoader()
                self.showToast(type: .fail, title: self.translate(text: .coreError), subTitle: error, attachTo: self.view) {
                    return
                }
                return
                
            case .subrejectedDismiss:
                self.subRejected = true
                self.showToast(type: .fail, title: self.translate(text: .coreError), subTitle: self.translate(text: .anotherUserInToTheRoom), attachTo: self.view) {
                    return
                }
            default:
                self.subRejected = false
                return
        }
    }
}

extension SDKIdentifyLoginViewController { // Dil seçme & değiştirme işlemleriasdadsa
    
    func goToModuleScreen() {
        let next = SDKModuleListViewController()
        next.updateDelegate = self
        self.navigationController?.pushViewController(next, animated: true)
    }
    
    func showSettingsOptions() {
        let actionSheetController: UIAlertController = UIAlertController(title: "Yapmak istediğiniz düzenlemeyi seçin", message: nil, preferredStyle: .actionSheet)

        let firstAction: UIAlertAction = UIAlertAction(title: "Modül Seçme Ekranı", style: .default) { action -> Void in
            self.goToModuleScreen()
        }
        
        let secondAct: UIAlertAction = UIAlertAction(title: "Sunucu Ayarları", style: .default) { action -> Void in
            let next = EnvListViewController()
            let nc = UINavigationController(rootViewController: next)
            self.present(nc, animated: true)
        }
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in }

        
        actionSheetController.addAction(firstAction)
        actionSheetController.addAction(secondAct)
        actionSheetController.addAction(cancelAction)
        actionSheetController.popoverPresentationController?.sourceView = self.view
        present(actionSheetController, animated: true)
    }
    
    func showIdLang() {
        let actionSheetController: UIAlertController = UIAlertController(title: "Okutulacak kimlik / pasaport dilini seçin", message: nil, preferredStyle: .actionSheet)

        let firstAction: UIAlertAction = UIAlertAction(title: "Türkçe", style: .default) { action -> Void in
            self.idLang = .TR
            self.showNetworkOptions()
        }
        
        let secondAct: UIAlertAction = UIAlertAction(title: "Diğer", style: .default) { action -> Void in
            self.idLang = .OTHER
            self.showNetworkOptions()
        }
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in }

        
        actionSheetController.addAction(firstAction)
        actionSheetController.addAction(secondAct)
        actionSheetController.addAction(cancelAction)
        actionSheetController.popoverPresentationController?.sourceView = self.view
        present(actionSheetController, animated: true)
    }
    
    func showNetworkOptions() {
        let actionSheetController: UIAlertController = UIAlertController(title: "Bağlanmak istediğiniz sunucuyu seçin", message: nil, preferredStyle: .actionSheet)
        
        let firstAction: UIAlertAction = UIAlertAction(title: "Live", style: .default) { action -> Void in
            self.selectedServer.apiUrl = "https://api.identify.com.tr/"
            self.selectedServer.envTitle = "Live"
            self.connectSDK()
        }
        
        let secondAct: UIAlertAction = UIAlertAction(title: "Test", style: .default) { action -> Void in
            self.selectedServer.apiUrl = "https://apitest.identify.com.tr/"
            self.selectedServer.envTitle = "Test"
            self.connectSDK()
        }
        
        let thirdAct: UIAlertAction = UIAlertAction(title: "Dev", style: .default) { action -> Void in
            self.selectedServer.apiUrl = "https://apidev.identify.com.tr/"
            self.selectedServer.envTitle = "Dev"
            self.connectSDK()
        }
        
        let forthAct: UIAlertAction = UIAlertAction(title: "V2", style: .default) { action -> Void in
            self.selectedServer.apiUrl = "https://v2api.identify.com.tr/"
            self.selectedServer.envTitle = "V2"
            self.connectSDK()
        }
        
        let fifthAct: UIAlertAction = UIAlertAction(title: "QA", style: .default) { action -> Void in
            self.selectedServer.apiUrl = "https://apiqa.identify.com.tr"
            self.selectedServer.envTitle = "QA"
            self.connectSDK()
        }
        
        actionSheetController.addAction(firstAction)
        actionSheetController.addAction(secondAct)
        actionSheetController.addAction(thirdAct)
        actionSheetController.addAction(forthAct)
        actionSheetController.addAction(fifthAct)
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
                
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "EnvServers")
        
        do {
            let fetchResults = try managedContext.fetch(fetchRequest)
            for item in fetchResults as! [NSManagedObject] {
                
                let newAct: UIAlertAction = UIAlertAction(title: item.value(forKey: "envTitle") as? String, style: .default) { action -> Void in
                    self.selectedServer.apiUrl = item.value(forKey: "apiUrl") as! String
                    self.selectedServer.envTitle = item.value(forKey: "envTitle") as! String
                    self.connectSDK()
                }
                actionSheetController.addAction(newAct)
            }
            
        } catch let error {
            print(error.localizedDescription)
        }
//        actionSheetController.addAction(fifthAct)
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in }
        actionSheetController.addAction(cancelAction)
        actionSheetController.popoverPresentationController?.sourceView = self.view
        present(actionSheetController, animated: true)
    }
    
    
    @objc func showLangOptions() {
        let actionSheetController: UIAlertController = UIAlertController(title: "SDK Dilini Seçin", message: nil, preferredStyle: .actionSheet)
        
        let firstAction: UIAlertAction = UIAlertAction(title: "Ingilizce", style: .default) { action -> Void in
            self.manager.setSDKLang(lang: .eng)
            self.setupUI()
        }
        
        let secondAct: UIAlertAction = UIAlertAction(title: "Türkçe", style: .default) { action -> Void in
            self.manager.setSDKLang(lang: .tr)
            self.setupUI()
        }
        
        let thirdAct: UIAlertAction = UIAlertAction(title: "Almanca", style: .default) { action -> Void in
            self.manager.setSDKLang(lang: .de)
            self.setupUI()
        }
        
        let russianAct: UIAlertAction = UIAlertAction(title: "Rusça", style: .default) { action -> Void in
            self.manager.setSDKLang(lang: .ru)
            self.setupUI()
        }
        
        let azeriAct: UIAlertAction = UIAlertAction(title: "Azerice", style: .default) { action -> Void in
            self.manager.setSDKLang(lang: .az)
            self.setupUI()
        }
        actionSheetController.addAction(firstAction)
        actionSheetController.addAction(secondAct)
        actionSheetController.addAction(thirdAct)
        actionSheetController.addAction(russianAct)
        actionSheetController.addAction(azeriAct)
        
        actionSheetController.popoverPresentationController?.sourceView = self.view
        present(actionSheetController, animated: true)
    }
    
    
}

extension SDKIdentifyLoginViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        if textField.tag == 0 {
            self.view.endEditing(true)
//            self.showNetworkOptions()
            self.showIdLang()
            return true
        }
        
        return true
    }
}


extension SDKIdentifyLoginViewController: SDKManualModulDelegate {
    func updateModules(moduleList: [SdkModules]) {
        self.selectedModuleList = moduleList
    }
    
    
}
