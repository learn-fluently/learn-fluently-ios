//
//  OverviewViewController.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 1/23/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import Foundation
import UIKit
import Speech
import SwiftRichString

protocol OverviewViewControllerDelegate: AnyObject {

    func onWatchingButtonTouched()

    func onSpeakingButtonTouched()

    func onWritingButtonTouched()

}


class OverviewViewController: BaseViewController, NibBasedViewController {

    // MARK: Properties

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    @IBOutlet private weak var learningLanguageTitle: UILabel!
    @IBOutlet private weak var watchingTitleLabel: UILabel!
    @IBOutlet private weak var watchingDescLabel: UILabel!
    @IBOutlet private weak var speakingTitleLabel: UILabel!
    @IBOutlet private weak var speakingDescLabel: UILabel!
    @IBOutlet private weak var writingTitleLabel: UILabel!
    @IBOutlet private weak var writingDescLabel: UILabel!
    @IBOutlet private weak var answeringTitleLabel: UILabel!
    @IBOutlet private weak var answeringDescLabel: UILabel!

    private weak var delegate: OverviewViewControllerDelegate?

    private var locale: NSLocale {
        return (Locale.current as NSLocale)
    }


    // MARK: Life cycle

    init(delegate: OverviewViewControllerDelegate) {
        self.delegate = delegate
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not available")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        reloadLearningLanguageTitle()
        configureLabels()
    }


    // MARK: Event handlers

    @IBAction private func watchingButtonTouched() {
        delegate?.onWatchingButtonTouched()
    }

    @IBAction private func speakingButtonTouched() {
        delegate?.onSpeakingButtonTouched()
    }

    @IBAction private func writingButtonTouched() {
        delegate?.onWritingButtonTouched()
    }

    @IBAction private func answeringButtonTouched() {
        showAlert(.ANSWERING_UNDER_CONSTRUCTION, error: false)
    }

    @IBAction private func switchLanguageButtonTouched() {
        let actions: [UIAlertAction.ActionData<String>] = SFSpeechRecognizer.supportedLocales()
                .map {
                    .init(identifier: $0.identifier,
                          title: locale.displayName(forKey: .identifier, value: $0.identifier) ?? "")
                }
                .sorted { actionA, actionB in
                    actionA.title < actionB.title
                }

        presentActionSheet(title: "", message: .CHOOSE_A_LANGUAGE, actions: actions) { [weak self] selected in
            if let languageCode = selected?.identifier {
                UserDefaultsService.shared.learingLanguageCode = languageCode
                self?.reloadLearningLanguageTitle()
            }
        }
    }


    // MARK: Private functions

    private func configureLabels() {
        watchingTitleLabel.setText(.SECTION_WATCHING_TITLE, style: .overviewSectionTitle)
        watchingDescLabel.setText(.SECTION_WATCHING_DESC, style: .overviewSectionDescription)

        speakingTitleLabel.setText(.SECTION_SPEAKING_TITLE, style: .overviewSectionTitle)
        speakingDescLabel.setText(.SECTION_SPEAKING_DESC, style: .overviewSectionDescription)

        writingTitleLabel.setText(.SECTION_WRITING_TITLE, style: .overviewSectionTitle)
        writingDescLabel.setText(.SECTION_WRITING_DESC, style: .overviewSectionDescription)

        answeringTitleLabel.setText(.SECTION_ANSWERING_TITLE, style: .overviewSectionTitle)
        answeringDescLabel.setText(.SECTION_ANSWERING_DESC, style: .overviewSectionDescription)
    }

    private func reloadLearningLanguageTitle() {
        let code = UserDefaultsService.shared.learingLanguageCode
        let name = (Locale.current as NSLocale).displayName(forKey: .identifier, value: code) ?? ""
        learningLanguageTitle.setText(.OVERVIEW_TITLE_PREFIX + name, style: .pageTitleTextStyle)
    }

}
