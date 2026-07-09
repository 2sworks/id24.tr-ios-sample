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
    /// Core Data'dan gelen kullanıcı tanımlı sunucu; yalnızca bunlar silinebilir.
    var isCustom: Bool = false
}

// MARK: - LoginViewModel

@MainActor
final class LoginViewModel: ObservableObject {

    // MARK: - Base (eski BaseModuleViewModel'den inline)

    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    let manager = IdentifyManager.shared

    // MARK: - Ident ID

    @Published var identId: String = ""

    /// "Beni Hatırla" tercihi. Açıkken girilen Ident ID kaydedilir ve bir sonraki
    /// açılışta alana otomatik gelir; kapalıyken hiçbir şey saklanmaz.
    @Published var rememberMe: Bool = false

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

    // MARK: - UserDefaults Keys

    private enum UDKey {
        static let selectedServerTitle  = "selected_server_title"
        static let selectedServerApiUrl = "selected_server_api_url"
        static let selectedServerWsUrl  = "selected_server_ws_url"
        static let selectedSDKLang      = "selected_sdk_lang"
        static let lastIdentId          = "last_ident_id"
        static let rememberMe           = "remember_ident_id"
    }

    var hasUserSelectedServer: Bool {
        UserDefaults.standard.string(forKey: UDKey.selectedServerTitle) != nil
    }

    // MARK: - Init

    init() {
        let savedLangRaw = UserDefaults.standard.string(forKey: UDKey.selectedSDKLang)
        let savedLang = savedLangRaw.flatMap(SDKLang.init) ?? .tr
        selectedSDKLang = savedLang
        manager.setSDKLang(lang: savedLang)
        rememberMe = UserDefaults.standard.bool(forKey: UDKey.rememberMe)
        // "Beni Hatırla" açıksa son Ident ID'yi alana getir; kapalıysa boş başla.
        identId = rememberMe ? (UserDefaults.standard.string(forKey: UDKey.lastIdentId) ?? "") : ""
        checkJailbreak()
        loadSavedServers()
        loadSelectedServer()
    }

    // MARK: - SDK Language

