//
//  UIViewController+.swift
//  NewTest
//
//  Created by Emir Beytekin on 27.10.2022.
//

import UIKit

extension UIViewController {
    
    public static func instantiate() -> Self {
        func instanceFromNib<T: UIViewController>() -> T {
            return T(nibName: String(describing: self), bundle: Bundle(for: self))
        }
        return instanceFromNib()
    }
}
