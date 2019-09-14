//
//  AttributedText+Style.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 5/26/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import SwiftRichString

extension NSAttributedString {

    static func make(string: String, style: Style) -> NSAttributedString {
        return string.set(style: style)
    }

    static func makeMutable(string: String, style: Style) -> NSMutableAttributedString {
        return .init(attributedString: .make(string: string, style: style))
    }

}
