//
//  SDKLoginViewController.swift
//  NewTest
//
//  Created by Emir Beytekin on 25.10.2022.
//  New Sample APP

import UIKit
import IdentifySDK

class SDKLoginViewController: SDKViewOptionsController {

    @IBOutlet weak var langBtn: IdentifyButton!
    @IBOutlet weak var loginBtn: IdentifyButton!
    @IBOutlet weak var identIdArea: UITextField!
    @IBOutlet weak var selfIdentBtn: IdentifyButton!
    var subRejected = false
    @IBOutlet weak var versionNo: UILabel!
    @IBOutlet weak var jbView: UIView!
    var selectedServer = SelectedServerSettings()
    
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
        
        self.selectedServer.apiUrl = "https://v2api.identify.com.tr/"
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
        
        self.langBtn.populate()
        self.versionNo.text = "Build No: \(Bundle.main.buildVersionNumber ?? "")"
        self.navigationItem.rightBarButtonItem = nil
        
    }
    
    // MARK:  Sisteme giriş yapıyoruz
    
    private func loginSystem() {
        if identIdArea.text == "" {
            self.showToast(type: .fail, title: self.translate(text: .coreError), subTitle: "Ident ID Girmediniz", attachTo: self.view) {
                return
            }
        } else {
            self.connectSDK()
        }
    }
    
    private func connectSDK() {
        self.view.endEditing(true)
        if identIdArea.text == "xxx" {
            self.identIdArea.text = "eaebe29505c8c27ab68a626f8c0a8bb61e61d3f9"
        } else if identIdArea.text == "x" {
            self.identIdArea.text = "46ecfdf9d2650e7c4a3f99f5e3d65a9ca2891dce"
        } else if identIdArea.text == "y" {
            self.identIdArea.text = "7fc133f53bb05aa7547b671db589dff994c62fcc"
        } else if identIdArea.text == "oo" {
            self.identIdArea.text = "87b9dc12bc003f80ab47c8d80d500349e6a31c5a"
        }
        self.showLoader()
        
        self.manager.setupSDK(
            identId: identIdArea.text!,
            baseApiUrl: self.selectedServer.apiUrl,
            networkOptions: SDKNetworkOptions(timeoutIntervalForRequest: 30, timeoutIntervalForResource: 30, useSslPinning: true), // DOCS' U MUTLAKA OKUYUN!!
            kpsData: nil, // EĞER ELİNİZDE KPS DEN GELEN KİMLİK DATALARI VARSA ALTTAKİ KODU AKTİF EDİP BU SATIRI SİLEBİLİRSİNİZ.
//                kpsData: SDKKpsData(birthDate: "890103", validDate: "300303", serialNo: "B25F24190"),
            identCardType: [.idCard, .passport, .oldSchool], // destekleyeceğiniz kart tipleri
            signLangSupport: false, // işitme engelliler için müşteri temsilcisi desteği
            nfcMaxErrorCount: 3,
            logLevel: .all,
            bigCustomerCam: true,
            selectedModules: [],
            turnKey: ""
        ) { socketStats, apiResp, webErr in
                
            print("socket resp : \(socketStats)")
            if let err = webErr, err.errorMessages != "" { // web servisten hata gelirse
                self.showToast(type:. fail, title: self.translate(text: .coreError), subTitle: err.errorMessages, attachTo: self.view) {
                    self.hideLoader()
                }
            } else { // hata yoksa işlemlere devam ediyoruz
                if socketStats?.isConnected == true {
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
}

extension SDKLoginViewController: SDKSocketListener {
    
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

extension SDKLoginViewController { // Dil seçme & değiştirme işlemleri
    
    
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
        actionSheetController.addAction(firstAction)
        actionSheetController.addAction(secondAct)
        actionSheetController.addAction(thirdAct)
        
        actionSheetController.popoverPresentationController?.sourceView = self.view
        present(actionSheetController, animated: true)
    }
    
    
}

struct SelectedServerSettings {
    
    var apiUrl, turnUrl, stunUrl, turnUser, turnPassword, websocketUrl, envTitle: String
    
    init() {
        self.apiUrl = ""
        self.turnUrl = ""
        self.stunUrl = ""
        self.turnUser = ""
        self.turnPassword = ""
        self.websocketUrl = ""
        self.envTitle = ""
    }
    
    init(apiUrl: String, turnUrl: String, stunUrl: String, turnUser: String, turnPassword: String, websocketUrl: String, envTitle: String) {
        self.apiUrl = apiUrl
        self.turnUrl = turnUrl
        self.stunUrl = stunUrl
        self.turnUser = turnUser
        self.turnPassword = turnPassword
        self.websocketUrl = websocketUrl
        self.envTitle = envTitle
    }
    
}
