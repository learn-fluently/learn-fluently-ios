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
import RxSwift
import SwiftRichString

class SpeakingViewController: BaseViewController, NibBasedViewController {
    
    // MARK: Constants
    
    private struct Constants {
        
        static let speakingHint = "[Start speaking ...]"
    }
    
    
    // MARK: Properties
    
    //let speakingConfig = SpeakingConfig()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    // MARK: Properties 
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var playerController: PlayerViewController!
    private var subtitleRepository: SubtitleRepository!
    private var disposeBag = DisposeBag()
    private var currentSubtitle: String? = nil
    private var textLabelTempValue: String? = nil
    private var isRecording: Bool {
        return audioEngine.isRunning
    }
    
    // MARK: Outlets
    
    @IBOutlet private weak var textLabelView: UILabel!
    @IBOutlet private weak var playerContainerView: UIView!
    @IBOutlet private weak var playPauseButton: UIButton!
    @IBOutlet private weak var correctPercentageLabel: UILabel!
    @IBOutlet private weak var recordButton: UIButton!
    @IBOutlet private weak var hintButton: UIButton!
    
    
    // MARK: Lifecyle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        configureRecordButton()
        addPlayerViewControllerAndPlay()
        configureSubtitleRepository()
        subscribeToPlayerTime()
        compareAndShowOrHideResultIfNeeded()
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
    
    @IBAction private func playPauseButtonTouched() {
        playerController.togglePlaying()
    }
    
    @IBAction private func skipNextButtonTouched() {
        let time = subtitleRepository.getStartOfNextSubtitle(currentTime: playerController.playerTime)
        seek(to: time)
    }
    
    @IBAction private func skipPrevButtonTouched() {
        let time = subtitleRepository.getStartOfPrevSubtitle(currentTime: playerController.playerTime)
        seek(to: time)
    }
    
    @IBAction private func recordButtonTouched() {
        if audioEngine.isRunning {
            stopRecording()
            compareAndShowOrHideResultIfNeeded()
        } else {
            startRecordingIfPossible()
        }
    }
    
    @IBAction private func hintButtonTouchedDown() {
        showHint()
    }
    
    @IBAction private func hintButtonTouchedUpOutside() {
        hideHint()
    }
    @IBAction private func hintButtonTouchedUpInside() {
        hideHint()
    }
    
    // MARK: Private functions
    
    private func showHint() {
        playerController.pause()
        stopRecordingIfNeeded()
        textLabelTempValue = textLabelView.text
        textLabelView.attributedText = currentSubtitle?.set(style: Style.subtitleTextStyle)
    }
    
    private func hideHint() {
        if let tempValue = textLabelTempValue {
            textLabelView.attributedText = tempValue.set(style: Style.subtitleTextStyle)
            textLabelTempValue = nil
        }
    }
    
    private func compareAndShowOrHideResultIfNeeded() {
        let currentSubtitleLength = currentSubtitle?.lengthOfBytes(using: .utf8) ?? 0
        
        if textLabelView.text?.lengthOfBytes(using: .utf8) ?? 0 < 1 ||
            currentSubtitleLength < 1 ||
            playerController.isPlaying ||
            isRecording {
            correctPercentageLabel.isHidden = true
            return
        }
        
        let editDifference = currentSubtitle!.levenshtein(textLabelView.text!)
        let correctPerc = Double(currentSubtitleLength - editDifference) / Double(currentSubtitleLength)
        
        correctPercentageLabel.isHidden = false
        correctPercentageLabel.text =  String(format: "%.1f", correctPerc * 100) + "%"
    }
    
    private func seek(to time:Double) {
        playerController.seek(to: time)
        stopRecordingIfNeeded()
        playerController.play()
    }
    
    private func subscribeToPlayerTime() {
        playerController.playerTimeObservable.subscribe(onNext: { [weak self] currentValue in
            self?.adjustCurrentSubtitle(currentValue: currentValue)
            self?.pausePlayerAndStartRecordingIfNeeded(currentValue: currentValue)
        }).disposed(by: disposeBag)
    }
    
    private func adjustCurrentSubtitle(currentValue: Double) {
        if let subtitle = self.subtitleRepository.getSubtitleForTime(currentValue) {
            self.currentSubtitle = subtitle
        }
    }
    
    private func pausePlayerAndStartRecordingIfNeeded(currentValue: Double) {
        if  playerController.isPlaying,
            subtitleRepository.isTimeCloseToEndOfSubtitle(currentValue) {
            
            playerController.pause()
            startRecordingIfPossible()
        }
    }
    
    private func startRecordingIfPossible() {
        guard recordButton.isEnabled else {
            return
        }
        do {
            try startRecording()
            recordButton.setImage(#imageLiteral(resourceName: "Recording"), for: [])
            playPauseButton.isEnabled = false
            playerController.showsPlaybackControls = false
        } catch {
            showAlert("Recording Not Available")
        }
    }
    
    private func stopRecordingIfNeeded() {
        if isRecording {
            stopRecording()
        }
    }
    
    private func stopRecording() {
        if textLabelView.text == Constants.speakingHint {
            textLabelView.text = ""
        }
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recordButton.isEnabled = false
        playPauseButton.isEnabled = true
        playerController.showsPlaybackControls = true
    }
    
    private func addPlayerViewControllerAndPlay(){
        let url: URL = Bundle.main.url(forResource: "movie", withExtension: "mp4")!
        
        playerController = PlayerViewController()
        playerController.playingDelegate = self
        addChild(playerController)
        guard let videoView = playerController?.view else { return }
        playerContainerView.insertSubview(videoView, at: 0)
        playerController.didMove(toParent: self)
        
        playerController.url = url
        playerController.play()
    }
    
    private func configureRecordButton() {
        // Disable the record buttons until authorization has been granted.
        recordButton.isEnabled = false
    }
    
    private func configureSubtitleRepository(){
        let url = Bundle.main.url(forResource: "subtitle", withExtension: "srt")
        subtitleRepository = SubtitleRepository(url: url!)
    }
    
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
                self.textLabelView.attributedText = result.bestTranscription.formattedString.set(style: Style.subtitleTextStyle)
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
        textLabelView.text = Constants.speakingHint
    }
    
    private func showAlert(_ message:String, error: Bool = true) {
        presentOKMessage(title: error ? "Error" : "", message: message)
    }
    
}


extension SpeakingViewController: PlayerViewControllerPlayingDelegate {
    
    // MARK: Functions
    
    func onPlayingStateChanged(playerViewController: PlayerViewController) {
        let image = playerViewController.isPlaying ? #imageLiteral(resourceName: "Pause") : #imageLiteral(resourceName: "Play")
        playPauseButton.setImage(image, for: .normal)
        compareAndShowOrHideResultIfNeeded()
        recordButton.isEnabled = !playerViewController.isPlaying
    }
    
    func onCloseButtonTouched(playerViewController: PlayerViewController) {
        dismiss(animated: true, completion: nil)
    }
}


extension SpeakingViewController: SFSpeechRecognizerDelegate {
    
    // MARK: Functions
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            recordButton.isEnabled = true
            recordButton.setImage(#imageLiteral(resourceName: "Record"), for: [])
        } else {
            recordButton.isEnabled = false
            showAlert("Recognition Not Available")
        }
    }
}
