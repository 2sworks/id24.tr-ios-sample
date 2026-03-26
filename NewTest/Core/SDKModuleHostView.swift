//
//  SDKModuleHostView.swift
//  NewTest
//
//  Generic UIViewControllerRepresentable wrapper.
//  SDK'nın UIKit ViewController'larını SwiftUI NavigationStack içinde gösterir.
//  UIKit VC'ler kendi navigationController.push akışlarını kullanmaya devam eder.
//

import SwiftUI
import UIKit

struct SDKModuleHostView: UIViewControllerRepresentable {
    let viewController: UIViewController

    func makeUIViewController(context: Context) -> UIViewController {
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
