//
//  RootViewController.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 12/23/18.
//  Copyright © 2018 Amir Khorsandi. All rights reserved.
//

import UIKit


class RootViewController: UIViewController {
    
    
    // MARK: Private properties
    
    private var current: UIViewController
    
    
    // MARK: Lifecycle
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.current = ChooseInputsViewController.instantiate()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.current = ChooseInputsViewController.instantiate()
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        transition(to: current)
    }
    
    
    // MARK: UIViewController
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    
    // MARK: Public functions
    
    func transition(to new: UIViewController) {
        current.willMove(toParent: nil)
        current.view.removeFromSuperview()
        current.removeFromParent()
        
        addChild(new)
        new.view.frame = view.bounds
        view.addSubview(new.view)
        new.didMove(toParent: self)
        
        current = new
    }
    
    func animateTransition(to new: UIViewController, duration: TimeInterval, options: UIView.AnimationOptions, completion: ((Bool) -> Void)? = nil) {
        current.willMove(toParent: nil)
        
        addChild(new)
        new.view.frame = view.bounds
        new.view.setNeedsLayout()
        new.view.layoutIfNeeded()
        
        transition(from: current, to: new, duration: duration, options: options, animations: nil) { completed in
            self.current.view.removeFromSuperview()
            self.current.removeFromParent()
            
            self.view.addSubview(new.view)
            new.didMove(toParent: self)
            self.current = new
            completion?(completed)
        }
    }
    
}
