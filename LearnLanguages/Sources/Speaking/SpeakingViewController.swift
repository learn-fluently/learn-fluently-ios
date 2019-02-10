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
        static let stopRecordingAfterInactivityForSeconds = 2.5
        static let autoGoToTheNextWithPercentage = 90
        static let autoGoToTheNextDelay: Double = 2
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
    private var autoStartRecordingForNext = true
    private var autoStopRecording = true
    private var audioDetectionTimer: Timer? = nil
    private var lastBestTranscription: String? = nil
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
    @IBOutlet private weak var replayButton: UIButton!
    
    
    // MARK: Lifecyle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        configureRecordButton()
        addPlayerViewControllerAndPlay()
        configureSubtitleRepository()
        subscribeToPlayerTime()
        adjustResultViewIfNeeded()
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
        stopRecordingIfNeeded(keepResult: false)
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
    
    @IBAction private func onReplayButtonTouched() {
        replay()
    }
    
    
    // MARK: Private functions
    
    private func showHint() {
        playerController.pause()
        stopRecordingIfNeeded()
        textLabelTempValue = textLabelView.text
        updateTextLabelView(currentSubtitle)
    }
    
    private func hideHint() {
        if let tempValue = textLabelTempValue {
            updateTextLabelView(tempValue)
            textLabelTempValue = nil
        }
    }
    
    private func replay() {
        guard !playerController.isPlaying,
            let time = subtitleRepository.getStartOfCurrentSubtitle() else {
                return
        }
        autoStartRecordingForNext = false
        stopRecordingIfNeeded(keepResult: false)
        subtitleRepository.cleanLastStop()
        playerController.seek(to: time)
        playerController.play()
    }
    
    private func adjustResultViewIfNeeded() {
        let currentSubtitleLength = currentSubtitle?.lengthOfBytes(using: .utf8) ?? 0
        
        if lastBestTranscription?.lengthOfBytes(using: .utf8) ?? 0 < 1 ||
            currentSubtitleLength < 1 ||
            playerController.isPlaying ||
            isRecording {
            correctPercentageLabel.isHidden = true
            return
        }
        
        let originalText = normalizeTextForComparesion(currentSubtitle!)
        let speachText = normalizeTextForComparesion(lastBestTranscription!)
        
        let editDifference = originalText.levenshtein(speachText)
        let beingCorrectRate = Double(currentSubtitleLength - editDifference) / Double(currentSubtitleLength)
        
        correctPercentageLabel.isHidden = false
        var color:UIColor = .red
        if beingCorrectRate > 0.5 {
            color = .orange
        }
        if beingCorrectRate > 0.85 {
            color = .green
        }
        let style = Style.beCorrectPercentage(color: color)
        let beingCorrectPercentage = Int(beingCorrectRate * 100)
        correctPercentageLabel.attributedText =  (String(format: "%d", beingCorrectPercentage) + "%").set(style: style)
        
        // auto play
        if beingCorrectPercentage >= Constants.autoGoToTheNextWithPercentage {
            view.isUserInteractionEnabled = false
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.autoGoToTheNextDelay) { [weak self] in
                self?.view.isUserInteractionEnabled = true
                self?.playerController.play()
            }
        }
    }
    
    private func normalizeTextForComparesion(_ text:String) -> String {
        let filteredCharacters = text.lowercased().filter {
            return String($0).rangeOfCharacter(from: NSCharacterSet.lowercaseLetters) != nil ||
                String($0).rangeOfCharacter(from: NSCharacterSet.decimalDigits) != nil
        }
        return String(filteredCharacters)
    }
    
    private func seek(to time:Double) {
        playerController.seek(to: time)
        stopRecordingIfNeeded(keepResult: false)
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
            if autoStartRecordingForNext {
                startRecordingIfPossible()
            } else {
                autoStartRecordingForNext = true
            }
        }
    }
    
    private func startRecordingIfPossible() {
        guard recordButton.isEnabled else {
            return
        }
        do {
            try startRecording()
            recordButton.setImage(#imageLiteral(resourceName: "Recording"), for: [])
            playerController.showsPlaybackControls = false
        } catch {
            showAlert("Recording Not Available")
        }
    }
    
    private func stopRecordingIfNeeded(keepResult: Bool = true) {
        if isRecording {
            stopRecording(keepResult: keepResult)
        }
    }
    
    private func stopRecording(keepResult: Bool = true) {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recordButton.isEnabled = false
        playerController.showsPlaybackControls = true
        if !keepResult {
            lastBestTranscription = nil
        }
        if lastBestTranscription == nil {
            updateTextLabelView(nil)
        }
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
    
    private func updateTextLabelView(_ text: String?) {
        textLabelView.attributedText = (text ?? "").set(style: Style.subtitleTextStyle)
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
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let s = self else {
                return
            }
            
            var isFinal = false
            
            if let result = result {
                // Update the text view with the results.
                s.lastBestTranscription = result.bestTranscription.formattedString
                s.updateTextLabelView(s.lastBestTranscription)
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                // Stop recognizing speech if there is a problem.
                s.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                s.recognitionRequest = nil
                s.recognitionTask = nil
                
                s.recordButton.isEnabled = true
                s.recordButton.setImage(#imageLiteral(resourceName: "Record"), for: [])
                s.adjustResultViewIfNeeded()
            } else {
                if let timer = s.audioDetectionTimer, timer.isValid {
                    timer.invalidate()
                }
                s.audioDetectionTimer = Timer.scheduledTimer(withTimeInterval: Constants.stopRecordingAfterInactivityForSeconds, repeats: false, block: { (timer) in
                    if !isFinal && s.lastBestTranscription != nil {
                        s.stopRecordingIfNeeded()
                    }
                    timer.invalidate()
                })
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
        updateTextLabelView(Constants.speakingHint)
        lastBestTranscription = nil
        adjustResultViewIfNeeded()
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
        recordButton.isEnabled = !playerViewController.isPlaying
        if playerViewController.isPlaying {
            updateTextLabelView(nil)
        }
        adjustResultViewIfNeeded()
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