//
//  SourceConfigViewModel.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 4/9/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa


class SourceConfigViewModel {

    // MARK: Constants

    enum SourcePikcerMode {

        // MARK: Cases

        case video
        case subtitle
    }

    enum SourcePickerOption: Int {

        // MARK: Cases

        case youtube
        case browser
        case directLink
        case documentPicker
    }


    // MARK: Properties

    let title: String

    let subtitle: String

    var currentPickerMode: SourcePikcerMode?

    var sourcePickerOptions: [UIAlertAction.ActionData<SourcePickerOption>] {
        return [
            .init(identifier: .browser, title: .SOURCE_OPTION_BROWSER),
            .init(identifier: .youtube, title: .SOURCE_OPTION_YOUTUBE),
            .init(identifier: .directLink, title: .SOURCE_OPTION_DIRECT_LINK),
            .init(identifier: .documentPicker, title: .SOURCE_OPTION_DOCUMENT)
        ]
    }

    var downloadByDirectLinkTitle: String {
        return currentPickerMode == .video ? .SOURCE_FILE_TITLE : .SUBTITLE_FILE_TITLE
    }

    let videoFileDescription = BehaviorRelay<String?>(value: nil)

    let subtitleFileDescription = BehaviorRelay<String?>(value: nil)

    private var lastSubtitleSourceName: String? = UserDefaultsService.shared.subtitleSourceName
    private var lastVideoSourceName: String? = UserDefaultsService.shared.videoSourceName
    private let fileRepository = FileRepository()
    private let youtubeSourceService = YoutubeSourceService()


    // MARK: Life cycle

    init(title: String, subtitle: String) {
        self.title = title
        self.subtitle = subtitle
    }


    // MARK: Functions

    func isSupported(mimeType: String, url: URL) -> Bool {
        var isSupported = false
        if currentPickerMode == .video {
            if mimeType == "video/mp4" ||
                url.pathExtension.lowercased() == "mkv" {
                isSupported = true
            }
        } else if currentPickerMode == .subtitle {
            if mimeType == "application/zip" {
                isSupported = true
            } else if mimeType == "text/plain", url.pathExtension.lowercased() == "srt" {
                isSupported = true
            }
        }
        return isSupported
    }

    func handleDocumentPickerResult(url: URL) {
        let destinationURL = getDestinationURL()
        fileRepository.replaceItem(at: destinationURL, with: url)
    }

    func handleDownloadResult(_ result: SourceDownloaderService.DownloadResult) {
        fileRepository.replaceItem(at: getDestinationURL(), with: result.destinationURL)
        try? fileRepository.removeItem(at: result.destinationURL)
    }

    func saveSourceNameIfNeeded() {
        if lastVideoSourceName != nil {
            UserDefaultsService.shared.videoSourceName = lastVideoSourceName
        }
        if lastSubtitleSourceName != nil {
            UserDefaultsService.shared.subtitleSourceName = lastSubtitleSourceName
        }
    }

    func updateSourceFileDescriptions(sourceName: String? = nil, isYoutube: Bool = false) {
        if let sourceName = sourceName {
            if isYoutube {
                self.lastVideoSourceName = sourceName
                self.lastSubtitleSourceName = sourceName
            } else if self.currentPickerMode == .video {
                self.lastVideoSourceName = sourceName
            } else if self.currentPickerMode == .subtitle {
                self.lastSubtitleSourceName = sourceName
            }
        }

        let videoDesc = lastVideoSourceName ?? .SOURCE_FILE_DESC
        videoFileDescription.accept(videoDesc)

        let subtitleDesc = lastSubtitleSourceName ?? .SUBTITLE_FILE_DESC
        subtitleFileDescription.accept(subtitleDesc)
    }

    func convertFile(url: URL, completion: ((URL?, Error?) -> Void)?) {
        if !fileRepository.fileExists(at: url) {
            completion?(nil, Errors.Download.convert("source file doesn't exist"))//TODO:
        }
        var srcVideoUrl = url
        if srcVideoUrl.pathExtension.isEmpty {
            let newUrl = srcVideoUrl.appendingPathExtension("mkv")
            try? fileRepository.moveItem(at: srcVideoUrl, to: newUrl)
            srcVideoUrl = newUrl
        }
        let destVideoUrl = fileRepository.getPathURL(for: .temporaryFileForConvert).appendingPathExtension("mp4")
        try? fileRepository.removeItem(at: destVideoUrl)

        let command = "-i \(srcVideoUrl.path) -codec copy \(destVideoUrl.path)"
        let queue = DispatchQueue(
            label: String(describing: SourceConfigViewController.self),
            qos: .background
        )
        queue.async { [weak self] in
            MobileFFmpeg.execute(command)
            if self?.fileRepository.fileExists(at: destVideoUrl) == true {
                completion?(destVideoUrl, nil)
                ((try? self?.fileRepository.removeItem(at: srcVideoUrl)) as ()??)
            } else {
                completion?(nil, Errors.Download.convert("failed to convert"))//TODO:
            }
        }
    }

    func getYoutubeVideoInfo(url: URL) -> Single<YoutubeSourceService.YoutubeVideoInfo>? {
        return youtubeSourceService.getVideoInfo(url: url)
    }


    // MARK: Private functions

    func getDestinationURL() -> URL {
        return currentPickerMode == .video ? fileRepository.getPathURL(for: .videoFile) : fileRepository.getPathURL(for: .subtitleFile)
    }

}
