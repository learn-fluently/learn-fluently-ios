//
//  Style+Appearance.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 2/9/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import SwiftRichString


extension Style {

    // MARK: Static properties

    static var base: Style {
        return Style {
            $0.font = UIFont.systemFont(ofSize: 11, weight: .regular)
            $0.color = UIColor.black
        }
    }

    static var overviewSectionTitle: Style {
        return new {
            $0.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            $0.color = #colorLiteral(red: 0.231372549, green: 0.231372549, blue: 0.231372549, alpha: 1)
        }
    }

    static var overviewSectionDescription: Style {
        return new(base: overviewSectionTitle) {
            $0.font = UIFont.systemFont(ofSize: 10, weight: .regular)
        }
    }

    static var subtitleTextStyle: Style {
        return new {
            $0.font = SystemFonts.Helvetica.font(size: 18)
        }
    }

    static var selectableSubtitleTextStyle: Style {
        return new(base: subtitleTextStyle) {
            $0.lineHeightMultiple = 1.8
        }
    }

    static var selectableSubtitleSelectedTextStyle: Style {
        return new(base: selectableSubtitleTextStyle) {
            $0.color = UIView().tintColor
            $0.underline = (.thick, UIColor.orange)
        }
    }

    static func beCorrectPercentage(color: UIColor) -> Style {
        return new {
            $0.font = SystemFonts.Helvetica_Bold.font(size: 17)
            $0.color = color
        }
    }

    static var pageTitleTextStyle: Style {
        return new {
            $0.font = SystemFonts.HelveticaNeue_Medium.font(size: 18)
        }
    }

    static var pageSubtitleTextStyle: Style {
        return new {
            $0.font = SystemFonts.HelveticaNeue_Medium.font(size: 12)
        }
    }

    static var itemTitleTextStyle: Style {
        return new {
            $0.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        }
    }

    static var itemDescriptionTextStyle: Style {
        return new {
            $0.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        }
    }


    // MARK: Static functions

    static func new(base: Style = .base, adjuster: (inout Style) -> Void) -> Style {
        var style = base
        adjuster(&style)
        return style
    }

}
