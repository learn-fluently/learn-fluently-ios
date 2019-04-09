//
//  InputViewController.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 3/2/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import RxSwift
import SwiftRichString

class InputViewController: BaseViewController {

    // MARK: Properties

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    var showsPlaybackControls: Bool {
        set { playerController.showsControls = newValue }
        get { return playerController.showsControls }
    }

    internal var disposeBag = DisposeBag()

    private(set) var autoGoToTheNextWithPercentage: Int = 90

    private(set) var autoGoToTheNextDelay: Double = 2

    private(set) var isInputBusy: Bool = false

    private var playerController: PlayerViewController!
    private var subtitleRepository: SubtitleRepository!
    private var fileRepository: FileRepository!
    private var currentSubtitle: String?


    // MARK: Outlets

    @IBOutlet private weak var hintLabel: UILabel!
    @IBOutlet private weak var playerContainerView: UIView!
    @IBOutlet private weak var playPauseButton: UIButton!
    @IBOutlet private weak var correctPercentageLabel: UILabel!
    @IBOutlet private weak var hintButton: UIButton!
    @IBOutlet private weak var replayButton: UIButton!


    // MARK: Lifecyle

    public override func viewDidLoad() {
        super.viewDidLoad()
        fileRepository = FileRepository()

        addPlayerViewController()
        subscribeToPlayerTime()
        adjustResultViewIfNeeded()
        configureSubtitleRepositoryAndThenPlay()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        playerController.pause()
    }


    // MARK: Input events

    internal func onInputAllowedChanged(isAllowed: Bool) {
        fatalError("Should implemented in child classes")
    }

    internal func onReadyToGetNewInput() {
        fatalError("Should implemented in child classes")
    }

    internal func inputWrongWordRanges(_ ranges: [NSRange]) {
        // can be implemented in child classes
    }


    // MARK: - Event handlers

    @IBAction private func playPauseButtonTouched() {
        togglePlayerPlaying()
    }

    @IBAction private func skipNextButtonTouched() {
        let time = subtitleRepository.getStartOfNextSubtitle(currentTime: playerController.playerTime)
        seek(to: time)
    }

