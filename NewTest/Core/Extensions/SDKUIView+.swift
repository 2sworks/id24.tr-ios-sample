//
//  SDKUIView+.swift
//  IdentifyIOS_Example
//
//  Created by Emir Beytekin on 23.05.2022.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import SwiftUI

extension UIView {
    
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
         let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
         let mask = CAShapeLayer()
         mask.path = path.cgPath
         layer.mask = mask
     }
    
    static func loadFromXib<T>(withOwner: Any? = nil, options: [UINib.OptionsKey : Any]? = nil) -> T where T: UIView {
        let bundle = Bundle(for: self)
        let nib = UINib(nibName: "\(self)", bundle: bundle)

        guard let view = nib.instantiate(withOwner: withOwner, options: options).first as? T else {
            fatalError("Could not load view from nib file.")
        }
        return view
    }
    
    func dropShadow(color: UIColor, opacity: Float = 0.5, offSet: CGSize, radius: CGFloat = 1, scale: Bool = true) {
        layer.masksToBounds = false
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offSet
        layer.shadowRadius = radius

        layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
    
    @IBInspectable
    var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
}

// MARK: - SwiftUI View Extensions

extension View {

    /// Identify SDK gölge stili
    func sdkShadow(
        color: Color = .black,
        opacity: Double = 0.3,
        offset: CGSize = CGSize(width: -1, height: 1),
        radius: CGFloat = 9
    ) -> some View {
        self.shadow(
            color: color.opacity(opacity),
            radius: radius,
            x: offset.width,
            y: offset.height
        )
    }

    /// Belirli köşeleri yuvarlama (SwiftUI)
    func sdkRoundCorners(_ corners: UIRectCorner, radius: CGFloat) -> some View {
        clipShape(RoundedCornerShape(corners: corners, radius: radius))
    }
}

// MARK: - RoundedCornerShape

/// `sdkRoundCorners` için yardımcı Shape
struct RoundedCornerShape: Shape {
    var corners: UIRectCorner
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
