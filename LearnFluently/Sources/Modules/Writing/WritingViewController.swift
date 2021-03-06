//
//  WritingViewController.swift
//  Learn Fluently
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

class WritingViewController: InputViewController<WritingViewModel>, NibBasedViewController {

    // MARK: Properties

    private var isEditingAllowed = false
    override var autoGoToTheNextWithPercentage: Int {
        return 97
    }

    @IBOutlet private weak var inputTextView: UITextView!
    @IBOutlet private weak var doneButton: UIButton!
    @IBOutlet private weak var contentViewBottomConstraint: NSLayoutConstraint!


    // MARK: Lifecycle

    init(viewModel: WritingViewModel, delegate: InputViewControllerDelegate) {
        super.init(viewModel: viewModel, delegate: delegate, nibName: type(of: self).nibName)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not available")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        inputTextView.delegate = self
        adjustResultViewIfNeeded()
        addKeyboardFrameNotificationObserver()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureSubtitleRepositoryAndThenPlay()
        inputTextView.becomeFirstResponder()
    }

    deinit {
        removeKeyboardNotificationObserver()
    }


    // MARK: - Event handlers

    @IBAction private func doneButtonTouched() {
       adjustResultViewIfNeeded(input: inputTextView.text)
    }


    // MARK: Internal functions

    internal override func togglePlayerPlaying() {
        super.togglePlayerPlaying()
        cleanInputTextView()
    }

    internal override func showHint() {
        super.showHint()
        inputTextView.isHidden = true
    }

    internal override func hideHint() {
        super.hideHint()
        inputTextView.isHidden = false
    }

    internal override func replay() {
        super.replay()
        cleanInputTextView()
    }

    internal override func seek(to time: Double?) {
        guard let time = time else {
            return
        }
        super.seek(to: time)
        cleanInputTextView()
    }

    internal override func onReadyToGetNewInput() {
        cleanInputTextView()
        isEditingAllowed = true
        doneButton.isEnabled = true
        inputTextView.isHidden = false
        inputTextView.becomeFirstResponder()
    }

    internal override func onInputAllowedChanged(isAllowed: Bool) {
        isEditingAllowed = isAllowed
        if !isAllowed {
            cleanInputTextView()
        }
    }

    internal override func inputWrongWordRanges(_ ranges: [NSRange]) {
        let text = inputTextView.text ?? ""
        let wrongWordStyle = Style.subtitleTextStyle
        wrongWordStyle.color = UIColor.red
        let attributedText = AttributedString.makeMutable(string: text, style: .subtitleTextStyle)
        ranges.forEach {
            attributedText.set(style: wrongWordStyle, range: $0)
        }
        inputTextView.attributedText = attributedText
    }


    // MARK: Private functions

    private func cleanInputTextView() {
        inputTextView.attributedText = nil
        inputTextView.isHidden = true
        doneButton.isEnabled = false
        inputTextView.textContainerInset = .zero
        inputTextView.contentInset = .zero
        inputTextView.textContainer.lineFragmentPadding = 0
    }

    private func addKeyboardFrameNotificationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardWillChangeFrame(notification:)),
            name: UIWindow.keyboardWillChangeFrameNotification,
            object: nil)
    }

    private func removeKeyboardNotificationObserver() {
        NotificationCenter.default.removeObserver(self, name: UIWindow.keyboardWillChangeFrameNotification, object: nil)
    }

    @objc private func handleKeyboardWillChangeFrame(notification: Notification) {
        let keyboardEndFrame = (notification.userInfo?[UIWindow.keyboardFrameEndUserInfoKey] as? CGRect) ?? .zero
        var constant = self.view.frame.height - keyboardEndFrame.origin.y
        if constant < 0 {
            constant = 0
        }
        contentViewBottomConstraint.constant = constant + 4
        view.layoutIfNeeded()
    }

}


extension WritingViewController: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        let selectedRange = textView.selectedTextRange
        textView.setText(textView.text, style: .subtitleTextStyle)
        textView.selectedTextRange = selectedRange
    }

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return isEditingAllowed
    }

}
