//
//  SDKColorManager.swift
//  NewTest
//
//  Created by Emir Beytekin on 27.10.2022.
//

import UIKit

public class SDKColorManager: NSObject {
    
    override init() {}
    
    public static let shared = SDKColorManager.init()
    
    public lazy var backgroundGradient: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.153, green: 1, blue: 0.882, alpha: 1).cgColor,
            UIColor(red: 0.31, green: 0.18, blue: 0.851, alpha: 1).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0.25, y: 0.5)
        gradient.endPoint = CGPoint(x: 0.75, y: 0.5)
        gradient.transform = CATransform3DMakeAffineTransform(CGAffineTransform(a: 1.19, b: 0.94, c: -0.8, d: 1.41, tx: 0.27, ty: -0.52))
        gradient.locations = [0, 1]
        return gradient
    }()
    
    public lazy var backgroundBlackGradient: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.colors = [
          UIColor(red: 0, green: 0, blue: 0, alpha: 1).cgColor,
          UIColor(red: 0, green: 0, blue: 0, alpha: 0.88).cgColor,
          UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor
        ]
        gradient.locations = [0, 0.35, 1]
        gradient.startPoint = CGPoint(x: 0.25, y: 0.5)
        gradient.endPoint = CGPoint(x: 0.75, y: 0.5)
        gradient.transform = CATransform3DMakeAffineTransform(CGAffineTransform(a: 0, b: -0.51, c: 2.73, d: 0, tx: -0.86, ty: 0.87))
        
        return gradient
    }()
    
}
