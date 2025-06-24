//
//  BaseViewController.swift
//  NewTest
//
//  Created by Emir Beytekin on 25.10.2022.
//

import Foundation
import UIKit
import IdentifySDK
import Toast

class SDKViewOptionsController: UIViewController {
    
    let manager = IdentifyManager.shared
    let languageManager = SDKLangManager.shared
    var onTap: VoidHandler?
    public typealias VoidHandler = () -> Void
    var isExternalScreen = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad: \(self)")
        self.addSkipModuleButton()
        if !(self is SDKIdentifyLoginViewController) && !(self is SDKCallScreenViewController) {
            self.addQuitButton()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addBackPhoto(view: self.view)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        addBackPhoto(view: self.view)
    }
    
    func addSkipModuleButton() {
        var buttons = navigationItem.rightBarButtonItems ?? []
        let skipButton = UIBarButtonItem(title: "Skip Module", style: .plain, target: self, action: #selector(skipModuleAct))
        buttons.append(skipButton)
        navigationItem.rightBarButtonItems = buttons
    }

    func addQuitButton() {
        var buttons = navigationItem.rightBarButtonItems ?? []
        let quitButton = UIBarButtonItem(title: "Quit SDK", style: .plain, target: self, action: #selector(quitSDKAction))
        buttons.append(quitButton)
        navigationItem.rightBarButtonItems = buttons
    }
    
    @objc func skipModuleAct() {
        self.manager.skipModule()
        self.manager.getNextModule { nextMod in
            self.navigationController?.pushViewController(nextMod, animated: true)
        }
    }
    
    @objc func quitSDKAction() {
        let alert = UIAlertController(title: "Uyarı", message: "SDK Kapatılacak, onaylıyor musunuz ?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Hayır", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Evet", style: .destructive, handler: { [weak self] _ in
            guard let self = self else { return }
            self.manager.killSDKByUser { [weak self] resp in
                guard let self = self else { return }
                if resp { // eğer websockete kapatma isteğine dair haber gittiyse
                    self.dismiss(animated: true)
                } else {
                    print("")
                }
            }
        }))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    
    func listenToSocketConnection(callCompleted: Bool) {
        if callCompleted {
            self.manager.kycIsCompleted = true
        }
        guard let socket = self.manager.socket else { return }
        if socket.isConnected == false && manager.kycIsCompleted == false && self.manager.isAlreadyShowingReConnectScreen == false {
            self.openSocketDisconnect(callCompleted: callCompleted)
        } else {
            socket.onDisconnect = { [weak self] errMsg in
                guard let self = self else { return }
                if !self.manager.kycIsCompleted {
                    self.openSocketDisconnect(callCompleted: callCompleted)
                }
            }
        }
    }
    
    func openSocketDisconnect(callCompleted: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            if !self.manager.kycIsCompleted { // eğer kyc işlemleri bitmediyse
                if callCompleted == false && self.manager.isAlreadyShowingReConnectScreen == false {
                    let nextVC = SDKListenSocketViewController()
                    nextVC.delegate = self
                    self.manager.isAlreadyShowingReConnectScreen = true
                    nextVC.modalPresentationStyle = .fullScreen
                    nextVC.modalTransitionStyle = .crossDissolve
                    let controller = UIApplication.topViewController()
                    DispatchQueue.main.async {
                        controller?.present(nextVC, animated: true)
                    }
                }
            }
        })
    }
    
    func addBackPhoto(view: UIView) {
        let backImg = UIImage.init(named: "bgGradient")
        let imgView = UIImageView(image: backImg)
        imgView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        self.view.insertSubview(imgView, at: 0)
        self.addLogoToNavBar()
    }
    
    func addLogoToNavBar() {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 38, height: 38))
        imageView.contentMode = .scaleAspectFit
        let image = UIImage(named: "idCard")
        imageView.image = image
        
        imageView.isUserInteractionEnabled = true // Kullanıcının dokunmayı algılaması için gerekli
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openSocketLogs))
        tapGesture.numberOfTapsRequired = 2 // İki kez dokunmayı belirliyoruz
        imageView.addGestureRecognizer(tapGesture)
        
        navigationItem.titleView = imageView
    }
    
    @objc  func openSocketLogs() {
//        self.closeSDK()
        self.dismiss(animated: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                let socketLogVC = SDKSocketLogsViewController()
                self.present(socketLogVC, animated: true)
            })
        }
    }
    
    func addGradientBackground(view: UIView) {
        let colorManager = SDKColorManager.shared
        colorManager.backgroundGradient.frame = view.bounds
        colorManager.backgroundGradient.bounds = view.bounds.insetBy(dx: -0.5*view.bounds.size.width, dy: -0.5*view.bounds.size.height)
        colorManager.backgroundGradient.position = view.center
        view.layer.insertSublayer(colorManager.backgroundGradient, at: 0)
    }
    
    func showToast(type: ToastType? = .success, title: String, subTitle: String? = "", attachTo: UIView?, delay: Double? = 0.0, callback: @escaping() -> (Void)) {
        let successImg = UIImage.init(systemName: "checkmark.seal.fill")
        let failImg = UIImage.init(systemName: "xmark.seal.fill")
        var currentImg = UIImage()
        var conf = ToastConfiguration(autoHide: true, attachTo: attachTo)
        let successConf = ToastConfiguration(autoHide: true)
        let failConf = ToastConfiguration(autoHide: true, displayTime: 5)
        var hapticType: UINotificationFeedbackGenerator.FeedbackType

        var toast = Toast.default(
            image: currentImg,
            title: "Identify",
            subtitle: "SDK"
        )
        
        switch type {
            case .success:
                currentImg = successImg!
                conf = successConf
                hapticType = .success
            case .fail:
                currentImg = failImg!
                conf = failConf
                hapticType = .error
            default:
                return
        }
        
        if let haveSub = subTitle, subTitle != "" {
            toast = Toast.default(
                image: currentImg,
                title: title,
                subtitle: haveSub,
                configuration: conf
            )
        } else {
            toast = Toast.default(
                image: currentImg,
                title: title,
                configuration: conf
            )
        }
        DispatchQueue.main.async {
            toast.show(haptic: hapticType, after: delay!)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            callback()
        })
    }
    
    func translate(text: SDKKeywords) -> String {
        return languageManager.translate(key: text)
    }
    
    func closeSDK() {
        self.manager.quitSDK { cominVC in
            if cominVC.self == self.manager.thankYouViewController {
                let x = SDKThankYouViewController()
                x.completeStatus = .notCompleted
                self.navigationController?.pushViewController(x, animated: true)
            }
        }
    }
}


