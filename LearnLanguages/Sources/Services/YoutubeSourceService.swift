//
//  YoutubeSourceService.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 2/24/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import UIKit
import YoutubeDirectLinkExtractor

protocol YoutubeSourceServiceDelegate: AnyObject {

    func onSourceReady(sourceName: String)

}


class YoutubeSourceService {

    // MARK: Properties

    weak var delegate: YoutubeSourceServiceDelegate?

    private let youtubeDirectLinkExtractor = YoutubeDirectLinkExtractor()


    // MARK: Life cycle

    init(delegate: YoutubeSourceServiceDelegate) {
        self.delegate = delegate
    }


    // MARK: Functions

    func getAvailableQualities(url: URL, completion: (([Quality], Error?) -> Void )?) {
        youtubeDirectLinkExtractor.extractInfo(for: .url(url), success: { videoInfo in
            let qualities = videoInfo.rawInfo.map {
                Quality(name: $0["quality"] ?? "", url: URL(string: $0["url"] ?? "")!, typeRaw: $0["type"] ?? "")
            }
            completion?(qualities, nil)
        }, failure: { error in
            completion?([], error)
        })
    }

}


extension YoutubeSourceService {

    struct Quality {

        // MARK: Properties

        let name: String
        let url: URL
        let typeRaw: String

        var isCompatible: Bool {
            return typeRaw.starts(with: "video/mp4;")
        }
    }

}
