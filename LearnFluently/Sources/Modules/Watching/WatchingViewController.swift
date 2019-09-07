//
//  WatchingViewController.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 12/23/18.
//  Copyright © 2018 Amir Khorsandi. All rights reserved.
//

import SwiftRichString
import RxSwift

protocol WatchingViewControllerDelegate: AnyObject {

    func onCloseButtonTouched(watchingViewController: WatchingViewController)
    func onOpenWebURLRequest(url: URL)

}


class WatchingViewController: BaseViewController, NibBasedViewController {

    // MARK: Properties

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }


    // MARK: Private properties

    private let viewModel: WatchingViewModel
    private let keepSubtitleAlways: Bool = true
    private var paningStartPoint: CGPoint?
    private var playerController: PlayerViewController!
    private var disposeBag = DisposeBag()
    private weak var delegate: WatchingViewControllerDelegate?
    private var textViewSelectedTextRange: NSRange? = nil {
        didSet {
            setTextViewSelectedTextRange()
        }
    }

    @IBOutlet private weak var textView: LLTextView!
    @IBOutlet private weak var playerContainerView: UIView!
    @IBOutlet private weak var playPauseButton: UIButton!


    // MARK: Lifecycle

    init(viewModel: WatchingViewModel, delegate: WatchingViewControllerDelegate) {
        self.delegate = delegate
        self.viewModel = viewModel
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not available")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
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

        default:
            break
        }
    }


    // MARK: Private functions

    private func subscribeToPlayerTime() {
        if playerController.isPlaying {
            NSLog("asdasd")
        }
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
            selectedEndIndex = getWordStartOrEndIndex(indexInWord: characterIndexAtEndPoint, start: false)
        } else {
            selectedEndIndex = getWordStartOrEndIndex(indexInWord: characterIndexAtStartPoint, start: false)
        }

        if selectedEndIndex <= selectedStartIndex || selectedEndIndex >= textView.text.lengthOfBytes(using: .utf8) {
            return nil
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
        let subtitleText = viewModel.getSubtitleForTime(currentValue)
        if subtitleText == nil, keepSubtitleAlways == true {
            return
        }
        guard !UIMenuController.shared.isMenuVisible else {
            return
        }
        textView.setText(subtitleText ?? "", style: .selectableSubtitleTextStyle)
    }

    private func setTextViewSelectedTextRange() {
        var attributedText = AttributedString.makeMutable(string: textView.text, style: .selectableSubtitleTextStyle)
        if let selectedRange = textViewSelectedTextRange {
            textView.selectedRange = selectedRange
            attributedText = attributedText.set(style: Style.selectableSubtitleSelectedTextStyle,
                                                range: textView.selectedRange)
        }
        textView.attributedText = attributedText
    }

    private func addPlayerViewController() {
        let playerController = LAVPlayerViewController()
        self.playerController = playerController
        playerController.playingDelegate = self
        addChild(playerController)
        guard let videoView = playerController.view else {
            return
        }
        playerContainerView.insertSubview(videoView, at: 0)
        playerController.didMove(toParent: self)
        playerController.url = viewModel.getSourcePathURL()
    }

    private func configureSubtitleRepositoryAndThenPlay() {
        view.isUserInteractionEnabled = false
        viewModel.initSubtitleRepository()
            .subscribe(onCompleted: { [weak self] in
                self?.view.isUserInteractionEnabled = true
                self?.playerController.play()
            })
            .disposed(by: disposeBag)
    }

    private func configureTextView() {
        textView.isEditable = false
        textView.isSelectable = false
        textView.menuItemsDelegate = self
    }

}


extension WatchingViewController: PlayerViewControllerDelegate {

    // MARK: Functions

    func onPlayingStateChanged(playerViewController: PlayerViewController) {
        let image = playerViewController.isPlaying ? #imageLiteral(resourceName: "Pause") : #imageLiteral(resourceName: "Play")
        playPauseButton.setImage(image, for: .normal)
    }

    func onCloseButtonTouched(playerViewController: PlayerViewController) {
        delegate?.onCloseButtonTouched(watchingViewController: self)
    }
}


extension WatchingViewController: LLTextViewMenuDelegate {

    // MARK: Functions

    func onTranslateMenuItemSelected(_ textView: UITextView) {
        openWebView(urlString: "https://translate.google.com/#view=home&op=translate&sl=auto&tl=en&text=" + (getSelectedText().urlEncoded ?? "") )
    }

    func onImageMenuItemSelected(_ textView: UITextView) {
        openWebView(urlString: "https://www.google.com/search?tbm=isch&q=" + (getSelectedText().urlEncoded ?? "") )
    }

    func onGoogleMenuItemSelected(_ textView: UITextView) {
        openWebView(urlString: "https://www.google.com/search?q=" + (getSelectedText().urlEncoded ?? "") )
    }

    func onSpeechMenuItemSelected(_ textView: UITextView) {
        viewModel.speechText(getSelectedText())
        textViewSelectedTextRange = nil
    }


    // MARK: Private functions

    private func openWebView(urlString: String) {
        guard let url = urlString.asURL else {
            return
        }
        delegate?.onOpenWebURLRequest(url: url)
    }
}
