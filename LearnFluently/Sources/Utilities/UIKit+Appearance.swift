//
//  UIKit+Appearance.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 2/9/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import UIKit
import SwiftRichString


extension Style {

    // MARK: Static properties

    static var subtitleTextStyle: Style {
        return Style {
            $0.font = SystemFonts.Helvetica.font(size: 18)
            $0.color = UIColor.black
        }
    }

    static var selectableSubtitleTextStyle: Style {
        let style = subtitleTextStyle
        style.lineHeightMultiple = 1.8
        return style
    }

    static var selectableSubtitleSelectedTextStyle: Style {
        let style = selectableSubtitleTextStyle
        style.color = UIView().tintColor
        style.underline = (.thick, UIColor.orange)
        return style
    }

    static func beCorrectPercentage(color: UIColor) -> Style {
        return Style {
            $0.font = SystemFonts.Helvetica_Bold.font(size: 17)
            $0.color = color
        }
    }

    static var pageTitleTextStyle: Style {
        return Style {
            $0.font = SystemFonts.HelveticaNeue_Medium.font(size: 18)
            $0.color = UIColor.black
        }
    }

    static var pageSubtitleTextStyle: Style {
        return Style {
            $0.font = SystemFonts.HelveticaNeue_Medium.font(size: 12)
            $0.color = UIColor.black
        }
    }

    static var itemTitleTextStyle: Style {
        return Style {
            $0.font = UIFont.systemFont(ofSize: 17, weight: .bold)
            $0.color = UIColor.black
        }
    }

    static var itemDescriptionTextStyle: Style {
        return Style {
            $0.font = UIFont.systemFont(ofSize: 11, weight: .regular)
            $0.color = UIColor.black
        }
    }

}
