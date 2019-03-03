//
//  WatchingViewController.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 12/23/18.
//  Copyright © 2018 Amir Khorsandi. All rights reserved.
//

import AVFoundation
import AVKit
import SafariServices
import SwiftRichString
import RxSwift

class WatchingViewController: BaseViewController, NibBasedViewController {

    // MARK: Properties

    let playingConfig = PlayingConfig()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }


    // MARK: Private properties

    private let speechSynthesizer = AVSpeechSynthesizer()
    private var paningStartPoint: CGPoint?
    private var playerController: PlayerViewController!
    private var subtitleRepository: SubtitleRepository!
    private var fileRepository: FileRepository!
    private var disposeBag = DisposeBag()
    private var textViewSelectedTextRange: NSRange? = nil {
        didSet {
            setTextViewSelectedTextRange()
        }
    }


    // MARK: Outlets

    @IBOutlet private weak var textView: LLTextView!
    @IBOutlet private weak var playerContainerView: UIView!
    @IBOutlet private weak var playPauseButton: UIButton!


    // MARK: Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        fileRepository = FileRepository()
        addPlayerViewController()
        subscribeToPlayerTime()
        configureTextView()
        configureTextViewGestures()
        configureSubtitleRepositoryAndThenPlay()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        playerController.pause()
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
         adjustAndShowMenuForSelectedTextIfNeeded()
    }


    // MARK: - Event handlers

    @IBAction private func playPauseButtonTouched() {
        playerController.togglePlaying()
    }

    @IBAction private func skipNextButtonTouched() {
        playerController.seek(byDelta: 5.0)
    }

    @IBAction private func skipPrevButtonTouched() {
        playerController.seek(byDelta: -5.0)
    }


    // MARK: TextView gesture handeling

    @objc private func handleTap(_ gestureRecognizer: UIPanGestureRecognizer) {
        let point = gestureRecognizer.location(in: textView)
        if textViewSelectedTextRange != nil {
            textViewSelectedTextRange = nil
            UIMenuController.shared.setMenuVisible(false, animated: true)
        } else {
            if let range = getTextRangeByPointsOnTextView(startPoint: point) {
                playerController.pause()
                textViewSelectedTextRange = range
                adjustAndShowMenuForSelectedTextIfNeeded()
            }
        }
    }

    @objc private func handlePanGestue(_ gestureRecognizer: UIPanGestureRecognizer) {
        let location = gestureRecognizer.location(in: textView)
        switch gestureRecognizer.state {
        case .began:
            playerController.pause()
            paningStartPoint = location

        case .cancelled, .failed, .ended:
            paningStartPoint = nil
            adjustAndShowMenuForSelectedTextIfNeeded()

        case .possible, .changed:
            if let paningStartPoint = paningStartPoint,
                let range = getTextRangeByPointsOnTextView(startPoint: paningStartPoint, endPoint: location) {
                textViewSelectedTextRange = range
            }
        }
    }


    // MARK: Private functions

    private func subscribeToPlayerTime() {
        playerController.playerTimeObservable
            .subscribe(onNext: { [weak self] currentValue in
                self?.adjustSubtitleByPlayerTime(currentValue: currentValue)
            })
            .disposed(by: disposeBag)
    }

    private func getSelectedText() -> String {
        guard let selectedRange = textViewSelectedTextRange else {
            return ""
        }
        return textView.text.substring(from: selectedRange.location, length: selectedRange.length) ?? ""
    }

    private func getTextRangeByPointsOnTextView(startPoint: CGPoint, endPoint: CGPoint? = nil) -> NSRange? {
        let characterIndexAtStartPoint = getCharacterIndexByPointOnTextView(startPoint)
        guard characterIndexAtStartPoint < textView.text.lengthOfBytes(using: .utf8),
            characterIndexAtStartPoint > -1 else {
            return nil
        }
        let selectedStartIndex = getWordStartOrEndIndex(indexInWord: characterIndexAtStartPoint, start: true)

        let selectedEndIndex: Int
        if let endPoint = endPoint {
            let characterIndexAtEndPoint = getCharacterIndexByPointOnTextView(endPoint)
            if characterIndexAtEndPoint >= textView.text.lengthOfBytes(using: .utf8) ||
                characterIndexAtEndPoint <= selectedStartIndex {
                return nil
            }
            selectedEndIndex = getWordStartOrEndIndex(indexInWord: characterIndexAtEndPoint, start: false)
        } else {
            selectedEndIndex = getWordStartOrEndIndex(indexInWord: characterIndexAtStartPoint, start: false)
        }

        return NSRange(location: selectedStartIndex, length: selectedEndIndex - selectedStartIndex + 1)
    }

    private func getWordStartOrEndIndex(indexInWord: Int, start: Bool) -> Int {
        var index: Int = indexInWord
        while true {
            let nextIndex = index + (start ? -1 : 1)
            if nextIndex < 0 || nextIndex >= textView.text.lengthOfBytes(using: .utf8) {
                break
            }
            if textView.text[nextIndex] == " " ||
                textView.text[nextIndex] == "\n" {
                break
            }
            index = nextIndex
        }

        return index
    }

    private func getCharacterIndexByPointOnTextView(_ point: CGPoint) -> Int {
        let textStorage = NSTextStorage(attributedString: textView.attributedText)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let bounds: CGRect = textView.bounds
        let textContainer = NSTextContainer(size: bounds.size)
        layoutManager.addTextContainer(textContainer)
        let adjustedPoint = CGPoint(x: point.x, y: point.y - 15)
        return layoutManager.characterIndex(for: adjustedPoint,
                                            in: textContainer,
                                            fractionOfDistanceBetweenInsertionPoints: nil)
    }

    private func adjustAndShowMenuForSelectedTextIfNeeded() {
        guard let selectedRange = textViewSelectedTextRange,
        let rangeStart = textView.position(from: textView.beginningOfDocument, offset: selectedRange.location),
        let rangeEnd = textView.position(from: rangeStart, offset: selectedRange.length),
        let selectedTextRange = textView.textRange(from: rangeStart, to: rangeEnd) else {
            return
        }
        textView.becomeFirstResponder()
        let selectionRects = textView.selectionRects(for: selectedTextRange)
        var finalRect = CGRect.null
        for selectionRect in selectionRects {
            if finalRect.isNull {
                finalRect = selectionRect.rect
            } else {
                finalRect = finalRect.union(selectionRect.rect)
            }
        }
        let adjustedRect = CGRect(x: finalRect.minX, y: finalRect.minY + 10, width: finalRect.width, height: finalRect.height)
        UIMenuController.shared.setTargetRect(adjustedRect, in: textView)
        UIMenuController.shared.setMenuVisible(true, animated: true)
    }

    private func configureTextViewGestures() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePanGestue))
        textView.addGestureRecognizer(pan)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        textView.addGestureRecognizer(tap)
    }

    private func adjustSubtitleByPlayerTime(currentValue: Double) {
        let subtitleText = subtitleRepository?.getSubtitleForTime(currentValue)
        if subtitleText == nil && playingConfig.keepSubtitleAllways == true {
            return
        }
        guard !UIMenuController.shared.isMenuVisible else {
            return
        }
        setSubtitleText(subtitleText ?? "")
    }

    private func setSubtitleText(_ text: String) {
        textView.attributedText = text.set(style: Style.selectableSubtitleTextStyle)
    }

    private func setTextViewSelectedTextRange() {
        var attributedText = textView.text.set(style: Style.selectableSubtitleTextStyle)
        if let selectedRange = textViewSelectedTextRange {
            textView.selectedRange = selectedRange
            attributedText = attributedText.set(style: Style.selectableSubtitleSelectedTextStyle,
                                                range: selectedRange)
        }
        textView.attributedText = attributedText
    }

    private func addPlayerViewController() {
        playerController = PlayerViewController()
        playerController.playingDelegate = self
        addChild(playerController)
        guard let videoView = playerController?.view else { return }
        playerContainerView.insertSubview(videoView, at: 0)
        playerController.didMove(toParent: self)
        playerController.url = fileRepository.getPathURL(for: .videoFile)
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

    private func configureTextView() {
        textView.isEditable = false
        textView.isSelectable = false
        textView.menuItemsDelegate = self
    }

}


