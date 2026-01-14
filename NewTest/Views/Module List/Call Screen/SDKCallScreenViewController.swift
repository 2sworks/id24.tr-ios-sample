//
//  SDKCallScreenViewController.swift
//  NewTest
//
//  Created by Emir Beytekin on 15.11.2022.
//

import UIKit
import IdentifySDK
import CHIOTPField

protocol CallScreenDelegate: AnyObject {
    func acceptCall()
}

class SDKCallScreenViewController: SDKBaseViewController {
    
    @IBOutlet weak var plsWaitLbl: UILabel!
    @IBOutlet weak var smsLblDesc: UILabel!
    @IBOutlet weak var waitDesc1: UILabel!
    @IBOutlet weak var waitDesc2: UILabel!
    @IBOutlet weak var codeTxt: UITextField!
    @IBOutlet weak var waitScreen: UIView!
    @IBOutlet weak var customerCam: UIView!
    @IBOutlet weak var myCam: UIView!
    @IBOutlet weak var callScreen: UIView!
    @IBOutlet weak var qualityImg: UIImageView! // bağlantı kalitesi imajı
    @IBOutlet weak var smsStackView: UIView!
    @IBOutlet weak var timeInfoLbl: UILabel!
    @IBOutlet weak var endCallButton: UIButton!
    private var confStarted = false // ilk kez bağlantı kurulma - temsilci ve kişinin kamerasını bu değişkene göre aktif eder
    var checkedSignLang = false
    var isTerminating = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isTerminating = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if manager.connectToSignLang {
            if !checkedSignLang {
                self.checkSignLang()
                return
            }
        }
        
        checkCameraAndMicPermission()
        self.setupUI()
        setupCallScreen(inCall: false)
        self.manager.socketMessageListener = self
        navigationItem.rightBarButtonItem = nil
        self.navigationItem.hidesBackButton = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.confStarted = false
    }
    
    private func setupUI() {
        UIApplication.shared.isIdleTimerDisabled = true // görüşürken veya beklerken ekran kapanmaması için
        self.waitDesc1.text = self.translate(text: .waitingDesc1)
        self.waitDesc2.text = self.translate(text: .waitingDesc2)
        self.smsLblDesc.text = self.translate(text: .enterSmsCode)
        self.plsWaitLbl.text = self.translate(text: .corePlsWait)
        self.endCallButton.isUserInteractionEnabled = true
        self.endCallButton.isEnabled = true
        self.endCallButton.alpha = 1.0
    }
    
    private func checkSignLang() {
        let signVC = SDKSignLangViewController()
        signVC.delegate = self
        self.navigationController?.pushViewController(signVC, animated: false)
    }
    
    private func setupCallScreen(inCall: Bool) { // bekleme ekranı veya aktif görüşme ekranı arasındaki geçişi sağlar
        DispatchQueue.main.async {
            self.waitScreen.isHidden = inCall
            self.callScreen.isHidden = !inCall
            if inCall {
                self.navigationController?.setNavigationBarHidden(true, animated: true)
            } else {
                self.navigationController?.setNavigationBarHidden(false, animated: true)
            }
        }
    }
    
    private func setupCameras() {
        let remoteVideoView = manager.webRTCClient.remoteVideoView()
        let localVideoView = manager.webRTCClient.localVideoView()
        if self.manager.showBigCustomerCam {
            if self.manager.agentViewScale == 1 {
                manager.webRTCClient.setupRemoteViewFrame(frame: CGRect(x: 0, y: 0, width: self.myCam.frame.width, height: self.myCam.frame.height * 2))
            } else {
                manager.webRTCClient.setupRemoteViewFrame(frame: CGRect(x: 0, y: 0, width: self.myCam.frame.width * 2, height: self.myCam.frame.height))
            }
            remoteVideoView.contentMode = .scaleAspectFill
            manager.webRTCClient.setupLocalViewFrame(frame: CGRect(x: 0, y: 0, width: self.customerCam.frame.width, height: self.customerCam.frame.height))
            remoteVideoView.center = CGPoint(x: myCam.frame.size.width  / 2, y: myCam.frame.size.height / 2)
            customerCam.clipsToBounds = true
            self.myCam.addSubview(remoteVideoView)
            self.customerCam.addSubview(localVideoView)
            manager.webRTCClient.calculateLocalSize()
            manager.webRTCClient.calculateRemoteSize()
        } else {
            manager.webRTCClient.setupRemoteViewFrame(frame: CGRect(x: 0, y: 0, width:self.manager.remoteCam().frame.width * 2, height: self.manager.remoteCam().frame.height))
            customerCam.clipsToBounds = true
            manager.webRTCClient.setupLocalViewFrame(frame: CGRect(x: 0, y: 0, width: self.myCam.frame.width, height: self.myCam.frame.height))
            remoteVideoView.center = CGPoint(x: customerCam.frame.size.width  / 2, y: customerCam.frame.size.height / 2)
            remoteVideoView.contentMode = .scaleAspectFill
            self.myCam.addSubview(localVideoView)
            self.customerCam.addSubview(remoteVideoView)
            manager.webRTCClient.calculateLocalSize()
            manager.webRTCClient.calculateRemoteSize()
        }
        self.myCam.backgroundColor = IdentifyTheme.blackBack
        self.customerCam.backgroundColor = IdentifyTheme.blackBack
        customerCam.roundCorners(corners: .allCorners, radius: 12)
        self.setupCallScreen(inCall: true)
    }
    
    private func start2SideTransfer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: {
            self.setupCameras()
            self.hideLoader()
        })
    }
    
    private func callIsDone(doneStatus: CallStatus) {
        self.manager.forceQuitSDK()
        let x  = SDKThankYouViewController()
        x.completeStatus = doneStatus
        self.navigationController?.pushViewController(x, animated: true)
    }
    
    @IBAction func endCallAct(_ sender: UIButton) {
        let alert = UIAlertController(title: "Uyarı", message: "Görüşmeyi kapatırsanız tüm işlemler iptal edilecektir, onaylıyor musunuz?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Hayır", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Evet", style: .destructive, handler: { [weak self] _ in
            self?.closeByUser()
        }))
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func closeByUser() {
        self.manager.terminateCallByUser { resp in
            if resp {
                let x = SDKThankYouViewController()
                x.completeStatus = .notCompleted
                if let nav = self.navigationController {
                    nav.pushViewController(x, animated: true)
                }
            }
        }
    }
    
}

