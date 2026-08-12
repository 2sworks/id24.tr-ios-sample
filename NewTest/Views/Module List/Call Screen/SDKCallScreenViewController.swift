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

    /// Temsilci tarafının görüşmeyi **normal** kapattığını bildiren `terminateReason` değerleri.
    ///
    /// Android istemcisiyle aynı kümedir (`callProcessFinished` dalı): hata ekranı gösterilmez,
    /// oturum biter ve sonuç panelin statüsüne göre yazılır.
    static let agentClosedNormallyReasons: Set<String> = [
        "NORMAL_CLOSE_BY_AGENT",
        "AGENT_SOCKET_NETWORK_PROBLEM",
        "AGENT_FORCE_DISCONNECT_FOR_AUTO_CLOSE"
    ]

    /// Temsilci tarafında **sorun** oluştuğunu bildiren `terminateReason` değerleri.
    ///
    /// Android istemcisiyle aynı kümedir (`closeSocket` → "sorun oluştu" dalı). Buradaki
    /// karşılığı yeniden bağlanma ekranıdır: oturum karara bağlanmaz, kullanıcı bekleme
    /// odasına dönebilir.
    ///
    /// ⚠️ `ADMIN_DISCONNECTED_TURN` panelden gelir; SDK'nın kendi ürettiği `TURN_DISCONNECTED`
    /// (medya hattı düşmesi) ile aynı şey DEĞİLDİR.
    ///
    /// ⚠️ Android'de bu değerin enum adı `UNKNOWN`, tel üzerindeki karşılığı ise `UNKNOW`'dur
    /// (`UNKNOWN("UNKNOW")`). Sunucunun hangisini gönderdiği sürüme göre değişebileceği için
    /// ikisi de kabul edilir; `UNKNOW` yazımı hatalı görünse de doğrudur, düzeltilmemelidir.
    static let agentClosedWithProblemReasons: Set<String> = [
        "ADMIN_DISCONNECTED_TURN",
        "UNKNOW",
        "UNKNOWN"
    ]
    /// Çalma ekranı yalnızca "kabul et" ile kapandığından, çağrı yanıtlanmadan sonlanırsa
    /// (RINGING_TIMEOUT, terminateCall, imOffline) ekranda asılı kalmasın diye tutuluyor.
    private weak var ringVC: SDKRingViewController?
    
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
        self.manager.replayPendingQueueStats()
        navigationItem.rightBarButtonItem = nil
        self.navigationItem.hidesBackButton = true
        setupLiveness()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // ⚠️ Üstümüze bir modal açıldığında da bu metot çalışır (ör. yeniden bağlanma
        // ekranı .fullScreen present ediliyor). Görüşme sırasında panele giden video
        // ARKit karelerinden besleniyor (`startLiveness()` → `switchToARKitCapture()`),
        // dolayısıyla burada koşulsuz `stopLiveness()` çağırmak kare kaynağını tamamen
        // kesiyordu: panelde görüntü gidiyor, ses akmaya devam ediyordu.
        // Yalnızca ekrandan gerçekten ayrılırken durdur; görüşmenin bittiği her akış
        // (endCall / terminate / imOffline / missedCall) zaten stopLiveness çağırıyor.
        guard isMovingFromParent || isBeingDismissed else {
            print("callScreen: üste modal açıldı, ARKit/kamera akışı sürdürülüyor")
            return
        }

        self.confStarted = false
        stopLiveness()
    }
    
    
    private func applyQueueLabel(order: String, min: String) {
        if order == "0" || min == "0" {
            self.timeInfoLbl.text = self.translate(text: .callScreenWaitRepresentative)
        } else {
            self.timeInfoLbl.text = "\(self.translate(text: .waitingDesc1Live))\(order)\(self.translate(text: .waitingDesc2Live))\(min)\(self.translate(text: .waitingDesc3Live))"
        }
    }

    private func setupUI() {
        UIApplication.shared.isIdleTimerDisabled = true // görüşürken veya beklerken ekran kapanmaması için
        self.waitDesc1.text = self.translate(text: .waitingDesc1)
        self.waitDesc2.text = self.translate(text: .waitingDesc2)
        self.smsLblDesc.text = self.translate(text: .enterSmsCode)
        self.plsWaitLbl.text = self.translate(text: .corePlsWait)
        self.timeInfoLbl.text = self.translate(text: .callScreenCheckingAvailability)
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
        setupCameras()
        startLiveness()
    }
    
    /// Çağrı yanıtlanmadan sonlandıysa çalma ekranını kapatır; aksi halde
    /// yeniden bağlan penceresi çalma ekranının üstünde açılır ve altta o ekran asılı kalır.
    private func dismissRingScreenIfNeeded() {
        guard let ringVC = ringVC else { return }
        self.ringVC = nil
        DispatchQueue.main.async {
            ringVC.dismiss(animated: true)
        }
    }

    private func callIsDone(doneStatus: CallStatus) {
        stopLiveness()
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
        stopLiveness()
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
    
    override func reconnectCompletedWithStatus(isWaitingRoom: Bool, statusType: String?) {
        if isWaitingRoom {
            print("reconnect: Waiting Room'a dönülüyor")
            stopLiveness()
            DispatchQueue.main.async {
                self.setupCallScreen(inCall: false)
            }
        } else {
            print("reconnect: Thank You Page açılıyor, statusType: \(statusType ?? "-")")
            DispatchQueue.main.async {
                self.callIsDone(doneStatus: statusType == "positive" ? .completed : .notCompleted)
            }
        }
    }
    
}

