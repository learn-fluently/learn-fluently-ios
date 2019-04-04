//
//  String+Utilities.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 2/22/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import Foundation

extension String {

    var isValidURL: Bool {
        guard asURL != nil else {
                return false
        }
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return false
        }
        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.lengthOfBytes(using: .utf8))) {
            // it is a link, if the match covers the whole string
            return match.range.length == self.lengthOfBytes(using: .utf8)
        } else {
            return false
        }
    }

    var asURL: URL? {
        return URL(string: self)
    }
}
