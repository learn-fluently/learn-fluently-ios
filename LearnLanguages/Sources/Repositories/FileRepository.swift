//
//  FileRepository.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 2/10/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import Foundation

class FileRepository {

    // MARK: Constants

    enum PathName {

        // MARK: Cases

        case videoFile
        case subtitleFile
        case archiveFile
    }


    // MARK: Properties

    // swiftlint:disable:next force_try
    private let baseURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)


    // MARK: Functions

    func getPathURL(for pathName: PathName) -> URL {
        var url = baseURL

        switch pathName {
        case .videoFile:
            url.appendPathComponent("video.mp4")

        case .subtitleFile:
            url.appendPathComponent("subtitle.srt")

        case .archiveFile:
            url.appendPathComponent("archive.zip")
        }

        return url
    }

    func replaceItem(at dest: URL, with source: URL) {
        try? FileManager.default.removeItem(at: dest)
        do {
            try FileManager.default.copyItem(at: source, to: dest)
        } catch {
            print(error)
        }
    }

    func openArchiveFile(completion: ([URL]) -> Void) {
        //TODO:
    }

}
