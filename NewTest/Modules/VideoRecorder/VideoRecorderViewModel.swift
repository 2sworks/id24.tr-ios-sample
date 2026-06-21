//
//  VideoRecorderViewModel.swift
//  NewTest
//
//  5 saniye video kayit ekraninin ViewModel'i.
//  SDK: upload5SecVideo
//

import Foundation
import UIKit
import Speech
import IdentifySDK

@MainActor
final class VideoRecorderViewModel: BaseModuleViewModel {

    // MARK: - Published State

    /// Kaydedilen video verisi
    @Published var videoData: Data? = nil

    /// Onizleme URL (AVPlayer icin)
    @Published var videoURL: URL? = nil

    /// Yukleme tamamlandi mi
    @Published private(set) var uploadCompleted: Bool = false

    /// Video suresi limiti (saniye)
    let videoTimeLimit: TimeInterval = 5.0

    // MARK: - Reading Test State

    /// Kullanıcının okuması gereken cümle. nil ise okuma testi devre dışı.
    /// TODO: sunucu reading_text bağlanacak — manager.tempResp.data?.reading_text
    @Published private(set) var readingText: String? = nil

    /// SFSpeech ile video ses kanalından elde edilen transkript
    @Published private(set) var recognizedText: String = ""

    /// readingText başarıyla tanındı mı
    @Published private(set) var speechSuccess: Bool = false

    /// Transkripsiyon devam ediyor mu
    @Published private(set) var isTranscribing: Bool = false

    // MARK: - Private

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "tr-TR"))
    private var recognitionTask: SFSpeechRecognitionTask?

    // MARK: - Reading Text (dışarıdan override)

    /// Sunucudan reading_text geldiğinde çağrılır. Boş string gelirse nil'e çekilir.
    func updateReadingText(_ text: String) {
        readingText = text.isEmpty ? nil : text
    }

    // MARK: - Video Secildi

    func videoSelected(url: URL) {
        videoURL = url
        videoData = try? Data(contentsOf: url)
        uploadCompleted = false
        errorMessage = nil
        recognizedText = ""
        speechSuccess = false
        if readingText != nil {
            transcribeVideo(url: url)
        }
    }

    // MARK: - Transkripsiyon

    private func transcribeVideo(url: URL) {
        isTranscribing = true
        recognitionTask?.cancel()
        recognitionTask = nil

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                self.isTranscribing = false
                self.recognitionTask = nil

                if let result {
                    self.recognizedText = result.bestTranscription.formattedString
                    self.checkSpeechResult()
                } else if let error {
                    self.errorMessage = "Ses tanıma başarısız: \(error.localizedDescription)"
                }
            }
        }
    }

    private func checkSpeechResult() {
        guard let target = readingText else { return }
        let matched = recognizedText.lowercased().contains(target.lowercased())
        if matched {
            speechSuccess = true
        } else {
            errorMessage = "Okuma testi doğrulanamadı. Lütfen cümleyi okuyarak tekrar çekin."
        }
    }

    // MARK: - Delete

    func deleteVideo() {
        recognitionTask?.cancel()
        recognitionTask = nil
        if let url = videoURL {
            try? FileManager.default.removeItem(at: url)
        }
        videoURL = nil
        videoData = nil
        uploadCompleted = false
        errorMessage = nil
        recognizedText = ""
        speechSuccess = false
        isTranscribing = false
    }

    // MARK: - Upload

    func uploadVideo(appState: AppStateViewModel) {
        if readingText != nil && !speechSuccess {
            errorMessage = "Okuma testi doğrulanamadı. Lütfen cümleyi okuyarak tekrar çekin."
            return
        }
        guard let data = videoData else {
            errorMessage = "Video secilmedi"
            return
        }
        isLoading = true
        manager.upload5SecVideo(videoData: data) { [weak self] resp, webErr in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                if let err = webErr, err.errorMessages != "" {
                    self.errorMessage = err.errorMessages
                } else if resp?.result == true {
                    self.uploadCompleted = true
                    appState.advanceToNextModule()
                } else {
                    self.errorMessage = "Video yuklenemedi"
                }
            }
        }
    }
}
