//
//  AVPlayer+Utilities.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 1/25/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import AVFoundation

extension AVPlayer {
    var isPlaying: Bool {
        return rate != 0 && error == nil
    }
}
