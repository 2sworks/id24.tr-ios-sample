//
//  SpeechHostViewModel.swift
//  NewTest
//
//  Konuşma modülü host VM'i. SDKSpeechRecViewModel'i sarar; kayıt olaylarını loglar.
//

import SwiftUI
import IdentifySDK

@MainActor
final class SpeechHostViewModel: HostModuleViewModel {
    let sdk = SDKSpeechRecViewModel()

    override init() {
        super.init()
        bridge(sdk)
        sdk.onCompleted = { [weak self] in self?.log("speech_completed"); self?.onCompleted?() }
    }

    var targetWord: String { sdk.targetWord }
    var recognizedText: String { sdk.recognizedText }
    var isRecording: Bool { sdk.isRecording }
    var speechSuccess: Bool { sdk.speechSuccess }

    func toggleRecording() {
        if sdk.isRecording { log("stop_recording"); sdk.stopRecording() }
        else { log("start_recording"); sdk.startRecording() }
    }
    func confirm() { log("confirm_speech"); sdk.confirmSpeech() }
}
