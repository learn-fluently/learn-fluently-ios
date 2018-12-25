//
//  NibBasedViewController.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 12/23/18.
//  Copyright © 2018 Amir Khorsandi. All rights reserved.
//

import Foundation

import UIKit

protocol NibBasedViewController {
    static var nibName: String { get }
}

extension NibBasedViewController {
    static var nibName: String {
        return String(describing: self)
    }
}

extension NibBasedViewController where Self: UIViewController {
    static func instantiate() -> Self {
        return Self.init(nibName: self.nibName, bundle: Bundle(for: self))
    }
}
