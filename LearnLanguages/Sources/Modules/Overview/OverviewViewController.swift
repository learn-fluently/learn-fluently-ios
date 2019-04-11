//
//  OverviewViewController.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 1/23/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import Foundation
import UIKit

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

    private var locale: NSLocale {
        return (Locale.current as NSLocale)
    }

    private weak var delegate: OverviewViewControllerDelegate?


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
    }


    // MARK: Event handeling

    @IBAction private func watchingButtonTouched() {
        delegate?.onWatchingButtonTouched()
    }

    @IBAction private func speakingButtonTouched() {
        delegate?.onSpeakingButtonTouched()
    }

    @IBAction private func writingButtonTouched() {
        delegate?.onWatchingButtonTouched()
    }

    @IBAction private func switchLanguageButtonTouched() {
        let actions: [UIAlertAction.ActionData<String>] = ["en-US", "en-UK", "nl-NL"]
            .map {
                .init(identifier: $0,
                      title: locale.displayName(forKey: .identifier, value: $0) ?? "")
            }

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
