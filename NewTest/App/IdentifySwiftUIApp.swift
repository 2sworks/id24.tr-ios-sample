//
//  IdentifySwiftUIApp.swift
//  NewTest
//
//  SwiftUI entry point köprüsü - mimari belgelendirme.
//
//  Uygulama boot akışı:
//
//  AppDelegate.didFinishLaunchingWithOptions
//    └─ startSwiftUIScreen()
//         └─ UIWindow
//              └─ UINavigationController          ← UIKit VC'lerin push için kullandığı container
//                   └─ UIHostingController<IdentifyRootView>
//                        └─ IdentifyRootView (SwiftUI NavigationStack)
//                             └─ LoginView        ← Kullanıcı tasarımı burada
//                                  │
//                                  │ [Bağlan tıklandı]
//                                  ▼
//                             AppStateViewModel.setupSDK(...)
//                                  │
//                                  │ [Başarılı callback]
//                                  ▼
//                             AppStateViewModel.advanceToNextModule()
//                                  │
//                                  │ [getNextModule → nextModuleVC publish]
//                                  ▼
//                             SDKModuleHostView(viewController: nextModuleVC)
//                                  │
//                                  │ [UIKit VC içeriden push eder]
//                                  ▼
//                             UINavigationController.pushViewController(nextVC)
//                                  │
//                                  │ [modulePublisher event]
//                                  ▼
//                             AppStateViewModel.activeModule güncelenir
//
//  Önemli notlar:
//  - LoginView'dan sonraki tüm modüller UIKit VC'dir (UINavigationController üzerinden push).
//  - modulePublisher subscription AppStateViewModel.subscribeToModulePublisher() içindedir.
//  - Yeni bir oturum için appState.resetFlow() çağrılır.
//

import Foundation
// Bu dosya yalnızca belgelendirme amaçlıdır.
