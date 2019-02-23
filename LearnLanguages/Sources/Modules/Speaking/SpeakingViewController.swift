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
        static let autoGoToTheNextWithPercentage = 90
        static let autoGoToTheNextDelay: Double = 2
    }


    // MARK: Properties

    //let speakingConfig = SpeakingConfig()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }


    // MARK: Properties

    // TODO: set language
    private let speechRecognizer = SpeechRecognizerService(locale: Locale(identifier: "en-UK"))!
    private var playerController: PlayerViewController!
    private var subtitleRepository: SubtitleRepository!
    private var fileRepository: FileRepository!
    private var disposeBag = DisposeBag()
    private var currentSubtitle: String?
    private var textLabelTempValue: String?
    private var autoStartRecordingForNext = true
    private var autoStopRecording = true
    private var audioDetectionTimer: Timer?

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
        fileRepository = FileRepository()

        speechRecognizer.delegate = self
        try? speechRecognizer.configureAudioSession()

        configureRecordButton()
        addPlayerViewControllerAndPlay()
        configureSubtitleRepository()
        subscribeToPlayerTime()
        adjustResultViewIfNeeded()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        speechRecognizer.requestAuthorization { [weak self] isAuthorized, errorDescription in
            self?.recordButton.isEnabled = isAuthorized
            if let error = errorDescription {
                self?.showAlert(error)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        playerController.pause()
    }


    // MARK: - Event handlers

    @IBAction private func playPauseButtonTouched() {
        stopRecordingIfNeeded(shouldKeepResult: false)
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
        if speechRecognizer.isRecording {
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
        stopRecordingIfNeeded(shouldKeepResult: false)
        subtitleRepository.cleanLastStop()
        playerController.seek(to: time)
        playerController.play()
    }

    private func adjustResultViewIfNeeded() {
        let currentSubtitleLength = currentSubtitle?.lengthOfBytes(using: .utf8) ?? 0

        if speechRecognizer.lastBestTranscription?.lengthOfBytes(using: .utf8) ?? 0 < 1 ||
            currentSubtitleLength < 1 ||
            playerController.isPlaying ||
            speechRecognizer.isRecording {
            correctPercentageLabel.isHidden = true
            return
        }

        let originalText = normalizeTextForComparesion(currentSubtitle!)
        let speachText = normalizeTextForComparesion(speechRecognizer.lastBestTranscription!)

        let editDifference = originalText.levenshtein(speachText)
        let beingCorrectRate = Double(currentSubtitleLength - editDifference) / Double(currentSubtitleLength)

        correctPercentageLabel.isHidden = false
        var color: UIColor = .red
        if beingCorrectRate > 0.5 {
            color = .orange
        }
        if beingCorrectRate > 0.85 {
            color = .green
        }
        let style = Style.beCorrectPercentage(color: color)
        let beingCorrectPercentage = Int(beingCorrectRate * 100)
        correctPercentageLabel.attributedText = (String(format: "%d", beingCorrectPercentage) + "%").set(style: style)

        // auto play
        if beingCorrectPercentage >= Constants.autoGoToTheNextWithPercentage {
            view.isUserInteractionEnabled = false
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.autoGoToTheNextDelay) { [weak self] in
                self?.view.isUserInteractionEnabled = true
                self?.playerController.play()
            }
        }
    }

    private func normalizeTextForComparesion(_ text: String) -> String {
        let filteredCharacters = text.lowercased().filter {
            String($0).rangeOfCharacter(from: NSCharacterSet.lowercaseLetters) != nil ||
                String($0).rangeOfCharacter(from: NSCharacterSet.decimalDigits) != nil
        }
        return String(filteredCharacters)
    }

    private func seek(to time: Double) {
        playerController.seek(to: time)
        stopRecordingIfNeeded(shouldKeepResult: false)
        playerController.play()
    }

    private func subscribeToPlayerTime() {
        playerController.playerTimeObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] currentValue in
                self?.adjustCurrentSubtitle(currentValue: currentValue)
                self?.pausePlayerAndStartRecordingIfNeeded(currentValue: currentValue)
            })
            .disposed(by: disposeBag)
    }

    private func adjustCurrentSubtitle(currentValue: Double) {
        if let subtitle = self.subtitleRepository.getSubtitleForTime(currentValue) {
            self.currentSubtitle = subtitle
        }
    }

    private func addPlayerViewControllerAndPlay() {
        playerController = PlayerViewController()
        playerController.playingDelegate = self
        addChild(playerController)
        guard let videoView = playerController?.view else { return }
        playerContainerView.insertSubview(videoView, at: 0)
        playerController.didMove(toParent: self)

        playerController.url = fileRepository.getPathURL(for: .videoFile)
        playerController.play()
    }

    private func configureRecordButton() {
        // Disable the record buttons until authorization has been granted.
        recordButton.isEnabled = false
    }

    private func configureSubtitleRepository() {
        let url = fileRepository.getPathURL(for: .subtitleFile)
        subtitleRepository = SubtitleRepository(url: url)
    }

    private func updateTextLabelView(_ text: String?) {
        textLabelView.attributedText = (text ?? "").set(style: Style.subtitleTextStyle)
    }

    private func showAlert(_ message: String, error: Bool = true) {
        presentOKMessage(title: error ? .ERROR : "", message: message)
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

    private func stopRecordingIfNeeded(shouldKeepResult: Bool = true) {
        if speechRecognizer.isRecording {
            stopRecording(shouldKeepResult: shouldKeepResult)
        }
    }

    private func stopRecording(shouldKeepResult: Bool = true) {
        speechRecognizer.stopRecognitionTaskIfNeeded(cancel: !shouldKeepResult)
        if speechRecognizer.lastBestTranscription == nil {
            updateTextLabelView(nil)
        }
        onRecordingStoped()
    }

    private func startRecording() throws {
        try speechRecognizer.startRecording(onTranscriptionChanged: { [weak self] result in
            self?.updateTextLabelView(result)
            }, onStart: { [weak self] in
                self?.updateTextLabelView(Constants.speakingHint)
                self?.adjustResultViewIfNeeded()
            }, onAutoStoped: { [weak self] in
                self?.onRecordingStoped()
        })
    }

    private func onRecordingStoped() {
        recordButton.isEnabled = true
        playerController.showsPlaybackControls = true
        recordButton.setImage(#imageLiteral(resourceName: "Record"), for: [])
        adjustResultViewIfNeeded()
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
