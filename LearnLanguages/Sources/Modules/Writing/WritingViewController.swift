//
//  WritingViewController.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 3/2/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import Speech
import RxSwift
import SwiftRichString

class WritingViewController: InputViewController, NibBasedViewController {
//
//    // MARK: Constants
//
//    private struct Constants {
//
//        static let speakingHint = "[Start typing ...]"
//        static let autoGoToTheNextWithPercentage = 90
//        static let autoGoToTheNextDelay: Double = 2
//    }
//
//
//    // MARK: Properties
//
//    override var preferredStatusBarStyle: UIStatusBarStyle {
//        return .lightContent
//    }
//
//    private var playerController: PlayerViewController!
//    private var subtitleRepository: SubtitleRepository!
//    private var fileRepository: FileRepository!
//    private var disposeBag = DisposeBag()
//    private var currentSubtitle: String?
//    private var typingIsAllowed: Bool = false
//
//
//    // MARK: Outlets
//
//    @IBOutlet private weak var subtitleLabelView: UILabel!
//    @IBOutlet private weak var inputTextView: UITextView!
//    @IBOutlet private weak var playerContainerView: UIView!
//    @IBOutlet private weak var playPauseButton: UIButton!
//    @IBOutlet private weak var correctPercentageLabel: UILabel!
//    @IBOutlet private weak var doneButton: UIButton!
//    @IBOutlet private weak var hintButton: UIButton!
//    @IBOutlet private weak var replayButton: UIButton!
//
//
//    // MARK: Lifecyle
//
//    public override func viewDidLoad() {
//        super.viewDidLoad()
//        fileRepository = FileRepository()
//
//        configureSpeechRecognizerService()
//        configureRecordButton()
//        addPlayerViewController()
//        subscribeToPlayerTime()
//        adjustResultViewIfNeeded()
//        configureSubtitleRepositoryAndThenPlay()
//    }
//
//    override public func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//
//    }
//
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        playerController.pause()
//    }
//
//
//    // MARK: - Event handlers
//
//    @IBAction private func playPauseButtonTouched() {
//        playerController.togglePlaying()
//    }
//
//    @IBAction private func skipNextButtonTouched() {
//        let time = subtitleRepository.getStartOfNextSubtitle(currentTime: playerController.playerTime)
//        seek(to: time)
//    }
//
//    @IBAction private func skipPrevButtonTouched() {
//        let time = subtitleRepository.getStartOfPrevSubtitle(currentTime: playerController.playerTime)
//        seek(to: time)
//    }
//
//    @IBAction private func doneButtonTouched() {
//
//    }
//
//    @IBAction private func hintButtonTouchedDown() {
//        showHint()
//    }
//
//    @IBAction private func hintButtonTouchedUpOutside() {
//        hideHint()
//    }
//
//    @IBAction private func hintButtonTouchedUpInside() {
//        hideHint()
//    }
//
//    @IBAction private func onReplayButtonTouched() {
//        replay()
//    }
//
//
//    // MARK: Private functions
//
//    private func seek(to time: Double) {
//        playerController.seek(to: time)
//        playerController.play()
//    }
//
//    private func showHint() {
//        playerController.pause()
//        stopRecordingIfNeeded()
//        textLabelTempValue = textLabelView.text
//        updateTextLabelView(currentSubtitle)
//    }
//
//    private func hideHint() {
//        if let tempValue = textLabelTempValue {
//            updateTextLabelView(tempValue)
//            textLabelTempValue = nil
//        }
//    }
//
//    private func replay() {
//        guard !playerController.isPlaying,
//            let time = subtitleRepository.getStartOfCurrentSubtitle() else {
//                return
//        }
//        autoStartRecordingForNext = false
//        stopRecordingIfNeeded(shouldKeepResult: false)
//        subtitleRepository.cleanLastStop()
//        playerController.seek(to: time)
//        playerController.play()
//    }
}
