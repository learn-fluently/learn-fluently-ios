//
//  SpeakingViewController.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 2/3/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import AVKit
import Speech

class SpeakingViewController: BaseViewController, NibBasedViewController, SFSpeechRecognizerDelegate {

    // MARK: Properties
    
//    private let player: AVPlayer!
//    private let playerController: AVPlayerViewController!
//    private let subtitles: Subtitles!
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    // MARK: Outlets
    
    @IBOutlet private weak var textLabelView: UILabel!
    @IBOutlet private weak var playerContainerView: UIView!
    @IBOutlet private weak var playPauseButton: UIButton!
    @IBOutlet private weak var correctPercentageLabel: UILabel!
    @IBOutlet private weak var recordButton: UIButton!
    @IBOutlet private weak var hintButton: UIButton!
    
    
    // MARK: - ViewController
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Disable the record buttons until authorization has been granted.
        recordButton.isEnabled = false
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Configure the SFSpeechRecognizer object already
        // stored in a local member variable.
        speechRecognizer.delegate = self
        
        // Make the authorization request.
        SFSpeechRecognizer.requestAuthorization { authStatus in
            
            // Divert to the app's main thread so that the UI
            // can be updated.
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.recordButton.isEnabled = true
                    
                case .denied:
                    self.recordButton.isEnabled = false
                    self.showAlert("User denied access to speech recognition")
                    
                case .restricted:
                    self.recordButton.isEnabled = false
                    self.showAlert("Speech recognition restricted on this device")
                    
                case .notDetermined:
                    self.recordButton.isEnabled = false
                    self.showAlert("Speech recognition not yet authorized")
                }
            }
        }
    }
    
    
    // MARK: - Event handlers
    
    @IBAction private func closeButtonTouched() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func playPauseButtonTouched() {
//        if player.timeControlStatus == .playing {
//            player.pause()
//        } else if player.timeControlStatus == .paused {
//            player.play()
//        }
    }
    
    @IBAction private func skipNextButtonTouched() {
       // changeSeekTime(value: 5.0)
    }
    
    @IBAction private func skipPrevButtonTouched() {
      //  changeSeekTime(value: -5.0)
    }
    
    @IBAction private func recordButtonTouched() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recordButton.isEnabled = false
        } else {
            do {
                try startRecording()
                recordButton.setImage(#imageLiteral(resourceName: "Recording"), for: [])
            } catch {
                showAlert("Recording Not Available")
            }
        }
    }
    
    
    // MARK: Private functions
    
    private func startRecording() throws {
        
        // Cancel the previous task if it's running.
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        // Configure the audio session for the app.
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let inputNode = audioEngine.inputNode
        
        // Create and configure the speech recognition request.
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        recognitionRequest.shouldReportPartialResults = true
        
        // Create a recognition task for the speech recognition session.
        // Keep a reference to the task so that it can be canceled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                // Update the text view with the results.
                self.textLabelView.text = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                // Stop recognizing speech if there is a problem.
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.recordButton.isEnabled = true
                self.recordButton.setImage(#imageLiteral(resourceName: "Record"), for: [])
            }
        }
        
        // Configure the microphone input.
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        // Let the user know to start talking.
        textLabelView.text = "[Start speaking ...]"
    }
    
    private func showAlert(_ message:String, error: Bool = true) {
        presentOKMessage(title: error ? "Error" : "", message: message)
    }
    
    
    // MARK: SFSpeechRecognizerDelegate
    
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            recordButton.isEnabled = true
            recordButton.setImage(#imageLiteral(resourceName: "Record"), for: [])
        } else {
            recordButton.isEnabled = false
            showAlert("Recognition Not Available")
        }
    }
    
}
