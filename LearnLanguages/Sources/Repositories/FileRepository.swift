//
//  FileRepository.swift
//  Learn Fluently
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
        case temporaryArchiveDecompressedDir
        case temporaryFileForDownload
        case temporaryFileForConvert
    }


    // MARK: Properties

    private let fileManager = FileManager.default

    private let baseURL: URL

    private let queue: DispatchQueue


    // MARK: Life cycle

    init() {
        // swiftlint:disable:next force_try
        baseURL = try! fileManager.url(for: .developerDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        self.queue = DispatchQueue(label: String(describing: type(of: self).self), qos: .background)
        removeAllTempFiles()
    }

    // MARK: Functions

    func getPathURL(for pathName: PathName) -> URL {
        var url = baseURL

        switch pathName {
        case .videoFile:
            url.appendPathComponent("video.mp4")

        case .subtitleFile:
            url.appendPathComponent("subtitle.json")

        case .temporaryArchiveDecompressedDir:
            url.appendPathComponent("tempArchiveDecompressedDir" + String(Int.random(in: 0..<Int(RAND_MAX))))

        case .temporaryFileForDownload:
            url.appendPathComponent("tempFileForDownload" + String(Int.random(in: 0..<Int(RAND_MAX))))

        case .temporaryFileForConvert:
            url.appendPathComponent("tempFileForConvert" + String(Int.random(in: 0..<Int(RAND_MAX))))
        }

        return url
    }

    func fileExists(at url: URL) -> Bool {
        return fileManager.fileExists(atPath: url.path)
    }

    func moveItem(at: URL, to: URL) throws {
        try fileManager.moveItem(at: at, to: to)
    }

    func removeItem(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }

    func replaceItem(at dest: URL, with source: URL) throws {
        try? fileManager.removeItem(at: dest)
        try fileManager.copyItem(at: source, to: dest)
    }

    func decompressArchiveFile(sourceURL: URL, completion: @escaping (Error?, [URL], URL?) -> Void) {
        let destPath = getPathURL(for: .temporaryArchiveDecompressedDir)
        self.queue.async { [weak self] in
            do {
                try self?.fileManager.createDirectory(at: destPath, withIntermediateDirectories: false, attributes: nil)
                try self?.fileManager.unzipItem(at: sourceURL, to: destPath)
                let urls = try self?.fileManager.contentsOfDirectory(at: destPath, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]) ?? []
                completion(nil, urls, destPath)
            } catch {
                completion(error, [], nil)
            }
        }
    }


    // MARK: Private functions

    private func removeAllTempFiles() {
        let contents = try? fileManager.contentsOfDirectory(at: baseURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
        contents?.forEach {
            if $0.lastPathComponent.starts(with: "temp") {
                try? fileManager.removeItem(at: $0)
            }
        }
    }

}
