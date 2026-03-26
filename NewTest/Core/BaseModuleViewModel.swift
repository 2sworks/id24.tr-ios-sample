//
//  BaseModuleViewModel.swift
//  NewTest
//
//  Tüm modül ViewModel'lerinin miras aldığı base class.
//  IdentifyManager referansı ve ortak Published state'leri sağlar.
//

import Foundation
import IdentifySDK

@MainActor
class BaseModuleViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    let manager = IdentifyManager.shared
}
