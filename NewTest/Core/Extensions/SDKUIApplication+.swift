//
//  SDKUIApplication+.swift
//  IdentifyIOS_Example
//
//  Created by Emir Beytekin on 23.05.2022.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit

extension UIApplication {

    /// Aktif window scene üzerinden kök view controller'ı döndürür.
    /// iOS 13+ `keyWindow` kullanımını kaldırır.
    var activeRootViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }

    /// Ekranda en üstte görünen view controller'ı döndürür.
    public class func topViewController(viewController: UIViewController? = nil) -> UIViewController? {
        let root = viewController ?? UIApplication.shared.activeRootViewController
        if let nav = root as? UINavigationController {
            return topViewController(viewController: nav.visibleViewController)
        }
        if let presented = root?.presentedViewController {
            return topViewController(viewController: presented)
        }
        return root
    }
}
