//
//  OverviewViewController.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 1/23/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import Foundation
import UIKit

class OverviewViewController: BaseViewController, NibBasedViewController {

    // MARK: Properties

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    @IBOutlet private weak var learningLanguageTitle: UILabel!

    private var locale: NSLocale {
        return (Locale.current as NSLocale)
    }


    // MARK: Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        reloadLearningLanguageTitle()
    }


    // MARK: Event handeling

    @IBAction private func whatchingButtonTouched() {
        show(SourceConfigViewController(title: "Watching/Listening",
                                        subtitle: "Check translates\nlearn new words",
                                        type: .watching),
             sender: nil)
    }

    @IBAction private func speakingButtonTouched() {
        show(SourceConfigViewController(title: "Speaking",
                                        subtitle: "Pronunciation training\nSentence structure",
                                        type: .speaking),
             sender: nil)
    }

    @IBAction private func writingButtonTouched() {
        show(SourceConfigViewController(title: "Writing",
                                        subtitle: "Listening training\ndictation training",
                                        type: .writing),
             sender: nil)
    }

    @IBAction private func switchLanguageButtonTouched() {

        let actions: [ActionData<String>] = [
            ActionData(identifier: "en-US", title: locale.displayName(forKey: .identifier, value: "en-US") ?? ""),
            ActionData(identifier: "en-UK", title: locale.displayName(forKey: .identifier, value: "en-UK") ?? ""),
            ActionData(identifier: "nl-NL", title: locale.displayName(forKey: .identifier, value: "nl-NL") ?? "")
        ]

        presentActionSheet(title: "", message: "Choose language", actions: actions) { [weak self] selected in
            if let languageCode = selected?.identifier {
                UserDefaultsService.shared.learingLanguageCode = languageCode
                self?.reloadLearningLanguageTitle()
            }
        }

    }


    // MARK: Private functions

    private func reloadLearningLanguageTitle() {
        let code = UserDefaultsService.shared.learingLanguageCode
        let name = (Locale.current as NSLocale).displayName(forKey: .identifier, value: code) ?? ""
        learningLanguageTitle.text = "You are learning \n" + name
    }

}
