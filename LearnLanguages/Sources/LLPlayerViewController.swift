//
//  LLPlayerViewController.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 12/31/18.
//  Copyright © 2018 Amir Khorsandi. All rights reserved.
//

import AVFoundation
import AVKit
import Foundation

class LLPlayerViewController: AVPlayerViewController{
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    
        self.showsPlaybackControls = true
        super.touchesBegan(touches, with: event)
    }
}
