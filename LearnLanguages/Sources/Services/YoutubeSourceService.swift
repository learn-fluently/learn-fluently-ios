//
//  YoutubeSourceService.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 2/24/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import UIKit
import XCDYouTubeKit


class YoutubeSourceService {

    // MARK: Properties

    private let client = XCDYouTubeClient.default()


    // MARK: Functions

    func getVideoInfo(url: URL, completion: ((YoutubeVideoInfo?, Error?) -> Void )?) {
        guard let videoId = getVideoIdFromUrl(url) else {
            completion?(nil, nil)
            return
        }
        client.getVideoWithIdentifier(videoId, cookies: nil) { video, error in
            guard error == nil,
                let title = video?.title,
                let streamURLs = video?.streamURLs else {
                completion?(nil, error)
                return
            }

            let captionURLs = VideoCaption.from(video?.captionURLs)
            let autoGeneratedCaptionURLs = VideoCaption.from(video?.autoGeneratedCaptionURLs,
                                                             isAutoGenerated: true)

            var videoItems: [VideoQuality] = []
            if let small = streamURLs[XCDYouTubeVideoQuality.small240.rawValue] {
                videoItems.append(VideoQuality(name: .YOUTUBE_VIDEO_SMALL, url: small))
            }
            if let medium = streamURLs[XCDYouTubeVideoQuality.medium360.rawValue] {
                videoItems.append(VideoQuality(name: .YOUTUBE_VIDEO_MEDIUM, url: medium))
            }
            if let hd720 = streamURLs[XCDYouTubeVideoQuality.HD720.rawValue] {
                videoItems.append(VideoQuality(name: .YOUTUBE_VIDEO_HD, url: hd720))
            }

            let videoInfo = YoutubeVideoInfo(title: title,
                                             videos: videoItems,
                                             captionURLs: captionURLs + autoGeneratedCaptionURLs)

            completion?(videoInfo, nil)
        }
    }


    // MARK: Private functions

    private func getVideoIdFromUrl(_ url: URL) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: "(?<=v(=|/))([-a-zA-Z0-9_]+)|(?<=youtu.be/)([-a-zA-Z0-9_]+)", options: .caseInsensitive)
            let match = regex.firstMatch(in: url.absoluteString, options: .reportProgress, range: NSRange(location: 0, length: url.absoluteString.lengthOfBytes(using: .utf8)))
            let range = match!.range(at: 0)
            return url.absoluteString.substring(from: range.location, length: range.length)
        } catch {
            return nil
        }
    }

}


extension YoutubeSourceService {

    struct YoutubeVideoInfo {

        // MARK: Properties

        let title: String
        let videos: [VideoQuality]
        let captionURLs: [VideoCaption]
    }


    struct VideoQuality {

        // MARK: Properties

        let name: String
        let url: URL
    }


    struct VideoCaption {

        // MARK: Properties

        let languageName: String
        let languageCode: String
        let url: URL
        let isAutoGenerated: Bool


        // MARK: Static functions

        static func from(_ source: [AnyHashable: URL]?, isAutoGenerated: Bool = false) -> [VideoCaption] {
            return source?.map {
                let code = $0.key as? String ?? ""
                let name = (Locale.current as NSLocale).displayName(forKey: .identifier, value: code) ?? ""
                return VideoCaption(languageName: name,
                                    languageCode: code,
                                    url: $0.value,
                                    isAutoGenerated: isAutoGenerated)
            } ?? []
        }
    }

}