    func setSDKLanguage(_ lang: SDKLang) {
        selectedSDKLang = lang
        manager.setSDKLang(lang: lang)
        SDKLocalization.shared.clearCache()
        UserDefaults.standard.set(lang.rawValue, forKey: UDKey.selectedSDKLang)
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
                customList.append(ServerOption(title: title, apiUrl: apiUrl, wsUrl: wsUrl, isCustom: true))
            }
        }
        serverList = sabitSunucular + customList
    }

    func selectServer(_ server: ServerOption) {
        selectedServer = server
        saveSelectedServer(server)
    }

    /// Kullanıcı tanımlı yeni sunucuyu Core Data'ya kaydeder ve listeyi yeniler.
    /// WS adresi ayrıca sorulmaz; bağlantı yalnızca apiUrl üzerinden kurulur.
    func addServer(title: String, apiUrl: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        guard let entity = NSEntityDescription.entity(forEntityName: "EnvServers", in: context) else { return }
        let server = NSManagedObject(entity: entity, insertInto: context)
        server.setValue(title,  forKey: "envTitle")
        server.setValue(apiUrl, forKey: "apiUrl")
        server.setValue("",     forKey: "socketUrl")
        try? context.save()
        loadSavedServers()
    }

    /// Kullanıcı tanımlı sunucuyu Core Data'dan siler. Sabit sunucular silinemez.
    /// Silinen sunucu seçiliyse ilk sabit sunucuya dönülür.
    func deleteServer(_ server: ServerOption) {
        guard server.isCustom,
              let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "EnvServers")
        if let results = try? context.fetch(fetchRequest) as? [NSManagedObject] {
            for item in results where
                (item.value(forKey: "envTitle") as? String) == server.title &&
                (item.value(forKey: "apiUrl")   as? String) == server.apiUrl {
                context.delete(item)
            }
            try? context.save()
        }
        loadSavedServers()
        if selectedServer.title == server.title && selectedServer.apiUrl == server.apiUrl,
           let fallback = serverList.first {
            selectServer(fallback)
        }
    }

    // MARK: - Remember Me

    /// "Beni Hatırla" tercihini değiştirir ve kalıcı olarak saklar. Kapatılırsa
    /// saklanan son Ident ID de silinir.
    func setRememberMe(_ on: Bool) {
        rememberMe = on
        UserDefaults.standard.set(on, forKey: UDKey.rememberMe)
        if on {
            UserDefaults.standard.set(identId, forKey: UDKey.lastIdentId)
        } else {
            UserDefaults.standard.removeObject(forKey: UDKey.lastIdentId)
        }
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

    // MARK: - Connect

    /// SDK'yı kurar ve başarıda Default UI akışını başlatır.
    /// Opsiyon montajı eski `AppStateViewModel.setupSDK`'dan buraya taşındı.
    func connect(coordinator: SDKFlowCoordinator) {
        // "Beni Hatırla" açıksa girilen Ident ID'yi sakla; kapalıysa temizle.
        if rememberMe {
            UserDefaults.standard.set(identId, forKey: UDKey.lastIdentId)
        } else {
            UserDefaults.standard.removeObject(forKey: UDKey.lastIdentId)
        }
        isLoading = true
        errorMessage = nil

        // setupSDK'dan ÖNCE placeholder controller'ları kaydet; aksi halde SDK
        // modulesControllersArray'i farklı instance'larla kurar ve modüller başlamaz.
        coordinator.prepareForSetup()

        manager.setupSDK(
            identId: resolveIdentId(),
            baseApiUrl: selectedServer.apiUrl,
            networkOptions: SDKNetworkOptions(
                timeoutIntervalForRequest: 30,
                timeoutIntervalForResource: 30,
                useSslPinning: useSSLPinning
            ),
            kpsData: nil,
            identCardType: [.idCard, .passport, .oldSchool],
            signLangSupport: useSignLang,
            nfcMaxErrorCount: 3,
            logLevel: .online,
            logOnlineSecretKey: "dGhpc19pc19qdXN0X2R1bW15X3NlY3JldF9mb3JfZGVtbw==",
            bigCustomerCam: useBigCustomerCam,
            selectedModules: selectedModules,
            idCardLang: selectedIdLang,
            turnKey: "AEdHh9OZu1kg+nSBSd2UNMu9y4Kc3xVfgTsvw+PTAic=",
            wsSecretKey: "tgdRmdAABrWf9TCRJZIWoW3Bz0iPJpig5jtOkBN4pvU=",
            showThankYouPage: true,
            showNFCNotFoundPage: true,
            supportU18: true,
            AESKey: "SEATSJ8kk0v8+A1LeQsAMbOgL+fSj9pOaUKI5cDMITU=",
            enableAutoRotateOCR: true,
            // "Sesli Okuma (TTS)" tercihi (Ayarlar menüsündeki toggle). Hardcoded true iken
            // setupSDK, kapalıyken bile defaultMode .off → .native yükseltip toggle'ı
            // anlamsız kılıyordu. Artık gerçek tercih geçiliyor.
            ttsEnabled: UserDefaults.standard.bool(forKey: "sdkReadAloudEnabled")
        ) { [weak self] socketStats, apiResp, webErr in
            guard let self else { return }
            Task { @MainActor in
                self.isLoading = false
                if let err = webErr, err.errorMessages != "" {
                    self.errorMessage = err.errorMessages
                    return
                }
                if socketStats?.isConnected == true && (apiResp.result ?? false) {
                    coordinator.start()
                } else if socketStats?.isConnected == false {
                    self.errorMessage = "Socket bağlantısı kurulamadı"
                }
            }
        }
    }

    // MARK: - Private

    private func checkJailbreak() {
        isJailbroken = manager.jailBreakStatus
    }

    private func saveSelectedServer(_ server: ServerOption) {
        let ud = UserDefaults.standard
        ud.set(server.title,  forKey: UDKey.selectedServerTitle)
        ud.set(server.apiUrl, forKey: UDKey.selectedServerApiUrl)
        ud.set(server.wsUrl,  forKey: UDKey.selectedServerWsUrl)
    }

    private func loadSelectedServer() {
        let ud = UserDefaults.standard
        guard
            let title  = ud.string(forKey: UDKey.selectedServerTitle),
            let apiUrl = ud.string(forKey: UDKey.selectedServerApiUrl),
            let wsUrl  = ud.string(forKey: UDKey.selectedServerWsUrl)
        else { return }
        // Match against serverList so the id stays consistent for selection highlighting
        if let existing = serverList.first(where: { $0.apiUrl == apiUrl }) {
            selectedServer = existing
        } else {
            selectedServer = ServerOption(title: title, apiUrl: apiUrl, wsUrl: wsUrl)
        }
    }
}
