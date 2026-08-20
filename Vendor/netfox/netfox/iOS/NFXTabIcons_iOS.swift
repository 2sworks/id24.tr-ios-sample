//
//  NFXTabIcons_iOS.swift
//  netfox
//
//  Yerel fork eklentisi — sekme çubuğu ikonları.
//

#if os(iOS)

import UIKit

extension UIImage {

    /// HTTP trafiği sekmesi.
    static func NFXNetworkTabIcon() -> UIImage? {
        return UIImage(systemName: "arrow.up.arrow.down.circle")
    }

    /// Konsol çıktısı sekmesi.
    static func NFXConsoleTabIcon() -> UIImage? {
        return UIImage(systemName: "terminal")
    }

    /// Host uygulamanın bağladığı kaynak sekmesi.
    static func NFXExternalTabIcon() -> UIImage? {
        return UIImage(systemName: "bolt.horizontal.circle")
    }
}

#endif
