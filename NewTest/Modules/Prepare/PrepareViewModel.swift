//
//  PrepareViewModel.swift
//  NewTest
//
//  Hazirlik ekrani - baglanti hizi, kamera/mikrofon/konusma izinleri.
//  SDK: manager.startSpeedTest, manager.sendPreparetatus, manager.needSpeedTest
//

import Foundation
import AVFoundation
import Speech
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
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraAuthorized = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in self?.cameraAuthorized = granted }
            }
        default:
            cameraAuthorized = false
        }
    }

    func checkMicrophone() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            micAuthorized = true
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                Task { @MainActor in self?.micAuthorized = granted }
            }
        default:
            micAuthorized = false
        }
    }

    func checkSpeech() {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            speechAuthorized = true
        case .notDetermined:
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                Task { @MainActor in self?.speechAuthorized = status == .authorized }
            }
        default:
            speechAuthorized = false
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
