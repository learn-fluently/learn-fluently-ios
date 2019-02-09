//
//  SubtitleRepository.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 2/9/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import Foundation

class SubtitleRepository {
    
    // MARK: Constants
    
    private struct Constants {
        
        static let subtitleCloseThreshold: Double = 0.05
    }

    
    // MARK: Properties
    
    private var url: URL
    
    private var subtitle: Subtitle
    
    private var lastSubtitleCloseEndTime: Double? = nil
    
    
    // MARK: Lifecycle
    
    init(url: URL) {
        self.url = url
        self.subtitle = Subtitle(fileUrl: url)
    }
    
    
    // MARK: Public functions
    
    func getSubtitleForTime(_ time: Double) -> String? {
        guard time > 0 else {
            return nil
        }
        let texts = subtitle.items.first(where: {
            time < $0.end && time > $0.start
        })?.texts
        return texts?.joined(separator: "\n")
    }
    
    func isTimeCloseToEndOfSubtitle(_ time: Double) -> Bool {
        let text = subtitle.items.first(where: {
            abs(time - $0.end) < Constants.subtitleCloseThreshold && lastSubtitleCloseEndTime != $0.end
        })
        if text != nil {
            lastSubtitleCloseEndTime = text?.end
            return true
        }
        return false
    }
    
}
