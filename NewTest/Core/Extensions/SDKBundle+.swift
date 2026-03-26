//
//  SDKBundle+.swift
//  IdentifyIOS_Example
//
//  Created by Emir Beytekin on 23.05.2022.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Foundation
import SwiftUI

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
    var releaseVersionNumberPretty: String {
        return "v\(releaseVersionNumber ?? "1.0.0")"
    }
}

// MARK: - SwiftUI EnvironmentKey

/// Kullanım: @Environment(\.appVersion) private var appVersion
private struct AppVersionKey: EnvironmentKey {
    static let defaultValue: String = Bundle.main.releaseVersionNumberPretty
}

extension EnvironmentValues {
    var appVersion: String {
        get { self[AppVersionKey.self] }
        set { self[AppVersionKey.self] = newValue }
    }
}
