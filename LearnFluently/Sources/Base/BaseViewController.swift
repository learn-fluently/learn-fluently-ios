//
//  BaseViewController.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 12/23/18.
//  Copyright © 2018 Amir Khorsandi. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController {

    // MARK: Functions

    func showAlert(_ message: String, error: Bool = true) {
        presentOKMessage(title: error ? .ERROR : "", message: message)
    }
}
