//
//  SpeechRecViewModel.swift
//  NewTest
//
//  Konusma tanima ekraninin ViewModel'i.
//  SFSpeechRecognizer ile kayit, metin karsilastirma, SDK bildirimi.
//  SDK: sendSpeechStatus(isCompleted:)
//

import Foundation
import Speech
import AVFoundation
import IdentifySDK

@MainActor
final class SpeechRecViewModel: BaseModuleViewModel {

    // MARK: - Published State

    /// Kullanicinin soymesi gereken kelime (SDK tarafindan belirlenir)
    @Published private(set) var targetWord: String = "Berlin"

    /// Kayit devam ediyor mu
    @Published private(set) var isRecording: Bool = false

    /// Tanima sonucu
    @Published private(set) var recognizedText: String = ""

    /// Basari durumu
    @Published private(set) var speechSuccess: Bool = false

    // MARK: - Private

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    // MARK: - Init

    override init() {
        super.init()
        setupSpeechRecognizer()
    }

    private func setupSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "tr-TR"))
    }

    // MARK: - Kayit Baslat / Durdur

    func startRecording() {
        guard !isRecording else { return }
        recognizedText = ""
        speechSuccess = false
        errorMessage = nil

        // 1. Önce audio session'ı aktif et — format sorgusu ve engine start buna bağlı.
        // .defaultToSpeaker sadece .playAndRecord ile geçerlidir; .record ile -50 verir.
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        isRecording = true

        let request = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest = request
        request.shouldReportPartialResults = true

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.recognizedText = result.bestTranscription.formattedString
                }
                if result?.isFinal == true {
                    self.recognitionTask = nil
                    self.recognitionRequest = nil
                    self.checkResult()
                } else if error != nil {
                    self.recognitionTask = nil
                    self.recognitionRequest = nil
                    if !self.recognizedText.isEmpty {
                        self.checkResult()
                    }
                }
            }
        }

        // 2. Session aktifken format al, tap kur, engine başlat.
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            errorMessage = error.localizedDescription
            stopRecording()
        }
    }

    func stopRecording() {
        // guard: çift çağrıyı önle (tap zaten kaldırılmışsa "operation error" verir)
        guard isRecording else { return }
        isRecording = false
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        // endAudio: kalan ses tamponunu tanıyıcıya gönderir, isFinal ile tamamlanır.
        // cancel() çağrılmıyor — legacy SDKSpeechRecViewController ile aynı yaklaşım.
        recognitionRequest?.endAudio()
    }

    // MARK: - Sonuc Kontrolu

    private func checkResult() {
        let matched = recognizedText.lowercased().contains(targetWord.lowercased())
        if matched {
            speechSuccess = true
        } else {
            errorMessage = "'\(targetWord)' soylenmedi, tekrar deneyin"
        }
    }

    // MARK: - SDK Bildirimi

    func confirmSpeech(appState: AppStateViewModel) {
        manager.sendSpeechStatus(isCompleted: true)
        appState.advanceToNextModule()
    }
}
