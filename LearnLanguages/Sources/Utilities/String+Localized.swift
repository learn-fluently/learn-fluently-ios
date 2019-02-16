//
//  String+Localized.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 2/16/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import Foundation

extension String {

    // swiftlint:disable identifier_name
    static let OK = "OK".localize()
    static let MENU_ITEM_TRANSLATE = "Translate".localize()
    static let MENU_ITEM_GOOGLE_IMAGES = "Images".localize()
    static let MENU_ITEM_GOOGLE_SEARCH = "Google".localize()
    static let MENU_ITEM_SPEECH = "Speech".localize()
    static let ERROR = "Error".localize()

}


private extension String {

    func localize(withComment comment: String? = nil) -> String {
        return NSLocalizedString(self, comment: comment ?? "")
    }

}
