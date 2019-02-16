//
//  SpeechRecognizer.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 2/16/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import AVFoundation
import Speech

class SpeechRecognizer: SFSpeechRecognizer {

    // MARK: Constants

    private struct Constants {
        static let bufferSize: UInt32 = 1024
        static let stopRecordingAfterInactivityForSeconds: Double = 2.5
    }


    // MARK: Properties

    var isRecording: Bool {
        return audioEngine.isRunning
    }

    var autoStopAtEndOfDetection: Bool = true

    private(set) var lastBestTranscription: String?

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine!
    private var audioDetectionTimer: Timer?


    // MARK: Life cycle

    override init?(locale: Locale) {
        super.init(locale: locale)
        audioEngine = AVAudioEngine()
    }


    // MARK: Public functions

    func requestAuthorization(completion: ((Bool, String?) -> Void)?) {

        // Make the authorization request.
        SFSpeechRecognizer.requestAuthorization { authStatus in

            // Divert to the app's main thread so that the UI
            // can be updated.
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    completion?(true, nil)

                case .denied:
                    completion?(false, "User denied access to speech recognition")

                case .restricted:
                    completion?(false, "Speech recognition restricted on this device")

                case .notDetermined:
                    completion?(false, "Speech recognition not yet authorized")
                }
            }

        }
    }

    func configureAudioSession() throws {

        // Configure the audio session for the app.
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
        try audioSession.setActive(true)
    }

    func startRecording(onTranscriptionChanged: ((String?) -> Void)? = nil,
                        onStart:(() -> Void)? = nil,
                        onAutoStoped:(() -> Void)? = nil) throws {

        let inputNode = audioEngine.inputNode

        // Cancel the previous task if it's running.
        if let recognitionTask = recognitionTask {
            audioEngine.stop()
            inputNode.removeTap(onBus: 0)
            recognitionTask.cancel()
            recognitionRequest = nil
            self.recognitionTask = nil
        }


        // Create and configure the speech recognition request.
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        recognitionRequest.shouldReportPartialResults = true

        // Create a recognition task for the speech recognition session.
        // Keep a reference to the task so that it can be canceled.

        recognitionTask = recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let `self` = self else {
                return
            }

            var isFinal = false

            if let result = result {
                self.lastBestTranscription = result.bestTranscription.formattedString
                onTranscriptionChanged?(self.lastBestTranscription)
                isFinal = result.isFinal
            }

            if error != nil || isFinal {
                self.stopRecognitionTask()
            } else {
                if let timer = self.audioDetectionTimer, timer.isValid {
                    timer.invalidate()
                }
                if self.autoStopAtEndOfDetection {
                    self.audioDetectionTimer = Timer.scheduledTimer(withTimeInterval: Constants.stopRecordingAfterInactivityForSeconds, repeats: false, block: { (timer) in
                        if !isFinal && self.lastBestTranscription != nil {
                            if self.isRecording {
                                self.stopRecognitionTask(cancel: false)
                                onAutoStoped?()
                            }
                        }
                        timer.invalidate()
                    })
                }
            }
        }

        // Configure the microphone input.
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: Constants.bufferSize, format: recordingFormat) { (buffer: AVAudioPCMBuffer, _) in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        lastBestTranscription = nil
        onStart?()
    }

    func stopRecognitionTaskIfNeeded(cancel: Bool = false) {
        guard isRecording else {
            return
        }
        stopRecognitionTask(cancel: cancel)
    }

    func stopRecognitionTask(cancel: Bool = false) {
        if let timer = self.audioDetectionTimer, timer.isValid {
            timer.invalidate()
        }

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        recognitionRequest = nil
        if !cancel, recognitionTask?.isFinishing != true {
            recognitionTask?.finish()
            recognitionTask = nil
        } else if cancel {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
    }

}
