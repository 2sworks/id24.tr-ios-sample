//
//  AppDelegate.swift
//  NewTest
//
//  Created by Emir Beytekin on 10.10.2022.
//

import UIKit
import SwiftUI
import IQKeyboardManagerSwift
import netfox
import IdentifySDK
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UIApplication.shared.isIdleTimerDisabled = true
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = true
        SDKReachabilityHelper.shared.observeReachability()
        NFX.sharedInstance().start()
        startSwiftUIScreen()
        return true
    }

    // MARK: - SwiftUI Entry Point

    func startSwiftUIScreen() {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        // Coordinator + AppState IdentifyNavigationCoordinatorView içinde @StateObject olarak yaşar.
        let rootView = IdCardScannerView(side: .front)
        let hostingVC = UIHostingController(rootView: rootView)
        self.window?.rootViewController = hostingVC
        self.window?.makeKeyAndVisible()
    }

    // MARK: - Core Data Stack

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Env")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