extension SDKCallScreenViewController: CallScreenDelegate {
    
    func acceptCall() { // temsilciden gelen  çağrı kabul edilince bu fonksiyon çalışır
        manager.acceptCall { connected, errMsg, sdpConnOk in
            if let _ = connected, !connected! {
                self.showToast(title: self.translate(text: .coreError), subTitle: errMsg?.errorMessages ?? "", attachTo: self.view) {
                    return
                }
            } else {
                if sdpConnOk! { // sdp bağlantısı kuruldu
                    DispatchQueue.main.async {
                        self.showLoader()
                    }
                }
            }
        }
    }
}

extension SDKCallScreenViewController: SDKSocketListener {
    
    func listenSocketMessage(message: SDKCallActions) {
        
        guard !isTerminating else {
            print("terminateCall: zaten bitiyor, bekliyoruz...")
            return
        }
        
        switch message {
        case .incomingCall:
            print("yeni bir çağrı geliyor")
            let nextVC = SDKRingViewController()
            nextVC.delegate = self
            self.present(nextVC, animated:true)
        case .comingSms:
            self.openSMS()
            print("sms geliyor")
        case .endCall:
            manager.socket.disconnect()
            print("görüşme tamamlandı, sonraki modüle geçebiliriz")
            
        case .approveSms(let tanCode):
            print("sms onaylandı :\(tanCode)")
        case .openWarningCircle:
            print("surat çerçevesi açıldı")
        case .closeWarningCircle:
            print("surat çerçevesi kapatıldı")
        case .openCardCircle:
            print("kart çerçevesi açıldı")
        case .closeCardCircle:
            print("kart çerçevesi kapatıldı")
        case .terminateCall(let terminateReason, let statusSummaryType):
            
            print("terminateCall: (terminateReason=\(terminateReason ?? "-"), statusSummaryType=\(statusSummaryType ?? "-"))")
            
            isTerminating = true
            
            if terminateReason == "TURN_DISCONNECTED" {
                reconnect()
            } else {
                
                let hasStatus: Bool = {
                    guard let type = statusSummaryType else { return false }
                    return type == "positive" || type == "negative" || type == "neutral"
                }()
                
                if hasStatus {
                    
                    self.listenToSocketConnection(callCompleted: true)
                    self.setupCallScreen(inCall: false)
                    self.callIsDone(doneStatus: statusSummaryType == "positive" ? .completed : .notCompleted)
                    isTerminating = false
                    return
                    
                } else {
                    reconnect()
                }
                
            }
            
            func reconnect() {
                manager.socket.disconnect()
                setupCallScreen(inCall: false) // kameraları kapatıp bekleme ekranı görüntüsünü aktif eder
                openSocketDisconnect(callCompleted: false) // bağlantı koptuğuna dair disconnect penceresini present eder
                isTerminating = false
                return
            }
            
            
        case .imOffline:
            print("bağlantı kopartıldı - panelde sayfa yenilendi - browser kapatıldı")
            confStarted = false
            setupCallScreen(inCall: false)
        case .updateQueue(let order, let min):
            
            if order == "0" || min == "0" {
                print("🔔 [QUEUE] Sıra bilgisi yok veya geçersiz, default text gösteriliyor")
                self.timeInfoLbl.text = self.translate(text: .callScreenWaitRepresentative)
            } else {
                self.timeInfoLbl.text = "\(self.translate(text: .waitingDesc1Live))\(order)\(self.translate(text: .waitingDesc2Live))\(min)\(self.translate(text: .waitingDesc3Live))"
            }
        case .photoTaken(let msg):
            print("temsilci ekran fotoğrafı çekti \(msg)")
            self.showToast(title: msg, subTitle: "", attachTo: self.view) {
                return
            }
        case .subrejectedDismiss:
            print("aynı odada başka kişi var")
        case .subscribed:
            print("odaya katılım sağlandı")
        case .openNfcRemote(let birthDate, let validDate, let serialNo):
            manager.startRemoteNFC(birthDate: birthDate, validDate: validDate, docNo: serialNo)
            print("uzaktan nfc başlatıldı")
            
        case .editNfcProcess:
            print("kullanıcıya mrz datalarını düzeltme ekranı açıyoruz")
            let editVC = SDKNfcViewController()
            editVC.showOnlyEditScreen = true
            self.present(editVC, animated: true)
            
        case .startTransfer:
            self.showToast(title: "Kameranız ayarlanıyor, lütfen bekleyin", attachTo: self.view) {
                self.start2SideTransfer()
                return
            }
            print("yüz yüze görüşme başlıyor")
        case .disableEndCallButton:
            if topMostController().isKind(of: UIAlertController.self) {
                self.dismiss(animated: false)
            }
            self.endCallButton.isUserInteractionEnabled = false
            self.endCallButton.isEnabled = false
            self.endCallButton.alpha = 0.3
            print("bitirme butonu kapatıldı")
        case .networkQuality(let quality):
            print("bağlantı kalitesine göre sinyal resmi basılıyor")
            switch quality {
            case "bad":
                DispatchQueue.main.async {
                    self.qualityImg.image = UIImage(named: "badConn")
                }
            case "medium":
                DispatchQueue.main.async {
                    self.qualityImg.image = UIImage(named: "mediumConn")
                }
            case "good":
                DispatchQueue.main.async {
                    self.qualityImg.image = UIImage(named: "goodConn")
                }
            default:
                DispatchQueue.main.async {
                    self.qualityImg.image = UIImage()
                }
            }
        case .missedCall: // belirli süre boyunca telefon çaldı fakat müşteri açmadı veya temsilci aradı fakat telefon açılmadan aramayı sonlandırdı
            self.listenToSocketConnection(callCompleted: true)
            setupCallScreen(inCall: false)
            self.dismiss(animated: true) {
                self.callIsDone(doneStatus: .missedCall)
            }
            
        case .connectionErr:  // socket kopması durumunda tetiklenir
            setupCallScreen(inCall: false) // kameraları kapatıp bekleme ekranı görüntüsünü aktif eder
            openSocketDisconnect(callCompleted: false) // bağlantı koptuğuna dair disconnect penceresini present eder
        case .wrongSocketActionErr(_):
            break
        @unknown default:
            return
        }
    }
}


