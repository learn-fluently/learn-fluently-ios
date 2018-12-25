//
//  BaseNavigationController.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 12/23/18.
//  Copyright © 2018 Amir Khorsandi. All rights reserved.
//

import UIKit

class BaseNavigationController: UINavigationController {

    // MARK: Lifecycle
    
    convenience init(rootViewController: UIViewController, translucent: Bool) {
        self.init(rootViewController: rootViewController)
    }
    
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        commonInit()
    }
    
    override init(navigationBarClass: AnyClass?, toolbarClass: AnyClass?) {
        super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
        commonInit()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    
    // MARK: UIViewController
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    
    // MARK: Private functions
    
    private func commonInit() {
       navigationBar.shadowImage = UIImage()
    }
    
}
