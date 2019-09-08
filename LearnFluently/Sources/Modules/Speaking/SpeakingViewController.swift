//
//  SpeakingViewController.swift
//  Learn Fluently
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

class SpeakingViewController: InputViewController, NibBasedViewController {

    // MARK: Properties

    private let speechRecognizer = SpeechRecognizerService(locale: Locale(identifier: UserDefaultsService.shared.learingLanguageCode))!
    private var autoStartRecordingForNext = true

    override var isInputBusy: Bool {
        return speechRecognizer.isRecording
    }

    @IBOutlet private weak var textLabelView: UILabel!
    @IBOutlet private weak var recordButton: UIButton!


    // MARK: Lifecycle

    init(delegate: InputViewControllerDelegate) {
        super.init(nibName: type(of: self).nibName, bundle: nil)
        self.delegate = delegate
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not available")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        configureSpeechRecognizerService()
        configureRecordButton()
        adjustResultViewIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        speechRecognizer.requestAuthorization { [weak self] isAuthorized, errorDescription in
            self?.recordButton.isHidden = !isAuthorized
            if let error = errorDescription {
                self?.showAlert(error)
            }
            if isAuthorized {
                self?.configureSubtitleRepositoryAndThenPlay()
            }
        }
    }


    // MARK: - Event handlers

    @IBAction private func recordButtonTouched() {
        if speechRecognizer.isRecording {
            stopRecording()
        } else {
            startRecordingIfPossible()
        }
    }


    // MARK: Internal functions

    internal override func togglePlayerPlaying() {
        super.togglePlayerPlaying()
        stopRecordingIfNeeded(shouldKeepResult: false)
    }

    internal override func showHint() {
        super.showHint()
        stopRecordingIfNeeded()
        textLabelView.isHidden = true
    }

    internal override func hideHint() {
        super.hideHint()
        textLabelView.isHidden = false
    }

    internal override func replay() {
        super.replay()
        autoStartRecordingForNext = false
        stopRecordingIfNeeded(shouldKeepResult: false)
    }

    internal override func seek(to time: Double) {
        super.seek(to: time)
        stopRecordingIfNeeded(shouldKeepResult: false)
    }

    internal override func onReadyToGetNewInput() {
        if autoStartRecordingForNext {
            startRecordingIfPossible()
        } else {
            autoStartRecordingForNext = true
        }
    }

    internal override func onInputAllowedChanged(isAllowed: Bool) {
        recordButton.isEnabled = isAllowed
        if !isAllowed {
            textLabelView.text = ""
        }
    }


    // MARK: Private functions

    private func configureRecordButton() {
        // Disable the record buttons until authorization has been granted.
        recordButton.isEnabled = false
    }

    private func configureSpeechRecognizerService() {
        speechRecognizer.delegate = self
        speechRecognizer.recordingDelegate = self
        speechRecognizer.bestTranscriptionObservable
            .subscribe(onNext: { [weak self] value in
                self?.updateTextLabelView(value)
            })
            .disposed(by: self.disposeBag)
    }

    private func startRecordingIfPossible() {
        guard recordButton.isEnabled else {
            return
        }
        do {
            try speechRecognizer.startRecognition()
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
    }

    private func updateTextLabelView(_ text: String?) {
        textLabelView.setText(text ?? "", style: .subtitleTextStyle)
    }

}


extension SpeakingViewController: SFSpeechRecognizerDelegate, SpeechRecognizerRecordingDelegate {


    // MARK: Functions

    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if !available {
            recordButton.isHidden = true
            showAlert(.ERROR_RECOGNATION_NOT_AVAILABLE)
        }
    }

    func onRecordingStateChanged(isRecording: Bool) {
        if isRecording {
            updateTextLabelView(.START_SPEAKING_HINT)
        } else if speechRecognizer.bestTranscription == nil {
            updateTextLabelView(nil)
        }

        adjustResultViewIfNeeded(input: speechRecognizer.bestTranscription)
        showsPlaybackControls = !isRecording
        recordButton.setImage(isRecording ? #imageLiteral(resourceName: "Recording") : #imageLiteral(resourceName: "Record"), for: .normal)
    }

}
