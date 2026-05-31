//
//  PrepareViewModel.swift
//  NewTest
//
//  Hazirlik ekrani - baglanti hizi, kamera/mikrofon/konusma izinleri.
//  SDK: manager.startSpeedTest, manager.sendPreparetatus, manager.needSpeedTest
//

import Foundation
import CameraPermission
import MicrophonePermission
import SpeechRecognizerPermission
import PermissionsKit
import IdentifySDK

@MainActor
final class PrepareViewModel: BaseModuleViewModel {

    // MARK: - Published State

    @Published private(set) var speedCheckDone: Bool = false
    @Published private(set) var measuredSpeed: CGFloat = 0
    @Published private(set) var connectionQuality: SDKNetworkStatus = .good
    @Published private(set) var cameraAuthorized: Bool = false
    @Published private(set) var micAuthorized: Bool = false
    @Published private(set) var speechAuthorized: Bool = false

    @Published var showSettingsAlert: Bool = false
    var settingsAlertMessage: String = ""
    var settingsOpenAction: (() -> Void)?

    var allPermissionsGranted: Bool {
        cameraAuthorized && micAuthorized && speechAuthorized
    }

    var canProceed: Bool {
        allPermissionsGranted && (speedCheckDone || !(manager.needSpeedTest ?? false))
    }

    // MARK: - Init

    override init() {
        super.init()
        checkPermissions()
        if manager.needSpeedTest == true {
            startSpeedTest()
        } else {
            speedCheckDone = true
        }
    }

    // MARK: - Izin Kontrolleri

    func checkPermissions() {
        checkCamera()
        checkMicrophone()
        checkSpeech()
    }

    func checkCamera() {
        let perm = CameraPermission.camera
        if perm.authorized {
            cameraAuthorized = true
        } else if perm.status == .denied {
            settingsAlertMessage = "Kamera izni reddedildi. Devam etmek için ayarlardan izin verin."
            settingsOpenAction = { perm.openSettingPage() }
            showSettingsAlert = true
        } else {
            perm.request {
                Task { @MainActor in
                    self.cameraAuthorized = CameraPermission.camera.authorized
                }
            }
        }
    }

    func checkMicrophone() {
        let perm = MicrophonePermission.microphone
        if perm.authorized {
            micAuthorized = true
        } else if perm.status == .denied {
            settingsAlertMessage = "Mikrofon izni reddedildi. Devam etmek için ayarlardan izin verin."
            settingsOpenAction = { perm.openSettingPage() }
            showSettingsAlert = true
        } else {
            perm.request {
                Task { @MainActor in
                    self.micAuthorized = MicrophonePermission.microphone.authorized
                }
            }
        }
    }

    func checkSpeech() {
        let perm = SpeechPermission.speech
        if perm.authorized {
            speechAuthorized = true
        } else if perm.status == .denied {
            settingsAlertMessage = "Ses tanıma izni reddedildi. Devam etmek için ayarlardan izin verin."
            settingsOpenAction = { perm.openSettingPage() }
            showSettingsAlert = true
        } else {
            perm.request {
                Task { @MainActor in
                    self.speechAuthorized = SpeechPermission.speech.authorized
                }
            }
        }
    }

    // MARK: - Hiz Testi

    func startSpeedTest() {
        isLoading = true
        manager.startSpeedTest { [weak self] connectionStatus, kbPerSec in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                self.speedCheckDone = true
                self.measuredSpeed = kbPerSec
                self.connectionQuality = connectionStatus
            }
        }
    }

    // MARK: - Hazirlik Tamamlama

    func completePrepare(appState: AppStateViewModel) {
        manager.sendPreparetatus(isCompleted: true)
        appState.advanceToNextModule()
    }
}
