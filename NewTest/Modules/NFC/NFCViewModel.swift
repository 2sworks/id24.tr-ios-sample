//
//  NFCViewModel.swift
//  NewTest
//
//  NFC pasaport okuma ekraninin ViewModel'i.
//  SDK: manager.startNFC, manager.sdkBackInfo, manager.nfcMsgHandler
//

import Foundation
import UIKit
import IdentifySDK

@MainActor
final class NFCViewModel: BaseModuleViewModel {

    // MARK: - Published State

    @Published var serialNo: String = ""
    @Published var birthDate: String = ""
    @Published var validDate: String = ""
    @Published var nfcStatus: String = ""
    @Published var nfcCompleted: Bool = false
    @Published var showEditScreen: Bool = false
    @Published var isBirthdayPicker: Bool = true
    @Published var canContinue: Bool = false

    // MARK: - Init

    override init() {
        super.init()
        loadMRZFromSDK()
        setupNFCMessageHandler()
    }

    // MARK: - MRZ Verisi

    private func loadMRZFromSDK() {
        if manager.useKpsData {
            serialNo  = manager.mrzDocNo
            birthDate = manager.mrzBirthDay
            validDate = manager.mrzValidDate
        } else {
            serialNo  = manager.sdkBackInfo.idDocumentNumberMRZ ?? ""
            birthDate = manager.sdkBackInfo.idBirthDateMRZ ?? ""
            validDate = manager.sdkBackInfo.idValidDateMRZ ?? ""
        }
    }

    // MARK: - NFC Mesaj Handler

    private func setupNFCMessageHandler() {
        manager.nfcMsgHandler = { [weak self] displayMessage -> String in
            guard let self else { return "" }
            switch displayMessage {
            case .requestPresentPassport:
                return "Pasaportu okutun"
            case .authenticatingWithPassport(let progress):
                return "Kimlik dogrulaniyor: \(progress)%"
            case .readingDataGroupProgress(_, let progress):
                return "Veri okunuyor: \(progress)%"
            case .error(let err):
                Task { @MainActor in self.nfcStatus = "Hata: \(err)" }
                return "Hata olustu"
            case .successfulRead:
                Task { @MainActor in self.nfcStatus = "Okuma tamamlandi" }
                return "Basarili"
            default:
                return ""
            }
        }
    }

    // MARK: - NFC Baslat

    func startNFC(appState: AppStateViewModel) {
        guard !serialNo.isEmpty && !birthDate.isEmpty && !validDate.isEmpty else {
            showEditScreen = true
            return
        }
        isLoading = true
        nfcStatus = "NFC baslatiliyor..."

        manager.startNFC { [weak self] idCard, identStatus, webResponse, err in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                if err != nil {
                    self.manager.tryedNfcComparisonCount += 1
                    if self.manager.tryedNfcComparisonCount >= self.manager.nfcComparisonCount {
                        if self.manager.activeComparisonResultSkipModule == "1" {
                            appState.skipCurrentModule()
                        } else {
                            self.showEditScreen = true
                        }
                    } else {
                        self.nfcStatus = "Tekrar deneyin"
                    }
                } else {
                    self.nfcCompleted = true
                    self.canContinue = true
                    self.nfcStatus = "NFC basarili"
                    appState.advanceToNextModule()
                }
            }
        }
    }

    // MARK: - Manuel Tarih Duzeltme

    func saveManualDates() {
        // sdkBackInfo is non-optional, set fields directly
        manager.sdkBackInfo.idDocumentNumberMRZ = serialNo
        manager.sdkBackInfo.idBirthDateMRZ = birthDate
        manager.sdkBackInfo.idValidDateMRZ = validDate
        showEditScreen = false
    }
}
