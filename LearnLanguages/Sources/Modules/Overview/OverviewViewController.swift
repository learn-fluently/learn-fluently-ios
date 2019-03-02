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


    // MARK: Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
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

}
