//
//  SubtitleItem.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 12/26/18.
//  Copyright © 2018 Amir Khorsandi. All rights reserved.
//

import Foundation


struct SubtitleItem: Codable {

    // MARK: Properties

    var texts: [String]
    var start: TimeInterval
    var end: TimeInterval
    var index: Int

}