class SDKBaseViewController: SDKViewOptionsController {
    
    let nc = NotificationCenter.default

    override func viewDidLoad() {
        super.viewDidLoad()
        self.manager.trackingDelegate = self
        nc.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        nc.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        nc.addObserver(self, selector: #selector(reActiveScreen), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc func reActiveScreen() { // wi-fi' dan lte' ye çekme gibi durumlarda socket kopması yaşanabilir, buna önlem olarak koptuğu zaman yeniden bağlan ekranı basıyoruz.
        guard let socket = manager.socket else { return }
        if socket.isConnected == false && self.manager.isAlreadyShowingReConnectScreen == false {
            self.openSocketDisconnect(callCompleted: false)
        }
    }
    
    @objc func appMovedToBackground() { }

    @objc func appMovedToForeground() {
        if let socket = manager.socket {
            if socket.isConnected == false  && self.manager.isAlreadyShowingReConnectScreen == false {
                self.listenToSocketConnection(callCompleted: false)
            }
        }
    }
    
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
//        self.navigationItem.hidesBackButton = true // geri tuşu buradan engelleyebiliriz
        if isExternalScreen == false {
            if parent == nil {
                self.manager.moduleStepOrder -= 1
            } else {
                self.manager.moduleStepOrder += 1
            }
        }
    }
    
    func oneButtonAlertShow(appName: String? = "Identify", message: String, title1: String,  act1: @escaping () -> ()) {
        var topController: UIViewController? = UIApplication.shared.keyWindow?.rootViewController
        while ((topController?.presentedViewController) != nil) {
            topController = topController?.presentedViewController
        }
        let alert = UIAlertController(title: appName, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: title1, style: .default, handler: { [weak self] alert in
            guard let self = self else { return }
            act1()
        }))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            self.topMostController().present(alert, animated: true, completion: nil)
        })
        
    }
    
    func topMostController() -> UIViewController {
        var topController: UIViewController? = UIApplication.shared.keyWindow?.rootViewController
        while ((topController?.presentedViewController) != nil) {
            topController = topController?.presentedViewController
        }
        return topController!
    }
   
    
}
extension SDKBaseViewController: IdentifyTrackingListener {
    func eventReceived(event: TrackingEvent) {
        print("\(event.eventType) - \(event.time)")
    }
    
}

var vSpinner : UIView?


extension UIViewController {
    
    func showLoader(with msg: String? = "") {
        let spinnerView = UIView.init(frame: self.view.frame)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView.init(style: .large)
        ai.startAnimating()
        ai.center = spinnerView.center
        
        if let loadMsg = msg {
            let label = UILabel(frame: CGRect(x: 0, y: ai.frame.maxY + 10, width: spinnerView.frame.width, height: 30))
            label.text = msg
            label.textAlignment = .center
            label.textColor = .white
            DispatchQueue.main.async {
                spinnerView.addSubview(label)
            }
        }
        
        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            self.view.addSubview(spinnerView)
        }
        
        vSpinner = spinnerView
    }
    
    func hideLoader() {
        DispatchQueue.main.async {
            vSpinner?.removeFromSuperview()
            vSpinner = nil
        }
    }
}

public enum ToastType: String {
    case success
    case fail
}

extension SDKViewOptionsController: SDKNoConnectionDelegate {
    
    func reconnectCompleted() { // bağlantı koptu, no internet ekranı geldi, sonra bağlantı yeniden kurulduysa
        self.manager.isAlreadyShowingReConnectScreen = false // üst üste ekran açmasını engellemek için ekledik
    }
    
    
}
