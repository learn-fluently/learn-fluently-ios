//
//  UIViewController+AlertView.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 2/9/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import UIKit

extension UIViewController {
    
    // MARK: Properties
    
    private var defaultPreferredStyle: UIAlertController.Style {
        return .alert
    }
    
    
    // MARK: Public functions
    
    func presentOKMessage(title: String, message: String) {
        let controller = createController(title: title, message: message)
        present(controller, animated: true)
    }
    
    
    // MARK: Private functions
    
    private func createController(title: String, message: String, completion: ((Bool) -> Void)? = nil) -> UIAlertController {
        let controller = UIAlertController(title: title, message: message, preferredStyle: defaultPreferredStyle)
        
        let okAction = UIAlertAction(
            title: NSLocalizedString("OK", comment: ""),
            style: .default,
            handler: { _ in
                completion?(true)
        })
        controller.addAction(okAction)
        
        return controller
    }
}
