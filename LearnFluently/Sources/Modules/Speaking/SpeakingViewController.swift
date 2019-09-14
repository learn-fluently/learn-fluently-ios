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
import RxCocoa
import SwiftRichString

class SpeakingViewController: InputViewController<SpeakingViewModel>, NibBasedViewController {

    // MARK: Properties

    override var isInputBusy: Bool {
        return viewModel.isRecording
    }

    private var autoStartRecordingForNext = true
    private var isInputAllowed = false

    @IBOutlet private weak var textLabelView: UILabel!
    @IBOutlet private weak var recordButton: UIButton!


    // MARK: Lifecycle

    init(viewModel: SpeakingViewModel, delegate: InputViewControllerDelegate) {
        super.init(viewModel: viewModel, delegate: delegate, nibName: type(of: self).nibName)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not available")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.configureSpeechRecognizerService { [weak self] error in
            self?.showAlert(error)
        }
        subsribeToDescTextObservables()
        subsribeToisRecordingObservable()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.requestAuthorization()
            .subscribe(
                onSuccess: { [weak self] isAuthorized in
                    self?.recordButton.isHidden = !isAuthorized
                    if isAuthorized {
                        self?.configureSubtitleRepositoryAndThenPlay()
                    }
                },
                onError: { [weak self] error in
                    self?.showAlert(error.localizedDescription)
                }
            )
            .disposed(by: disposeBag)
    }


    // MARK: - Event handlers

    @IBAction private func recordButtonTouched() {
        if !isInputAllowed {
            return
        }
        if viewModel.isRecording {
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

    internal override func seek(to time: Double?) {
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
        isInputAllowed = isAllowed
        if !isAllowed {
            textLabelView.text = ""
        }
    }


    // MARK: Private functions

    private func subsribeToDescTextObservables() {
        viewModel.descriptionTextObservable
            .subscribe(onNext: { [weak self] text in
                self?.textLabelView.setText(text, style: .subtitleTextStyle)
            })
            .disposed(by: disposeBag)
    }

    private func subsribeToisRecordingObservable() {
        viewModel.isRecordingObservable
            .subscribe(onNext: { [weak self] isRecording in
                guard let self = self else {
                    return
                }
                self.adjustResultViewIfNeeded(input: self.viewModel.bestTranscription)
                self.showsPlaybackControls = !isRecording
                self.recordButton.setImage(isRecording ? #imageLiteral(resourceName: "Recording") : #imageLiteral(resourceName: "Record"), for: .normal)
            })
            .disposed(by: disposeBag)
    }

    private func startRecordingIfPossible() {
        guard viewModel.isRecordingPossible else {
            return
        }
        do {
            try viewModel.startRecognition()
        } catch {
            showAlert("Recording Not Available")
        }
    }

    private func stopRecordingIfNeeded(shouldKeepResult: Bool = true) {
        if viewModel.isRecording {
            stopRecording(shouldKeepResult: shouldKeepResult)
        }
    }

    private func stopRecording(shouldKeepResult: Bool = true) {
        viewModel.stopRecognitionTaskIfNeeded(keepResult: shouldKeepResult)
    }

}
