//
//  UIViewController+AlertController.swift
//  Learn Fluently
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

    func presentInput(title: String, message: String = "", defaultValue: String = "", completion: ((String?) -> Void)? = nil) {

        let controller = createController(title: title, message: message, actions: [], appendCancel: true)
        let okAction = UIAlertAction(title: .OK, style: .default) { _ in
            guard let textField = controller.textFields?.first else {
                completion?(nil)
                return
            }
            completion?(textField.text)
        }

        controller.addAction(okAction)
        controller.addTextField { textField in
            textField.text = defaultValue
        }
        present(controller, animated: true)
    }

    func presentActionSheet<Type: Hashable>(title: String,
                                            message: String,
                                            actions: [UIAlertAction.ActionData<Type>],
                                            appendCancel: Bool = true,
                                            completion: ((UIAlertAction.ActionData<Type>?) -> Void)? = nil) {

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
        if let popoverController = controller.popoverPresentationController {
            popoverController.sourceView = self.view //to set the source of your alert
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0) // you can set this as per your requirement.
            popoverController.permittedArrowDirections = [] //to hide the arrow of any particular direction
        }
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


extension UIAlertAction {

    struct ActionData<Type: Hashable> {

        let identifier: Type
        let title: String
        let style: UIAlertAction.Style = .default
    }

}
