//
//  InputViewController.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 3/2/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import RxSwift
import SwiftRichString

protocol InputViewControllerDelegate: AnyObject {

    func onCloseButtonTouched(inputViewControllerDelegate: BaseViewController)

}


class InputViewController<ViewModel: InputViewModel>: BaseViewController {

    // MARK: Properties

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    var showsPlaybackControls: Bool {
        set { playerController.showsControls = newValue }
        get { return playerController.showsControls }
    }

    weak var delegate: InputViewControllerDelegate?

    internal var disposeBag = DisposeBag()

    internal let viewModel: ViewModel

    private(set) var autoGoToTheNextWithPercentage: Int = 90

    private(set) var autoGoToTheNextDelay: Double = 2

    private(set) var isInputBusy: Bool = false

    private var playerController: PlayerViewController!
    private var currentSubtitle: String?

    @IBOutlet private weak var hintLabel: UILabel!
    @IBOutlet private weak var playerContainerView: UIView!
    @IBOutlet private weak var playPauseButton: UIButton!
    @IBOutlet private weak var correctPercentageLabel: UILabel!
    @IBOutlet private weak var hintButton: UIButton!
    @IBOutlet private weak var replayButton: UIButton!


    // MARK: Lifecycle

    init(viewModel: ViewModel, delegate: InputViewControllerDelegate, nibName: String) {
        self.delegate = delegate
        self.viewModel = viewModel
        super.init(nibName: nibName, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not available")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        addPlayerViewController()
        subscribeToPlayerTime()
        adjustResultViewIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        playerController.pause()
    }


    // MARK: Input events

    internal func onInputAllowedChanged(isAllowed: Bool) {
        fatalError("Should be implemented in child view controllers")
    }

    internal func onReadyToGetNewInput() {
        fatalError("Should be implemented in child view controllers")
    }

    internal func inputWrongWordRanges(_ ranges: [NSRange]) {
        // can be implemented in child classes
    }


    // MARK: - Event handlers

    @IBAction private func playPauseButtonTouched() {
        togglePlayerPlaying()
    }

    @IBAction private func skipNextButtonTouched() {
        let time = viewModel.getStartOfNextSubtitle(currentTime: playerController.playerTime)
        seek(to: time)
    }

    @IBAction private func skipPrevButtonTouched() {
        let time = viewModel.getStartOfPrevSubtitle(currentTime: playerController.playerTime)
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

    internal func configureSubtitleRepositoryAndThenPlay() {
        view.isUserInteractionEnabled = false
        viewModel.initSubtitleRepository()
            .subscribe(onCompleted: { [weak self] in
                self?.view.isUserInteractionEnabled = true
                self?.playerController.play()
            })
            .disposed(by: disposeBag)
    }

    internal func showHint() {
        playerController.pause()
        let style = Style.subtitleTextStyle
        style.color = view.tintColor
        hintLabel.setText(currentSubtitle ?? "", style: style)
        hintLabel.isHidden = false
    }

    internal func hideHint() {
        hintLabel.isHidden = true
    }

    internal func replay() {
        guard !playerController.isPlaying,
            let time = viewModel.getStartOfCurrentSubtitle() else {
                return
        }
        viewModel.cleanLastStop()
        playerController.seek(to: time)
        playerController.play()
    }

    internal func seek(to time: Double?) {
        guard let time = time else {
            return
        }
        playerController.seek(to: time)
        playerController.play()
    }

    internal func adjustResultViewIfNeeded(input: String? = nil) {
        let currentSubtitleLength = currentSubtitle?.lengthOfBytes(using: .utf8) ?? 0

        guard let input = input,
            input.lengthOfBytes(using: .utf8) > 0,
            currentSubtitleLength > 0,
            !playerController.isPlaying,
            !isInputBusy else {
                correctPercentageLabel.isHidden = true
                return
        }

        let originalText = normalizeTextForComparesion(currentSubtitle!)
        let inputText = normalizeTextForComparesion(input)

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
        correctPercentageLabel.setText(.init(format: "%d", beingCorrectPercentage) + "%", style: style)

        // auto play
        if beingCorrectPercentage >= autoGoToTheNextWithPercentage {
            onInputAllowedChanged(isAllowed: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + autoGoToTheNextDelay) { [weak self] in
                self?.playerController.play()
            }
        // finding wrong words ranges
        } else {
            let ranges: [NSRange] = getWrongWordRanges(origirnalText: currentSubtitle!, inputText: input)
            inputWrongWordRanges(ranges)
        }
    }


    // MARK: Private  functions

    private func getWrongWordRanges(origirnalText: String, inputText: String) -> [NSRange] {
        var ranges: [NSRange] = []
        let origirnalWords = origirnalText
            .replacingOccurrences(of: "\n", with: " ")
            .components(separatedBy: " ")
            .map { normalizeTextForComparesion($0) }

        let inputWords = inputText.replacingOccurrences(of: "\n", with: " ").components(separatedBy: " ")
        var location = 0
        if let first = inputWords.first {
            if let range = inputText.range(of: first) {
                location = inputText.nsRange(from: range).location
            }
        }
        inputWords.forEach {
            if $0.lengthOfBytes(using: .utf8) > 1, !origirnalWords.contains(normalizeTextForComparesion($0)) {
                ranges.append(NSRange(location: location, length: $0.lengthOfBytes(using: .utf8)))
            }
            location += $0.lengthOfBytes(using: .utf8) + 1
        }
        return ranges
    }

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
        if let subtitle = viewModel.getSubtitleForTime(currentValue) {
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
        playerController.url = viewModel.getSourcePathURL()
        self.playerController = playerController
    }

    private func pausePlayerAndStartRecordingIfNeeded(currentValue: Double) {
        if  playerController.isPlaying,
            viewModel.isTimeCloseToEndOfSubtitle(currentValue) {
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
        delegate?.onCloseButtonTouched(inputViewControllerDelegate: self)
    }
}
