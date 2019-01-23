//
//  OverviewViewController.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 1/23/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import Foundation

class OverviewViewController: BaseViewController, NibBasedViewController {
 
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    // MARK: Event handeling
    
    @IBAction private func whatchingButtonTouched() {
        show(ChooseInputsViewController(), sender: nil)
    }
    
}
