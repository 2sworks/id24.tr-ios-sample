//
//  NFX.swift
//  netfox
//
//  Copyright © 2016 netfox. All rights reserved.
//

import Foundation
#if os(OSX)
import Cocoa
#else
import UIKit
#endif

private func podPlistVersion() -> String? {
    guard let path = Bundle(identifier: "com.kasketis.netfox-iOS")?.infoDictionary?["CFBundleShortVersionString"] as? String else { return nil }
    return path
}

// TODO: Carthage support
let nfxVersion = podPlistVersion() ?? "0"

@objc
open class NFX: NSObject {
    
    // MARK: - Properties
    #if os(OSX)
        var windowController: NFXWindowController?
        let mainMenu: NSMenu? = NSApp.mainMenu?.items[1].submenu
        var nfxMenuItem: NSMenuItem = NSMenuItem(title: "netfox", action: #selector(NFX.show), keyEquivalent: String.init(describing: (character: NSF9FunctionKey, length: 1)))
    #endif
    
    #if os(iOS)
        fileprivate var presentedRootController: UIViewController?
    #endif
    
    fileprivate enum Constants: String {
        case alreadyStartedMessage = "Already started!"
        case alreadyStoppedMessage = "Already stopped!"
        case startedMessage = "Started!"
        case stoppedMessage = "Stopped!"
        case noTabsEnabledMessage = "No tabs enabled - nothing to show!"
        case nibName = "NetfoxWindow"
    }
    
    fileprivate var started: Bool = false
    fileprivate var presented: Bool = false
    /// Konsol sekmesinin gösterilip gösterilmeyeceği. `startConsoleCapture()` açar.
    fileprivate var consoleCaptureEnabled: Bool = false

    /// HTTP trafiği sekmesi. Kapalıyken URLSession kaydı hiç kurulmaz; panel ve
    /// sallama hareketi çalışmayı sürdürür. `start()`'tan önce ayarlanmalıdır.
    public var isRequestsTabEnabled: Bool = true
    /// Konsol sekmesi. Kapalıyken `startConsoleCapture()` çağrılsa da sekme çıkmaz.
    public var isConsoleTabEnabled: Bool = true
    /// Host'un bağladığı kaynağın sekmesi (ör. WebSocket). Kaynak yoksa zaten çıkmaz.
    public var isExternalTabEnabled: Bool = true
    /// Panel kapanıp açıldığında aynı sekmeye dönmek için.
    fileprivate var lastSelectedTabIndex: Int = 0
    /// Host uygulamanın bağladığı ek log kaynağı (ör. WebSocket trafiği).
    public var externalLogSource: NFXExternalLogSource?
    fileprivate var enabled: Bool = false
    fileprivate var selectedGesture: ENFXGesture = .shake
    fileprivate var ignoredURLs = [String]()
    fileprivate var ignoredURLsRegex = [NSRegularExpression]()
    fileprivate var lastVisitDate: Date = Date()
    
    internal var cacheStoragePolicy = URLCache.StoragePolicy.notAllowed
    
    // swiftSharedInstance is not accessible from ObjC
    class var swiftSharedInstance: NFX {
        struct Singleton {
            static let instance = NFX()
        }
        return Singleton.instance
    }
    
    // the sharedInstance class method can be reached from ObjC
    @objc open class func sharedInstance() -> NFX {
        return NFX.swiftSharedInstance
    }
    
    @objc public enum ENFXGesture: Int {
        case shake
        case custom
    }

    @objc open func start() {
        guard !started else {
            showMessage(Constants.alreadyStartedMessage.rawValue)
            return
        }

        started = true
        // HTTP sekmesi kapalıysa istekleri yakalayan katman hiç kurulmaz; panelin
        // geri kalanı (sallama, konsol, harici kaynak) çalışmaya devam eder.
        if isRequestsTabEnabled {
            URLSessionConfiguration.implementNetfox()
            register()
        }
        enable()
        fileStorageInit()
        showMessage(Constants.startedMessage.rawValue)
        #if os(OSX)
        addNetfoxToMainMenu()
        #endif
    }
    
    @objc open func stop() {
        guard started else {
            showMessage(Constants.alreadyStoppedMessage.rawValue)
            return
        }
        
        unregister()
        disable()
        clearOldData()
        started = false
        showMessage(Constants.stoppedMessage.rawValue)
        #if os(OSX)
        removeNetfoxFromMainmenu()
        #endif
    }
    
    /// `stdout`/`stderr` yakalamayı başlatır ve panele Console sekmesini ekler.
    ///
    /// Yakalanan satırlar orijinal tanıtıcıya geri yazılır; Xcode konsolu etkilenmez.
    /// Binary dağıtılan SDK'ların `print` çıktısı da bu yolla panele düşer.
    @objc open func startConsoleCapture() {
        guard !consoleCaptureEnabled else { return }
        consoleCaptureEnabled = true
        NFXStdoutCapture.shared.start()
    }

    /// Yakalamayı durdurur; Console sekmesi bir sonraki açılışta gösterilmez.
    @objc open func stopConsoleCapture() {
        guard consoleCaptureEnabled else { return }
        consoleCaptureEnabled = false
        NFXStdoutCapture.shared.stop()
    }

    /// Konsol sekmesine yapısal bir satır ekler.
    ///
    /// Aynı satır `stdout` üzerinden de yakalanmışsa yinelenmez; yapısal kayıt
    /// korunur. `type` sekmedeki tür süzgecinde görünür.
    @objc open func log(_ message: String, type: String = "general") {
        NFXLogStore.shared.addStructured(message: message, type: type)
    }

    fileprivate func showMessage(_ msg: String) {
        print("netfox \(nfxVersion) - [https://github.com/kasketis/netfox]: \(msg)")
    }
    
    internal func isEnabled() -> Bool {
        return enabled
    }
    
    internal func enable() {
        enabled = true
    }
    
    internal func disable() {
        enabled = false
    }
    
    fileprivate func register() {
        URLProtocol.registerClass(NFXProtocol.self)
    }
    
    fileprivate func unregister() {
        URLProtocol.unregisterClass(NFXProtocol.self)
    }
    
    @objc func motionDetected() {
        guard started else { return }
        toggleNFX()
    }
    
    @objc open func isStarted() -> Bool {
        return started
    }
    
    @objc open func setCachePolicy(_ policy: URLCache.StoragePolicy) {
        cacheStoragePolicy = policy
    }
    
    @objc open func setGesture(_ gesture: ENFXGesture) {
        selectedGesture = gesture
        #if os(OSX)
        if gesture == .shake {
            addNetfoxToMainMenu()
        } else {
            removeNetfoxFromMainmenu()
        }
        #endif
    }
    
    @objc open func show() {
        guard started else { return }
        showNFX()
    }
    
    #if os(iOS)
    @objc open func show(on rootViewController: UIViewController) {
        guard started, presented == false else { return }

        showNFX(on: rootViewController)
        presented = true
    }
    #endif
    
    @objc open func hide() {
        guard started else { return }
        hideNFX()
    }

    @objc open func toggle()
    {
        guard self.started else { return }
        toggleNFX()
    }
    
    @objc open func ignoreURL(_ url: String) {
        ignoredURLs.append(url)
    }
    
    @objc open func getSessionLog() -> Data? {
        return try? Data(contentsOf: NFXPath.sessionLogURL)
    }
    
    @objc open func ignoreURLs(_ urls: [String]) {
        ignoredURLs.append(contentsOf: urls)
    }
    
    @objc open func ignoreURLsWithRegex(_ regex: String) {
        ignoredURLsRegex.append(NSRegularExpression(regex))
    }
    
    @objc open func ignoreURLsWithRegexes(_ regexes: [String]) {
        ignoredURLsRegex.append(contentsOf: regexes.map { NSRegularExpression($0) })
    }
    
    internal func getLastVisitDate() -> Date {
        return lastVisitDate
    }
    
    fileprivate func showNFX() {
        if presented {
            return
        }
        
        showNFXFollowingPlatform()
        presented = true
    }
    
    fileprivate func hideNFX() {
        if !presented {
            return
        }
        
        hideNFXFollowingPlatform { () -> Void in
            self.presented = false
            self.lastVisitDate = Date()
        }
    }

    fileprivate func toggleNFX() {
        presented ? hideNFX() : showNFX()
    }
    
    private func fileStorageInit() {
        clearOldData()
        NFXPath.deleteOldNFXLogs()
        NFXPath.createNFXDirIfNotExist()
    }
    
    internal func clearOldData() {
        NFXHTTPModelManager.shared.clear()
        
        NFXPath.deleteNFXDir()
        NFXPath.createNFXDirIfNotExist()
    }
    
    func getIgnoredURLs() -> [String] {
        return ignoredURLs
    }
    
    func getIgnoredURLsRegexes() -> [NSRegularExpression] {
        return ignoredURLsRegex
    }
    
    func getSelectedGesture() -> ENFXGesture {
        return selectedGesture
    }
    
}

#if os(iOS)

extension NFX {
    fileprivate var presentingViewController: UIViewController? {
        var rootViewController = UIWindow.keyWindow?.rootViewController
		while let controller = rootViewController?.presentedViewController {
			rootViewController = controller
		}
        return rootViewController
    }

