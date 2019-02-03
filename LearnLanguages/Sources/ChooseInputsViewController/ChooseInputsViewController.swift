//
//  ChooseInputsViewController.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 12/23/18.
//  Copyright © 2018 Amir Khorsandi. All rights reserved.
//
import AVFoundation
import AVKit
import SafariServices
import SwiftRichString

class ChooseInputsViewController: BaseViewController, NibBasedViewController, LLTextViewMenuDelegate, UIGestureRecognizerDelegate, UITextViewDelegate {
    
    // MARK: Properties
    
    var player: AVPlayer!
    var playerController: AVPlayerViewController!
    var subtitles: Subtitles!
    let playingConfig = PlayingConfig()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    // MARK: Private properties
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var textViewSelectedTextRange: NSRange? = nil {
        didSet {
            setTextViewSelectedTextRange()
        }
    }
    private let textViewTextStyle = Style {
        $0.font = SystemFonts.Helvetica.font(size: 19)
        $0.lineHeightMultiple = 1.8
        $0.color = UIColor.black
    }
    private let textViewTextSelectedTextStyle = Style {
        $0.font = SystemFonts.Helvetica.font(size: 19)
        $0.lineHeightMultiple = 1.8
        $0.color = UIView().tintColor
        $0.underline = (.thick, UIColor.orange)
    }
    private var paningStartPoint: CGPoint? = nil
    private var lastStopTime:Double? = nil
    
    // MARK: Outlets
    
