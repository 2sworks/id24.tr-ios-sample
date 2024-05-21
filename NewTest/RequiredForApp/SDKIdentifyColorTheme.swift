//
//  SDKIdentifyColorTheme.swift
//  NewTest
//
//  Created by Emir Beytekin on 19.01.2023.
//

import UIKit


public struct IdentifyTheme {
    
    static var blackBack: UIColor { return UIColor().hexStringToUIColor(hex:"000814") }
    
    static var orangeColor: UIColor { return UIColor().hexStringToUIColor(hex:"fca311") }
    
    static var grayColor: UIColor { return UIColor().hexStringToUIColor(hex:"333533") }
    
    static var darkGrayColor: UIColor { return UIColor().hexStringToUIColor(hex:"1c1c1c") }
    
    static var lightGrayColor: UIColor { return UIColor().hexStringToUIColor(hex:"ced5de") }
    
    static var blueColor: UIColor { return UIColor().hexStringToUIColor(hex:"7bb2d9") }
    
    static var lightBlueColor: UIColor { return UIColor().hexStringToUIColor(hex:"cae9ff") }
    
    static var lightWhiteColor: UIColor { return UIColor().hexStringToUIColor(hex: "fefefe") }
    
    static var whiteColor: UIColor { return UIColor().hexStringToUIColor(hex: "ffffff") }
    
    static var submitBlueColor: UIColor { return UIColor().hexStringToUIColor(hex: "3227C9") }

}


extension UIColor {
    func hexStringToUIColor(hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return UIColor.gray
        }

        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
