//
//  SourceConfigViewController.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 2/10/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import Foundation
import UIKit
import SwiftRichString

class SourceConfigViewController: BaseViewController, NibBasedViewController {
    
    // MARK: Constants
    
    enum SourceType {
        case watching
        case speaking
    }
    
    
    // MARK: Properties
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    private let sourceType: SourceType
    private let pageTitle: String
    private let pageSubtitle: String
    
    
    // MARK: Outlets
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTitleViews()
    }
    
    init(title: String, subtitle: String, type: SourceType) {
        sourceType = type
        pageTitle = title
        pageSubtitle = subtitle
        super.init(nibName: SourceConfigViewController.nibName, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: Event handeling
    
    @IBAction private func closeButtonTouched() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func playButtonTouched() {
        if sourceType == .watching {
            show(WatchingViewController(), sender: nil)
        }
        if sourceType == .speaking {
            show(SpeakingViewController(), sender: nil)
        }
    }
    
    
    // MARK: Private functions
    
    private func configureTitleViews() {
        titleLabel.attributedText = pageTitle.set(style: Style.pageTitleTextStyle)
        subtitleLabel.attributedText = pageSubtitle.set(style: Style.pageSubtitleTextStyle)
    }
}