    fileprivate func showNFXFollowingPlatform() {
        showNFX(on: presentingViewController)
    }
    
    fileprivate func showNFX(on rootViewController: UIViewController?) {
        let tabs = buildTabs()
        // Tüm sekmeler kapatılmışsa gösterilecek bir şey yoktur.
        guard !tabs.isEmpty else {
            showMessage(Constants.noTabsEnabledMessage.rawValue)
            presented = false
            return
        }

        let tabBarController = UITabBarController()
        tabBarController.viewControllers = tabs
        tabBarController.selectedIndex = min(lastSelectedTabIndex, tabs.count - 1)
        tabBarController.delegate = self

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor.NFXStarkWhiteColor()
        tabBarController.tabBar.standardAppearance = tabAppearance
        if #available(iOS 15.0, *) {
            tabBarController.tabBar.scrollEdgeAppearance = tabAppearance
        }
        tabBarController.tabBar.tintColor = UIColor.NFXOrangeColor()

        tabBarController.modalPresentationStyle = .fullScreen
        tabBarController.presentationController?.delegate = self

        rootViewController?.present(tabBarController, animated: true, completion: nil)
        presentedRootController = tabBarController
    }

    /// Panelin sekmeleri. Network her zaman vardır; konsol yakalama açıksa Console,
    /// host bir kaynak bağladıysa onun sekmesi eklenir.
    fileprivate func buildTabs() -> [UIViewController] {
        var controllers: [UIViewController] = []

        // Sekme etiketi kök controller'ın `title` değerinden gelir; UIKit
        // navigation controller'ın başlığını tabBarItem'a yansıtır. Başlıklar bu
        // yüzden controller başlıklarıyla aynı tutulur.
        if isRequestsTabEnabled {
            let list = wrapInNavigation(NFXListController_iOS())
            list.tabBarItem = UITabBarItem(title: "Requests", image: UIImage.NFXNetworkTabIcon(), tag: 0)
            controllers.append(list)
        }

        if consoleCaptureEnabled, isConsoleTabEnabled {
            let console = wrapInNavigation(NFXConsoleController_iOS())
            console.tabBarItem = UITabBarItem(title: "Console", image: UIImage.NFXConsoleTabIcon(), tag: 1)
            controllers.append(console)
        }

        if let source = externalLogSource, isExternalTabEnabled {
            let externalController = NFXExternalLogController_iOS()
            externalController.source = source
            let external = wrapInNavigation(externalController)
            external.tabBarItem = UITabBarItem(title: source.title, image: UIImage.NFXExternalTabIcon(), tag: 2)
            controllers.append(external)
        }

        return controllers
    }

