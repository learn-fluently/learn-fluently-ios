//
//  SubtitleItem.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 12/26/18.
//  Copyright © 2018 Amir Khorsandi. All rights reserved.
//

import UIKit

public class SubtitleItem: NSObject {
    public var texts: [String]?
    public var start: TimeInterval?
    public var end: TimeInterval?
    public var index: Int?
    
    
    public init(withTexts: [String], start: TimeInterval, end: TimeInterval, index: Int) {
        super.init()
        
        self.texts = withTexts
        self.start = start
        self.end = end
        self.index = index
    }
}
