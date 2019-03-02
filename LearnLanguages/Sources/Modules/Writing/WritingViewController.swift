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

    // MARK: Properties

    override var isInputBusy: Bool {
        return false// TODO: set language
    }


    // MARK: Outlets

    @IBOutlet private weak var inputTextView: UITextView!
    @IBOutlet private weak var doneButton: UIButton!


    // MARK: Lifecyle

    public override func viewDidLoad() {
        super.viewDidLoad()

        adjustResultViewIfNeeded()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        inputTextView.becomeFirstResponder()
    }


    // MARK: - Event handlers

    @IBAction private func doneButtonTouched() {
       adjustResultViewIfNeeded(input: inputTextView.text)
    }


    // MARK: Internal functions

    internal override func togglePlayerPlaying() {
        super.togglePlayerPlaying()
        inputTextView.text = ""
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
        inputTextView.text = ""
    }

    internal override func seek(to time: Double) {
        super.seek(to: time)
        inputTextView.text = ""
    }

    internal override func onReadyToGetNewInput() {
        inputTextView.text = ""
        inputTextView.becomeFirstResponder()
    }

    internal override func onInputAllowedChanged(isAllowed: Bool) {
//        recordButton.isEnabled = isAllowed
//        if !isAllowed {
//            textLabelView.text = ""
//        }
    }

}


extension WritingViewController: UITextFieldDelegate {


}