extension WatchingViewController: PlayerViewControllerPlayingDelegate {

    // MARK: Functions

    func onPlayingStateChanged(playerViewController: PlayerViewController) {
        let image = playerViewController.isPlaying ? #imageLiteral(resourceName: "Pause") : #imageLiteral(resourceName: "Play")
        playPauseButton.setImage(image, for: .normal)
    }

    func onCloseButtonTouched(playerViewController: PlayerViewController) {
        dismiss(animated: true, completion: nil)
    }
}


extension WatchingViewController: LLTextViewMenuDelegate {

    // MARK: Functions

    func onTranslateMenuItemSelected(_ textView: UITextView) {
        openWebView(url: "https://translate.google.com/#view=home&op=translate&sl=auto&tl=fa&text=" + urlEncode(getSelectedText()) )
    }

    func onImageMenuItemSelected(_ textView: UITextView) {
        openWebView(url: "https://www.google.com/search?tbm=isch&q=" + urlEncode(getSelectedText()) )
    }

    func onGoogleMenuItemSelected(_ textView: UITextView) {
        openWebView(url: "https://www.google.com/search?q=" + urlEncode(getSelectedText()) )
    }

    func onSpeechMenuItemSelected(_ textView: UITextView) {
        let utterance = AVSpeechUtterance(string: getSelectedText())
        utterance.voice = AVSpeechSynthesisVoice(language: UserDefaultsService.shared.learingLanguageCode)
        speechSynthesizer.speak(utterance)
        textViewSelectedTextRange = nil
    }


    // MARK: Private functions

    private func urlEncode(_ originalString: String) -> String {
        return originalString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
    }

    private func openWebView(url: String) {
        let webView = SFSafariViewController(url: URL(string: url)!)
        present(webView, animated: true)
    }
}
