//
//  SpeechRecognizerService.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 2/16/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import AVFoundation
import Speech
import RxCocoa
import RxSwift

protocol SpeechRecognizerRecordingDelegate: AnyObject {

    // MARK: Functions

    func onRecordingStateChanged(isRecording: Bool)

}


class SpeechRecognizerService: SFSpeechRecognizer {

    // MARK: Constants

    private struct Constants {
        static let bufferSize: UInt32 = 1_024
        static let stopRecordingAfterInactivityForSeconds: Double = 2.5
    }


    // MARK: Properties

    weak var recordingDelegate: SpeechRecognizerRecordingDelegate?

    var isRecording: Bool {
        return audioEngine.isRunning
    }

    var bestTranscriptionObservable: Observable<String?> {
        return bestTranscriptionBehaviorRelay.asObservable()
    }

    var bestTranscription: String? {
        return bestTranscriptionBehaviorRelay.value
    }

    private var autoStopAtEndOfDetection: Bool = true
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine!
    private var audioDetectionTimer: Timer?
    private var bestTranscriptionBehaviorRelay = BehaviorRelay<String?>(value: nil)


    // MARK: Life cycle

    override init?(locale: Locale) {
        super.init(locale: locale)
        audioEngine = AVAudioEngine()
        try? configureAudioSession()
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

                default:
                    completion?(false, nil)
                }
            }

        }
    }


    func startRecognition() throws {
        guard !isRecording else {
            return
        }
        try startRecording()
    }


    func stopRecognitionTaskIfNeeded(cancel: Bool = false) {
        guard isRecording else {
            return
        }
        stopRecognitionTask(cancel: cancel)
    }


    // MARK: Private functions

    private func startRecording() throws {

        let inputNode = audioEngine.inputNode

        // Cancel the previous task if it's running.
        if recognitionTask != nil {
            stopRecognitionTask(cancel: true)
        }

        // Create and configure the speech recognition request.
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object")
        }
        recognitionRequest.shouldReportPartialResults = true

        // Create a recognition task for the speech recognition session.
        // Keep a reference to the task so that it can be canceled.
        recognitionTask = recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let `self` = self else {
                return
            }

            if let result = result, self.isRecording {
                self.bestTranscriptionBehaviorRelay.accept(result.bestTranscription.formattedString)
            }

            if let error = error {
                if self.bestTranscription != nil {
                    self.bestTranscriptionBehaviorRelay.accept(nil)
                }
                print(error)
            } else if result?.isFinal == false {
                if let timer = self.audioDetectionTimer, timer.isValid {
                    timer.invalidate()
                }
                if self.autoStopAtEndOfDetection {
                    self.audioDetectionTimer = Timer.scheduledTimer(
                        withTimeInterval: Constants.stopRecordingAfterInactivityForSeconds,
                        repeats: false) { timer in
                            if self.isRecording, self.bestTranscriptionBehaviorRelay.value != nil {
                                self.stopRecognitionTask(cancel: false)
                            }
                            timer.invalidate()
                    }
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
        DispatchQueue.main.async {
            self.bestTranscriptionBehaviorRelay.accept(nil)
            self.recordingDelegate?.onRecordingStateChanged(isRecording: true)
        }
    }

    private func configureAudioSession() throws {
        // Configure the audio session for the app.
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
        try audioSession.setActive(true)
    }

    private func stopRecognitionTask(cancel: Bool = false) {
        if let timer = self.audioDetectionTimer, timer.isValid {
            timer.invalidate()
        }

        recognitionRequest?.endAudio()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest = nil

        if !cancel, recognitionTask?.isFinishing != true {
            recognitionTask?.finish()
        } else if cancel {
            recognitionTask?.cancel()
        }

        recognitionTask = nil
        recordingDelegate?.onRecordingStateChanged(isRecording: false)
    }

}
