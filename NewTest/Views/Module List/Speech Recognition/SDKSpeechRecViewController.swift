//
//  SDKSpeechRecViewController.swift
//  NewTest
//
//  Created by Emir Beytekin on 17.11.2022.
//

import UIKit
import Speech

class SDKSpeechRecViewController: SDKBaseViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var errorLbl: UILabel!
    @IBOutlet weak var circleBtnView: UIView!
    @IBOutlet weak var micImg: UIImageView!
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "tr-TR"))
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    var onBreakToppedButton = false
    @IBOutlet weak var continueBtn: IdentifyButton!
    @IBOutlet weak var infoLbl: UILabel!
    var correctTitle = "Berlin"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkSpeechPermission()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.resetCache()
    }
    
    private func resetCache() {
        setupUI()
        self.circleBtnView.isHidden = false
        self.circleBtnView.alpha = 1
    }
    
    private func setupUI() {
        speechRequest()
        self.errorLbl.text = ""
        self.infoLbl.text = self.translate(text: .coreCityDesc)
        self.micImg.tintColor = IdentifyTheme.orangeColor
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(buttonPressed))
        recognizer.minimumPressDuration = 0.0;
        recognizer.delegate = self;
        circleBtnView.addGestureRecognizer(recognizer)
        
        continueBtn.isHidden = true
        continueBtn.setTitle(self.translate(text: .continuePage), for: .normal)
        continueBtn.type = .submit
        continueBtn.onTap = {
            self.manager.getNextModule { nextVC in
                self.navigationController?.pushViewController(nextVC, animated: true)
            }
        }
        continueBtn.populate()
    }
    
    @objc func buttonPressed(rec: UILongPressGestureRecognizer)  {
        switch rec.state {
        case .began:
            UIView.animate(withDuration: 0.3) {
                self.circleBtnView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
                self.micImg.tintColor = .red
            }
            self.onBreakToppedButton = false
            self.startRecording()
            break
        case .ended:
            UIView.animate(withDuration: 0.3) {
                self.circleBtnView.transform = CGAffineTransformIdentity
                self.micImg.tintColor = IdentifyTheme.orangeColor
            }
            self.onBreakToppedButton = true
            self.stopRecordSession()
            break
        default:
            return
        }
    }

}

extension SDKSpeechRecViewController {
    
    func speechRequest() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            SFSpeechRecognizer.requestAuthorization { status in
                print("speech status: \(status)")
            }
        }
    }
    
    func setupContinueBtn() {
        UIView.animate(withDuration: 0.3, delay: 0.0, options: [.curveEaseIn], animations: {
            self.circleBtnView.alpha = 0
        }, completion: { (finished: Bool) in
            self.manager.sendSpeechStatus(isCompleted: true)
            self.continueBtn.isHidden = false
        })
    }
    
    func stopRecordSession(_ completed: Bool? = false) {
        self.audioEngine.stop()
        self.recognitionRequest?.endAudio()
    }
    
    func startRecording() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.default, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

            let inputNode = audioEngine.inputNode

            guard let recognitionRequest = recognitionRequest else {
                return
            }

            recognitionRequest.shouldReportPartialResults = true

            self.recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
                var isFinal = false
                if result != nil && self.onBreakToppedButton {
                    isFinal = result?.isFinal ?? false
                    DispatchQueue.main.async {
                        self.updateUI(withResult: result!)
                        return
                    }
                }
                if error != nil || isFinal {
                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                    self.recognitionRequest = nil
                    self.recognitionTask = nil
                }
            })

            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
                self.recognitionRequest?.append(buffer)
            }

            self.audioEngine.prepare()

            do {
                try self.audioEngine.start()
            } catch let err {
                print(err.localizedDescription)
                print("audioEngine couldn't start because of an error.")
            }
            
        } catch let err {
            print(err.localizedDescription)
            print("audioSession properties weren't set because of an error.")
        }
        
    }
    
    private func updateUI(withResult result: SFSpeechRecognitionResult) {
        if onBreakToppedButton {
            let resultText = result.bestTranscription.formattedString
            if resultText == self.correctTitle {
                self.errorLbl.text = ""
                self.manager.speechCompleted()
                if audioEngine.isRunning {
                    stopRecordSession(true)
                }
                self.setupContinueBtn()
            } else {
                if audioEngine.isRunning {
                    stopRecordSession()
                }
                self.errorLbl.text = "Hatalı kelime söylediniz, okuduğunuz kelime: \(resultText)"
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    self.onBreakToppedButton = false
                })
            }
        }
    }
    
}
