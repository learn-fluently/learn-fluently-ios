//
//  FileRepository.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 2/10/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import Foundation

class FileRepository {

    // MARK: Functions

    func getURLForVideoFile() -> URL {
        // swiftlint:disable:next force_try
        var url: URL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        url.appendPathComponent("video.mp4")
        return url
    }

    func getURLForSubtitleFile() -> URL {
        // swiftlint:disable:next force_try
        var url: URL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        url.appendPathComponent("subtitle.srt")
        return url
    }

}
