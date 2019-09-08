//
//  SourceDownloadInfo.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 4/17/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

struct SourceInfo {

    // MARK: Constants

    enum `Type` {

        // MARK: Cases

        case video
        case subtitle
    }


    enum Picker {

        // MARK: Cases

        case youtube
        case browser
        case directLink
        case documentPicker
        case auto
    }


    // MARK: Properties

    private(set) var type: Type
    var picker: Picker?
    var sourceURL: URL?
    var destinationURL: URL?
    var mimeType: MimeType?
    var lastDownloadEvent: DownloadUpdateEvent?
    var youtubeVideoInfo: Youtube.VideoInfo?
    var youtubeSelectedUrls: [Type: URL] = [:]
    var selectedName: String?
    var extractedFiles: [URL] = [] {
        didSet {
            mimeType = nil
        }
    }

    var typeName: String {
        return type == .video ? .SOURCE_FILE_TITLE : .SUBTITLE_FILE_TITLE
    }

    var shouldConvert: Bool {
        return getSouldConvert()
    }

    var isArchive: Bool {
        return mimeType?.type == .archive || sourceURL?.pathExtension.lowercased() == "zip"
    }

    var isSupported: Bool {
        return getIsSupported()
    }

    var defaultName: String {
        return youtubeVideoInfo?.title ?? sourceURL?.lastPathComponent ?? ""
    }


    // MARK: Lifecycle

    init(type: Type) {
        self.type = type
    }


    // MARK: Public functions

    func getNextAutoPickSourceInfo() -> SourceInfo? {
        guard picker == .youtube else {
            return nil
        }
        var sourceInfo = self
        sourceInfo.type = type == .video ? .subtitle : .video
        sourceInfo.picker = .auto
        sourceInfo.sourceURL = youtubeSelectedUrls[sourceInfo.type]
        return sourceInfo
    }


    // MARK: Private functions

    private func getSouldConvert() -> Bool {
        return (
            (mimeType == nil || mimeType?.type == .unknown) &&
                sourceURL?.pathExtension.lowercased() == "mkv" &&
                type == .video
            )
            ||
            type == .subtitle
    }

    private func getIsSupported() -> Bool {
        if picker == .youtube || picker == .auto || isArchive {
            return true
        }
        var isSupported = false
        if type == .video {
            if mimeType?.type == .video ||
                sourceURL?.pathExtension.lowercased() == "mkv" ||
                sourceURL?.pathExtension.lowercased() == "mp4" {
                isSupported = true
            }
        } else if type == .subtitle {
            if mimeType?.type == .text ||
                sourceURL?.pathExtension.lowercased() == "srt" {
                isSupported = true
            }
        }
        return isSupported
    }
}
