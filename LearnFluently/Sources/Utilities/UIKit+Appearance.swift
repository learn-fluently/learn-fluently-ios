//
//  UIKit+Appearance.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 5/26/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import UIKit
import SwiftRichString

extension UILabel {

    // MARK: Public functions

    func setText(_ string: String, style: Style) {
        attributedText = .make(string: string, style: style)
    }

}


extension UITextView {

    // MARK: Public functions

    func setText(_ string: String, style: Style) {
        attributedText = .make(string: string, style: style)
    }

}


extension UIButton {

    // MARK: Public functions

    func setTitle(_ string: String, style: Style, for state: UIControl.State = .normal) {
        setAttributedTitle(.make(string: string, style: style), for: state)
    }

}
