//
//  SDKCgRect+.swift
//  IdentifyIOS_Example
//
//  Created by Emir Beytekin on 23.05.2022.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit

extension CGRect {
    
    func isValid() -> Bool {
        return
          !(origin.x.isNaN || origin.y.isNaN || width.isNaN || height.isNaN || width < 0 || height < 0
          || origin.x < 0 || origin.y < 0)
    }
}
