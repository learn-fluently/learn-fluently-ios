//
//  FileRepository.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 2/10/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import Foundation
import ZIPFoundation

class FileRepository {

    // MARK: Constants

    enum PathName {

        // MARK: Cases

        case videoFile
        case subtitleFile
        case archiveFile
        case archiveDecompressedDir
        case temporaryFileForDownload
    }


    // MARK: Properties

    private let fileManager = FileManager.default

    private let baseURL: URL


    // MARK: Life cycle

    init() {
        // swiftlint:disable:next force_try
        baseURL = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }

    // MARK: Functions

    func getPathURL(for pathName: PathName) -> URL {
        var url = baseURL

        switch pathName {
        case .videoFile:
            url.appendPathComponent("video.mp4")

        case .subtitleFile:
            url.appendPathComponent("subtitle.txt")

        case .archiveFile:
            url.appendPathComponent("archive.zip")

        case .archiveDecompressedDir:
            url.appendPathComponent("archiveDecompressedDir")

        case .temporaryFileForDownload:
            url.appendPathComponent("temporaryFileForDownload")
        }

        return url
    }

    func replaceItem(at dest: URL, with source: URL) {
        try? fileManager.removeItem(at: dest)
        do {
            try fileManager.copyItem(at: source, to: dest)
        } catch {
            print(error)
        }
    }

    func decompressArchiveFile(completion: ([URL]) -> Void) {
        let destPath = getPathURL(for: .archiveDecompressedDir)
        try? fileManager.removeItem(at: destPath)
        try? fileManager.createDirectory(at: destPath, withIntermediateDirectories: false, attributes: nil)
        try? fileManager.unzipItem(at: getPathURL(for: .archiveFile), to: destPath)
        let urls = try? fileManager.contentsOfDirectory(at: destPath, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
        completion(urls ?? [])
    }

}