    @IBOutlet private weak var textView: LLTextView!
    @IBOutlet private weak var playerContainerView: UIView!
    @IBOutlet private weak var playPauseButton: UIButton!
    
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addPlayerAndPlay()
        configureSubtitle()
        addPlayerTimeListener()
        configureTextView()
        configureTextViewGestures()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player.pause()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
         adjustAndShowMenuForSelectedTextIfNeeded()
    }
    
    
    // MARK: - Event handlers
    
    @IBAction private func closeButtonTouched() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func playPauseButtonTouched() {
        if player.timeControlStatus == .playing {
            player.pause()
        } else if player.timeControlStatus == .paused {
            player.play()
        }
    }
    
    @IBAction private func skipNextButtonTouched() {
        changeSeekTime(value: 5.0)
    }
    
    @IBAction private func skipPrevButtonTouched() {
        changeSeekTime(value: -5.0)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "timeControlStatus" {
            onPlayerStateChanged()
        }
    }
    
    
    // MARK: TextView gesture handeling
    
    @objc private func handleTap(_ gestureRecognizer : UIPanGestureRecognizer){
        let point = gestureRecognizer.location(in: textView)
        if textViewSelectedTextRange != nil {
            textViewSelectedTextRange = nil
            UIMenuController.shared.setMenuVisible(false, animated: true)
        }
        else {
            if let range = getTextRangeByPointsOnTextView(startPoint: point) {
                textViewSelectedTextRange = range
                adjustAndShowMenuForSelectedTextIfNeeded()
                player.pause()
            }
        }
    }
    
    @objc private func handlePanGestue(_ gestureRecognizer : UIPanGestureRecognizer){
        let location = gestureRecognizer.location(in: textView)
        switch gestureRecognizer.state {
        case .began:
            player.pause()
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
        }
        else {
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
    
    private func changeSeekTime(value: Double) {
        guard let duration = player.currentItem?.duration else{
            return
        }
        let playerCurrentTime = CMTimeGetSeconds(player.currentTime())
        var newTime = playerCurrentTime + value
        
        if newTime < 0 {
            newTime = 0
        }
        if newTime < (CMTimeGetSeconds(duration) - value) {
            let time: CMTime = CMTimeMakeWithSeconds(newTime, preferredTimescale: Int32(NSEC_PER_SEC))
            player.seek(to: time, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        }
    }
    
    private func configureTextViewGestures() {
        for recognizer in textView.gestureRecognizers ?? [] {
            if recognizer is UILongPressGestureRecognizer {
                recognizer.isEnabled = false
            }
        }
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePanGestue))
        textView.addGestureRecognizer(pan)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        textView.addGestureRecognizer(tap)
    }
    
    
    
    private func addPlayerTimeListener(){
        let interval = CMTimeMakeWithSeconds(0.1, preferredTimescale: Int32(NSEC_PER_SEC))
        player.addPeriodicTimeObserver(forInterval: interval, queue: nil) { [weak self] time in
            let currentValue = Double(Double(time.value) / 1000000000.0)
            self?.adjustSubtitleByPlayerTime(currentValue: currentValue)
            self?.pausePlayerIfNeeded(currentValue: currentValue)
        }
    }
    
    private func pausePlayerIfNeeded(currentValue: Double) {
        guard let subtitles = subtitles.titles, currentValue > 0 else {
            return
        }
        let text = subtitles.first(where: {
            abs(currentValue - ($0.end ?? 0)) < 0.05 && lastStopTime != $0.end
        })
        if text != nil {
            lastStopTime = text?.end
            player.pause()
        }
    }
    
    private func adjustSubtitleByPlayerTime(currentValue: Double) {
        guard let subtitles = subtitles.titles, currentValue > 0 else {
            return
        }
        let texts = subtitles.first(where: {
            currentValue < $0.end ?? 0 && currentValue > $0.start ?? 0
        })?.texts
        let subtitleText = texts?.joined(separator: "\n")
        if subtitleText == nil && playingConfig.keepSubtitleAllways == true {
            return
        }
        setSubtitleText(subtitleText ?? "")
    }
    
    private func setSubtitleText(_ text: String) {
        textView.attributedText = text.set(style: textViewTextStyle)
    }
    
    private func setTextViewSelectedTextRange() {
        var attributedText = textView.text.set(style: textViewTextStyle)
        if let selectedRange = textViewSelectedTextRange {
            textView.selectedRange = selectedRange
            attributedText = attributedText.set(style: textViewTextSelectedTextStyle, range: selectedRange)
        }
        textView.attributedText = attributedText
    }
    
    private func addPlayerAndPlay(){
        let url: URL = Bundle.main.url(forResource: "movie", withExtension: "mp4")!
        
        let avAsset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: avAsset)
        player = AVPlayer(playerItem: playerItem)
        playerController = AVPlayerViewController()
        playerController?.player = player
        guard let videoView = playerController?.view else { return }
        playerContainerView.insertSubview(videoView, at: 0)
        videoView.snp.makeConstraints {
            $0.size.equalToSuperview()
            $0.center.equalToSuperview()
        }
        player?.play()
        
        player.addObserver(self, forKeyPath: "timeControlStatus", options: [], context: nil)
        playerController?.setValue(false, forKey: "canHidePlaybackControls")
    }
    
    @objc private func onPlayerStateChanged() {
        if player.timeControlStatus == .playing {
            playPauseButton.setImage(#imageLiteral(resourceName: "Pause"), for: .normal)
        } else {
            playPauseButton.setImage(#imageLiteral(resourceName: "Play"), for: .normal)
        }
    }
    
    private func configureSubtitle(){
        let exampleSubtitlesUrl = Bundle.main.url(forResource: "subtitle", withExtension: "srt")
        subtitles = Subtitles(fileUrl: exampleSubtitlesUrl!)
    }
    
    private func configureTextView() {
        textView.isEditable = false
        textView.isSelectable = false
        textView.menuItemsDelegate = self
        textView.delegate = self
    }
    
    private func urlEncode(_ originalString:String) -> String{
        return originalString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
    }
    
    private func openWebView(url: String){
        let webView = SFSafariViewController(url: URL(string: url)!)
        present(webView, animated: true)
    }
    
    //MARK: - LLTextViewMenuDelegate
    
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
        // TODO: set language
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)
        textViewSelectedTextRange = nil
    }
    
}