    fileprivate func wrapInNavigation(_ controller: UIViewController) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.navigationBar.isTranslucent = false
        navigationController.navigationBar.tintColor = UIColor.NFXOrangeColor()
        navigationController.navigationBar.barTintColor = UIColor.NFXStarkWhiteColor()
        navigationController.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.NFXOrangeColor()]

        let appearence = UINavigationBarAppearance()
        appearence.configureWithOpaqueBackground()
        appearence.backgroundColor = UIColor.NFXStarkWhiteColor()
        appearence.titleTextAttributes = [.foregroundColor: UIColor.black]

        navigationController.navigationBar.standardAppearance = appearence
        navigationController.navigationBar.scrollEdgeAppearance = appearence
        if #available(iOS 15.0, *) {
            navigationController.navigationBar.compactScrollEdgeAppearance = appearence
        }

        return navigationController
    }
    
    fileprivate func hideNFXFollowingPlatform(_ completion: (() -> Void)?) {
        presentedRootController?.presentingViewController?.dismiss(animated: true, completion: completion)
        presentedRootController = nil
    }
}

extension NFX: UITabBarControllerDelegate {

    public func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        lastSelectedTabIndex = tabBarController.selectedIndex
    }
}

extension NFX: UIAdaptivePresentationControllerDelegate {

    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController)
    {
        guard self.started else { return }
        self.presented = false
    }
}

#elseif os(OSX)
    
extension NFX {
    
    public func windowDidClose() {
        presented = false
    }
    
    private func setupNetfoxMenuItem() {
        nfxMenuItem.target = self
        nfxMenuItem.action = #selector(NFX.motionDetected)
        nfxMenuItem.keyEquivalent = "n"
        nfxMenuItem.keyEquivalentModifierMask = NSEvent.ModifierFlags(rawValue: UInt(Int(NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue)))
    }
    
    public func addNetfoxToMainMenu() {
        setupNetfoxMenuItem()
        if let menu = mainMenu {
            menu.insertItem(nfxMenuItem, at: 0)
        }
    }
    
    public func removeNetfoxFromMainmenu() {
        if let menu = mainMenu {
            menu.removeItem(nfxMenuItem)
        }
    }
    
    public func showNFXFollowingPlatform()  {
        if windowController == nil {
            let nibName = Constants.nibName.rawValue

            windowController = NFXWindowController(windowNibName: nibName)
        }
        windowController?.showWindow(nil)
    }
    
    public func hideNFXFollowingPlatform(completion: (() -> Void)?) {
        windowController?.close()
        if let notNilCompletion = completion {
            notNilCompletion()
        }
    }
}

#endif
