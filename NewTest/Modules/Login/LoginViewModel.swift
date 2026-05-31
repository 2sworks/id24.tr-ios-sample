//
//  LoginViewModel.swift
//  NewTest
//

import Foundation
import CoreData
import UIKit
import IdentifySDK

// MARK: - ServerOption

struct ServerOption: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var apiUrl: String
    var wsUrl: String
}

// MARK: - LoginViewModel

@MainActor
final class LoginViewModel: BaseModuleViewModel {

    // MARK: - Ident ID

    @Published var identId: String = ""

    // MARK: - Yeni Müşteri Form

    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var tcNo: String = ""
    @Published var serialNo: String = ""
    @Published var birthDate: String = ""
    @Published var expiryDate: String = ""
    @Published var selectedProject: String = ""

    // MARK: - SDK Config

    @Published var selectedSDKLang: SDKLang = .eng
    @Published var selectedIdLang: IDLang = .TR
    @Published var selectedServer: ServerOption = ServerOption(
        title: "V2",
        apiUrl: "https://v2api.identify.com.tr",
        wsUrl: "wss://v2ws.identify.com.tr"
    )
    @Published var serverList: [ServerOption] = []
    @Published var selectedModules: [SdkModules] = []

    // MARK: - Toggles

    @Published var useBigCustomerCam: Bool = false
    @Published var useSignLang: Bool = false
    @Published var useNewLiveness: Bool = false
    @Published var useSSLPinning: Bool = false

    // MARK: - Device

    @Published private(set) var isJailbroken: Bool = false

    var buildNumber: String {
        Bundle.main.buildVersionNumber ?? ""
    }

    // MARK: - Init

    override init() {
        super.init()
        checkJailbreak()
        loadSavedServers()
    }

    // MARK: - SDK Language

    func setSDKLanguage(_ lang: SDKLang) {
        selectedSDKLang = lang
        manager.setSDKLang(lang: lang)
    }

    // MARK: - Modules

    let availableModules: [SdkModules] = [
        .prepare, .idCard, .idcard_w_ovd, .nfc, .livenessDetection,
        .speech, .addressConf, .signature, .videoRecord, .selfie, .waitScreen
    ]

    func updateModules(_ modules: [SdkModules]) {
        selectedModules = modules
    }

    // MARK: - Servers

    private let sabitSunucular: [ServerOption] = [
        ServerOption(title: "Live", apiUrl: "https://api.identify.com.tr/",     wsUrl: "wss://ws.identify.com.tr"),
        ServerOption(title: "Test", apiUrl: "https://apitest.identify.com.tr/", wsUrl: "wss://wstest.identify.com.tr"),
        ServerOption(title: "Dev",  apiUrl: "https://apidev.identify.com.tr/",  wsUrl: "wss://wsdev.identify.com.tr"),
        ServerOption(title: "V2",   apiUrl: "https://v2api.identify.com.tr",    wsUrl: "wss://v2ws.identify.com.tr"),
        ServerOption(title: "QA",   apiUrl: "https://apiqa.identify.com.tr",    wsUrl: "wss://wsqa.identify.com.tr")
    ]

    func loadSavedServers() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            serverList = sabitSunucular
            return
        }
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "EnvServers")
        var customList: [ServerOption] = []
        if let results = try? context.fetch(fetchRequest) as? [NSManagedObject] {
            for item in results {
                let title  = item.value(forKey: "envTitle")  as? String ?? "Sunucu"
                let apiUrl = item.value(forKey: "apiUrl")    as? String ?? ""
                let wsUrl  = item.value(forKey: "socketUrl") as? String ?? ""
                customList.append(ServerOption(title: title, apiUrl: apiUrl, wsUrl: wsUrl))
            }
        }
        serverList = sabitSunucular + customList
    }

    func selectServer(_ server: ServerOption) {
        selectedServer = server
    }

    // MARK: - Ident ID Aliases

    func resolveIdentId() -> String {
        let aliases: [String: String] = [
            "xxx":    "eaebe29505c8c27ab68a626f8c0a8bb61e61d3f9",
            "x":      "1404df9c1cbd6c66bbb3c9217ea4bbfc1157fd33",
            "y":      "7fc133f53bb05aa7547b671db589dff994c62fcc",
            "oo":     "87b9dc12bc003f80ab47c8d80d500349e6a31c5a",
            "tahsin": "70a156b19356e600c7ccce3bb3061886091c39b7",
            "h":      "600d7388a82294f712147672ef56965c77d92f41",
            "qa":     "1404df9c1cbd6c66bbb3c9217ea4bbfc1157fd33",
            "busra":  "14412dd4616298aabbd80c9628860ed8d214c288",
            "c":      "3e72ce1cd9872ccdd7dca0affad6abb57a9ca73e",
            "c2":     "a170357f1ed311b3c49880a5ec2f1d78d0bf624d"
        ]
        return aliases[identId] ?? identId
    }

    // MARK: - Private

    private func checkJailbreak() {
        isJailbroken = manager.jailBreakStatus
    }
}
