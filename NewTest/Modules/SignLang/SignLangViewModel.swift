//
//  SignLangViewModel.swift
//  NewTest
//
//  İşaret dili opt-in ekranı ViewModel'i.
//  manager.connectToSignLang set eder, sendStep çağırır ve tamamlanma callback'ini tetikler.
//

import Foundation
import IdentifySDK

@MainActor
final class SignLangViewModel: BaseModuleViewModel {

    @Published var isSignLangEnabled: Bool = false

    func continueAction(onFinish: @escaping () -> Void) {
        manager.connectToSignLang = isSignLangEnabled
        manager.sendStep()
        onFinish()
    }
}
