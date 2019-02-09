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
    
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    // MARK: Event handeling
    
    @IBAction private func whatchingButtonTouched() {
        show(WatchingViewController(), sender: nil)
    }
    
    @IBAction private func speakingButtonTouched() {
        show(SpeakingViewController(), sender: nil)
    }
    
}