extension SDKCallScreenViewController: CallScreenDelegate {
    
    func acceptCall() { // temsilciden gelen  çağrı kabul edilince bu fonksiyon çalışır
        // Çalma ekranı kendini kapattı: referans burada bırakılmazsa sonraki çağrının
        // çalma ekranı "zaten açık" sanılıp hiç gösterilmez.
        self.ringVC = nil
        manager.acceptCall { connected, errMsg, sdpConnOk in
            if let _ = connected, !connected! {
                self.showToast(title: self.translate(text: .coreError), subTitle: errMsg?.errorMessages ?? "", attachTo: self.view) {
                    return
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
            if manager.hideCallAnswerScreen {
                self.acceptCall()
            } else {
                // Ekranda zaten bir çalma ekranı varsa üstüne ikincisi açılmaz.
                guard ringVC == nil else {
                    print("çalma ekranı zaten açık, yeni çağrı bildirimi yok sayıldı")
                    return
                }
                let nextVC = SDKRingViewController()
                nextVC.delegate = self
                self.ringVC = nextVC
                self.present(nextVC, animated: true)
            }
        case .comingSms:
            self.openSMS()
            print("sms geliyor")
        case .endCall:
            stopLiveness()
            self.listenToSocketConnection(callCompleted: true)
            // 4106 — sunucu logunda kapanışın sebebi "görüşme tamamlandı" olarak görünür.
            manager.disconnectSocket(reason: .callCompleted)
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
            dismissRingScreenIfNeeded()

            if terminateReason == "TURN_DISCONNECTED" {
                // NOT: Bu değeri SDK'nın KENDİSİ üretir (medya hattı düştüğünde). Panelden
                // gelen `ADMIN_DISCONNECTED_TURN` ile karıştırılmamalıdır.
                reconnect()
            } else if Self.agentClosedNormallyReasons.contains(terminateReason ?? "") {
                // Temsilci tarafı görüşmeyi NORMAL kapattı (Android'deki `callProcessFinished`
                // dalı): hata ekranı gösterilmez, oturum biter ve sonuç panelin statüsüne
                // göre yazılır. Tek istisna, temsilcinin hiç durum seçmemiş olmasıdır.
                if manager.lastStatusSummary?.id == -3 {
                    print("terminateCall: normal kapanış ama temsilci durum seçmemiş (id -3), bekleme odasına dönülüyor")
                    reconnect()
                } else {
                    self.listenToSocketConnection(callCompleted: true)
                    self.setupCallScreen(inCall: false)
                    self.callIsDone(doneStatus: statusSummaryType == "positive" ? .completed : .notCompleted)
                    isTerminating = false
                }
            } else if Self.agentClosedWithProblemReasons.contains(terminateReason ?? "") {
                // Temsilci tarafında sorun oluştu (Android'deki `closeSocket` dalı): oturum
                // karara bağlanmaz, kullanıcı bekleme odasına dönebilir.
                print("terminateCall: panel görüşmeyi sorunlu kapattı (\(terminateReason ?? "-")), yeniden bağlanma ekranı açılıyor")
                reconnect()
            } else if terminateReason == "CLIENT_IS_DISCONNECTED" {
                if manager.socket.isConnected {
                    isTerminating = false
                } else {
                    reconnect()
                }
            } else {

                let hasStatus: Bool = {
                    guard let type = statusSummaryType else { return false }
                    // id == -3 → "Durum Seçilmedi": temsilci henüz karar vermemiştir.
                    // Bunu karar sayarsak `positive` olmadığı için müşteriye "doğrulama
                    // başarısız" ekranı çıkıyor; oysa oturum kararsız kapanmıştır.
                    guard manager.lastStatusSummary?.id != -3 else {
                        print("terminateCall: temsilci durum seçmemiş (id -3), karar sayılmıyor")
                        return false
                    }
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
                // Kapanış sebebi sunucu logunda ayrışsın: PING zaman aşımı 4107,
                // yanıtlanmayan çağrı 4108, diğer tüm yeniden bağlanma döngüleri 4104.
                let closeCode: SDKSocketCloseCode
                switch terminateReason {
                case "PING_TIMEOUT":    closeCode = .pingTimeout
                case "RINGING_TIMEOUT": closeCode = .ringingTimeout
                default:                closeCode = .reconnectCycle
                }
                manager.disconnectSocket(reason: closeCode)
                // Görüşme burada bitiyor: ARKit oturumunu bilinçli olarak kapat (kamerayı
                // serbest bırakır). Yeniden bağlanma başarılı olursa yeni çağrıda
                // `start2SideTransfer()` → `startLiveness()` ile tekrar başlar.
                confStarted = false
                stopLiveness()
                setupCallScreen(inCall: false) // bekleme ekranı görüntüsünü aktif eder
                openSocketDisconnect(callCompleted: false) // bağlantı koptuğuna dair disconnect penceresini present eder
                isTerminating = false
                return
            }
            
            
        case .imOffline:
            print("bağlantı kopartıldı - panelde sayfa yenilendi - browser kapatıldı")
            confStarted = false
            dismissRingScreenIfNeeded()
            stopLiveness()
            setupCallScreen(inCall: false)
        case .updateQueue(let order, let min):
            applyQueueLabel(order: order, min: min)
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
            DispatchQueue.main.async { [weak self] in self?.start2SideTransfer() }
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
            stopLiveness()
            self.listenToSocketConnection(callCompleted: true)
            setupCallScreen(inCall: false)
            self.dismiss(animated: true) {
                self.callIsDone(doneStatus: .missedCall)
            }
            
        case .connectionErr:  // socket kopması durumunda tetiklenir
            // Sinyal koptu: ARKit oturumunu bilinçli kapat. (SDK tarafında yerel medya
            // gönderimi zaten susturuluyor; burada kamera da serbest bırakılıyor.)
            confStarted = false
            // Kopmayla birlikte çağrı da düştü: açık kalan çalma ekranı kapatılır. Aksi halde
            // yeniden bağlanma ekranının altında asılı kalıyor ve reconnect sonrası ortaya
            // çıkıp kullanıcıya artık var olmayan bir çağrıyı yanıtlatıyordu.
            dismissRingScreenIfNeeded()
            stopLiveness()
            setupCallScreen(inCall: false) // bekleme ekranı görüntüsünü aktif eder
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
