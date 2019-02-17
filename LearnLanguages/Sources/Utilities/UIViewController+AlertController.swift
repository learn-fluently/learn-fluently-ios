//
//  UIViewController+AlertController.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 2/9/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import UIKit

extension UIViewController {

    // MARK: Public functions

    func presentOKMessage(title: String, message: String) {
        let controller = createController(title: title, message: message)
        present(controller, animated: true)
    }

    func presentMessage(title: String, message: String = "") -> UIAlertController {
        let controller = createController(title: title, message: message, actions: [])
        present(controller, animated: true)
        return controller
    }

    func presentInput(title: String, message: String, completion: ((String?) -> Void)? = nil) {

        let controller = createController(title: title, message: message, actions: [], appendCancel: true)
        let okAction = UIAlertAction(title: .OK, style: .default) { _ in
            guard let textField = controller.textFields?.first else {
                completion?(nil)
                return
            }
            completion?(textField.text)
        }

        controller.addAction(okAction)
        controller.addTextField { _ in }
        present(controller, animated: true)
    }

    func presentActionSheet<Type: Hashable>(title: String,
                                            message: String,
                                            actions: [ActionData<Type>],
                                            appendCancel: Bool = true,
                                            completion: ((ActionData<Type>?) -> Void)? = nil) {

        let alertActions = actions.map { action in
            UIAlertAction(title: action.title, style: action.style) { _ in
                completion?(action)
            }
        }

        let controller = createController(title: title,
                                          message: message,
                                          actions: alertActions,
                                          style: .actionSheet,
                                          appendCancel: appendCancel)

        present(controller, animated: true)
    }


    // MARK: Private functions

    private func createController(title: String,
                                  message: String,
                                  actions: [UIAlertAction]? = nil,
                                  style: UIAlertController.Style = .alert,
                                  appendCancel: Bool = false,
                                  completion: ((Bool) -> Void)? = nil) -> UIAlertController {

        let controller = UIAlertController(title: title, message: message, preferredStyle: style)
        var actions = actions ?? [UIAlertAction(title: .OK, style: .default) { _ in completion?(true) }]

        if appendCancel {
            let cancelAction = UIAlertAction(title: .CANCEL, style: .cancel) { _ in
                completion?(false)
            }
            actions.append(cancelAction)
        }

        actions.forEach {
            controller.addAction($0)
        }

        return controller
    }

}


extension UIViewController {

    struct ActionData<Type: Hashable> {

        let identifier: Type
        let title: String
        let style: UIAlertAction.Style = .default
    }

}
