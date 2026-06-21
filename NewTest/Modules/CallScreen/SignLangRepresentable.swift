//
//  SignLangRepresentable.swift
//  NewTest
//
//  Mevcut SDKSignLangViewController'ı SwiftUI fullScreenCover içinde kullanmak için sarmalayıcı.
//

import SwiftUI
import UIKit

struct SignLangRepresentable: UIViewControllerRepresentable {

    var onFinish: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        let vc = SDKSignLangViewController()
        vc.delegate = context.coordinator
        return UINavigationController(rootViewController: vc)
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    final class Coordinator: NSObject, SDKSignLangViewControllerDelegate {
        let onFinish: () -> Void

        init(onFinish: @escaping () -> Void) {
            self.onFinish = onFinish
        }

        func sdkSignLangViewControllerDidFinish(_ controller: SDKSignLangViewController) {
            onFinish()
        }
    }
}
