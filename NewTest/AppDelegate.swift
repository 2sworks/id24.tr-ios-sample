//
//  AppDelegate.swift
//  NewTest
//
//  Created by Emir Beytekin on 10.10.2022.
//

import UIKit
import IQKeyboardManagerSwift
import netfox
import IdentifySDK
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.        
        UIApplication.shared.isIdleTimerDisabled = true
        IQKeyboardManager.shared.enable = true
        NFX.sharedInstance().start()
        startFirstScreen()
        
        return true
    }
    
    func startFirstScreen() {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        let firstVC = SDKLoginViewController()
        let firstNC = UINavigationController(rootViewController: firstVC)
        UINavigationBar.appearance().tintColor = .white
//        UINavigationBar.appearance().prefersLargeTitles = false
//        UINavigationBar.appearance().backgroundColor = KHTheme.grayColor
//        UIBarButtonItem.appearance().tintColor = .white // pushtan sonra ki sayfanın buton rengi
//        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
        self.window?.rootViewController = firstNC
        self.window?.makeKeyAndVisible()
    }
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Env")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support
    func saveContext () {
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



