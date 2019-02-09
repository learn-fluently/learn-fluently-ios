//
//  UIKit+Appearance.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 2/9/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import UIKit
import SwiftRichString


extension Style {
    
    static var selectableSubtitleTextStyle: Style {
        return Style {
            $0.font = SystemFonts.Helvetica.font(size: 19)
            $0.lineHeightMultiple = 1.8
            $0.color = UIColor.black
        }
    }
    
    static var selectableSubtitleSelectedTextStyle: Style {
        return Style {
            $0.font = SystemFonts.Helvetica.font(size: 19)
            $0.lineHeightMultiple = 1.8
            $0.color = UIView().tintColor
            $0.underline = (.thick, UIColor.orange)
        }
    }
}