    @IBAction private func skipPrevButtonTouched() {
        let time = subtitleRepository.getStartOfPrevSubtitle(currentTime: playerController.playerTime)
        seek(to: time)
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


    // MARK: Internal functions

    internal func togglePlayerPlaying() {
        playerController.togglePlaying()
    }

    internal func showHint() {
        playerController.pause()
        let style = Style.subtitleTextStyle
        style.color = view.tintColor
        hintLabel.attributedText = (currentSubtitle ?? "").set(style: style)
        hintLabel.isHidden = false
    }

    internal func hideHint() {
        hintLabel.isHidden = true
    }

    internal func replay() {
        guard !playerController.isPlaying,
            let time = subtitleRepository.getStartOfCurrentSubtitle() else {
                return
        }
        subtitleRepository.cleanLastStop()
        playerController.seek(to: time)
        playerController.play()
    }

    internal func seek(to time: Double) {
        playerController.seek(to: time)
        playerController.play()
    }

    internal func adjustResultViewIfNeeded(input: String? = nil) {
        let currentSubtitleLength = currentSubtitle?.lengthOfBytes(using: .utf8) ?? 0

        if input?.lengthOfBytes(using: .utf8) ?? 0 < 1 ||
            currentSubtitleLength < 1 ||
            playerController.isPlaying ||
            isInputBusy {
            correctPercentageLabel.isHidden = true
            return
        }

        let originalText = normalizeTextForComparesion(currentSubtitle!)
        let inputText = normalizeTextForComparesion(input!)

        let editDifference = originalText.levenshtein(inputText)
        let beingCorrectRate = Double(currentSubtitleLength - editDifference) / Double(currentSubtitleLength)

        correctPercentageLabel.isHidden = false
        var color: UIColor = .red
        if beingCorrectRate > (Double(autoGoToTheNextWithPercentage - 5) / 100.0) {
            color = .green
        } else if beingCorrectRate > 0.5 {
            color = .orange
        }
        let style = Style.beCorrectPercentage(color: color)
        let beingCorrectPercentage = Int(beingCorrectRate * 100)
        correctPercentageLabel.attributedText = (String(format: "%d", beingCorrectPercentage) + "%").set(style: style)

        // auto play
        if beingCorrectPercentage >= autoGoToTheNextWithPercentage {
            onInputAllowedChanged(isAllowed: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + autoGoToTheNextDelay) { [weak self] in
                self?.playerController.play()
            }
        // finding wrong words ranges
        } else {
            var ranges: [NSRange] = []
            let origirnalWords = currentSubtitle!
                .components(separatedBy: " ")
                .map { normalizeTextForComparesion($0) }

            let inputWords = input!.components(separatedBy: " ")
            var location = 0
            if let first = inputWords.first {
                location = input!.range(of: first)?.nsRange.location ?? 0
            }
            inputWords.forEach {
                if $0.lengthOfBytes(using: .utf8) > 1,
                    !origirnalWords.contains(normalizeTextForComparesion($0)) {
                    ranges.append(
                        NSRange(location: location, length: $0.lengthOfBytes(using: .utf8))
                    )
                }
                location += $0.lengthOfBytes(using: .utf8) + 1
            }
            inputWrongWordRanges(ranges)
        }
    }


    // MARK: Private  functions

    private func normalizeTextForComparesion(_ text: String) -> String {
        let filteredCharacters = text.lowercased().filter {
            String($0).rangeOfCharacter(from: NSCharacterSet.lowercaseLetters) != nil ||
                String($0).rangeOfCharacter(from: NSCharacterSet.decimalDigits) != nil
        }
        return String(filteredCharacters)
    }


    private func subscribeToPlayerTime() {
        playerController.playerTimeObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] currentValue in
                self?.pausePlayerAndStartRecordingIfNeeded(currentValue: currentValue)
                self?.adjustCurrentSubtitle(currentValue: currentValue)
            })
            .disposed(by: disposeBag)
    }

    private func adjustCurrentSubtitle(currentValue: Double) {
        if let subtitle = subtitleRepository?.getSubtitleForTime(currentValue) {
            self.currentSubtitle = subtitle
        }
    }

    private func addPlayerViewController() {
        let playerController = LAVPlayerViewController()
        playerController.playingDelegate = self
        addChild(playerController)
        guard let videoView = playerController.view else {
            return
        }
        playerContainerView.insertSubview(videoView, at: 0)
        playerController.didMove(toParent: self)
        playerController.url = fileRepository.getPathURL(for: .videoFile)
        self.playerController = playerController
    }

    private func configureSubtitleRepositoryAndThenPlay() {
        view.isUserInteractionEnabled = false
        configureSubtitleRepositoryAsync { [weak self] in
            self?.view.isUserInteractionEnabled = true
            self?.playerController.play()
        }
    }

    private func configureSubtitleRepositoryAsync(completion: @escaping () -> Void) {
        let url = fileRepository.getPathURL(for: .subtitleFile)
        Completable
            .create { [weak self] event -> Disposable in
                self?.subtitleRepository = SubtitleRepository(url: url)
                event(.completed)
                return Disposables.create()
            }
            .subscribeOn(MainScheduler.asyncInstance)
            .observeOn(MainScheduler.instance)
            .subscribe(onCompleted: {
                completion()
            })
            .disposed(by: disposeBag)
    }

    private func pausePlayerAndStartRecordingIfNeeded(currentValue: Double) {
        if  playerController.isPlaying,
            subtitleRepository.isTimeCloseToEndOfSubtitle(currentValue) {
            playerController.pause()
            onReadyToGetNewInput()
        }
    }

}


extension InputViewController: PlayerViewControllerDelegate {

    // MARK: Functions

    func onPlayingStateChanged(playerViewController: PlayerViewController) {
        let image = playerViewController.isPlaying ? #imageLiteral(resourceName: "Pause") : #imageLiteral(resourceName: "Play")
        playPauseButton.setImage(image, for: .normal)
        onInputAllowedChanged(isAllowed: !playerViewController.isPlaying)
        adjustResultViewIfNeeded()
    }

    func onCloseButtonTouched(playerViewController: PlayerViewController) {
        dismiss(animated: true, completion: nil)
    }
}
