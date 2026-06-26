//
//  SDKBundle+.swift
//  IdentifyIOS_Example
//
//  Created by Emir Beytekin on 23.05.2022.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Foundation

extension Bundle {
    /// Login ekranında build numarasını göstermek için kullanılır.
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}