extension SDKCallScreenViewController {
    
    func openSMS() {
        codeTxt.becomeFirstResponder()
        codeTxt.delegate = self
        codeTxt.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        self.smsStackView.isHidden = false
    }
    
    func resetSMSInput(endEditing:Bool? = false) {
        DispatchQueue.main.async {
            if endEditing! {
                self.view.endEditing(true)
            } else {
                self.codeTxt.becomeFirstResponder()
            }
            self.codeTxt.text = .none
            self.codeTxt.text = String(repeating: " ", count: 6)
            self.codeTxt.text = ""
        }
    }
    
}

extension SDKCallScreenViewController: UITextFieldDelegate {
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if textField.text?.count == 6 {
            showLoader()
            manager.smsVerification(tan: codeTxt.text!) { resp in
                self.hideLoader()
                self.smsStackView.isHidden = resp
                if resp == false {
                    self.showToast(title: self.translate(text: .coreError), subTitle: self.translate(text: .wrongSMSCode), attachTo: self.view) {
                        self.resetSMSInput(endEditing:false)
                    }
                } else {
                    self.resetSMSInput(endEditing: true)
                }
            }
        }
    }
    
}

extension SDKCallScreenViewController: SDKSignLangViewControllerDelegate {
    func sdkSignLangViewControllerDidFinish(_ controller: SDKSignLangViewController) {
        checkedSignLang = true
    }
}

extension UIView {
    
    // Using a function since `var image` might conflict with an existing variable
    // (like on `UIImageView`)
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}
