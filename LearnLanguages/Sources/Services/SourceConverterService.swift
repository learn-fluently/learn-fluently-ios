//
//  SourceConverterService.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 4/19/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import RxCocoa
import RxSwift

class SourceConverterService {

    // MARK: Properties

    private let fileRepository: FileRepository
    private let queue: DispatchQueue


    // MARK: Life cycle

    init(fileRepository: FileRepository) {
        self.fileRepository = fileRepository
        self.queue = DispatchQueue(label: String(describing: type(of: self).self), qos: .background)
    }


    // MARK: Public functions

    func createConverter(sourceInfo: SourceInfo) -> Single<SourceInfo> {
        switch sourceInfo.type {
        case .video:
            return createVideoConverter(sourceInfo: sourceInfo)

        case .subtitle:
            return createSubtitleConverter(sourceInfo: sourceInfo)
        }
    }


    // MARK: Private functions

    private func createVideoConverter(sourceInfo: SourceInfo) -> Single<SourceInfo> {
        guard let url = sourceInfo.destinationURL else {
            return .just(sourceInfo)
        }
        return .create { [weak self] event -> Disposable in
            guard let self = self else {
                return Disposables.create()
            }
            var srcVideoUrl = url
            if srcVideoUrl.pathExtension != "mkv" {
                let newUrl = srcVideoUrl.appendingPathExtension("mkv")
                do {
                    try self.fileRepository.moveItem(at: srcVideoUrl, to: newUrl)
                } catch {
                    event(.error(error))
                }
                srcVideoUrl = newUrl
            }
            let destVideoUrl = self.getNewPathURL().appendingPathExtension("mp4")

            let command = "-i \(srcVideoUrl.path) -codec copy \(destVideoUrl.path)"
            self.queue.async { [weak self] in
                MobileFFmpeg.execute(command)
                do {
                    if self?.fileRepository.fileExists(at: destVideoUrl) == true {
                        var sourceInfo = sourceInfo
                        sourceInfo.destinationURL = url
                        try? self?.fileRepository.removeItem(at: srcVideoUrl)
                        try? self?.fileRepository.removeItem(at: url)
                        try self?.fileRepository.moveItem(at: destVideoUrl, to: url)
                        event(.success(sourceInfo))
                    } else {
                        throw Errors.Download.convert(.ERROR_CONVERT_SOURCE)
                    }
                } catch {
                    event(.error(error))
                }
            }
            return Disposables.create()
        }
    }

    private func createSubtitleConverter(sourceInfo: SourceInfo) -> Single<SourceInfo> {
        guard let url = sourceInfo.destinationURL else {
            return .just(sourceInfo)
        }
        return .create { [weak self] event -> Disposable in
            guard let self = self else {
                return Disposables.create()
            }
            let newURL = self.getNewPathURL()

            self.queue.async { [weak self] in
                let subtitle = Subtitles(fileUrl: url)
                guard let data = subtitle.encodeToData() else {
                    event(.error(Errors.Download.convert(.ERROR_CONVERT_SUBTITLES)))
                    return
                }
                do {
                    try data.write(to: newURL)
                    var sourceInfo = sourceInfo
                    sourceInfo.destinationURL = url
                    try self?.fileRepository.removeItem(at: url)
                    try self?.fileRepository.moveItem(at: newURL, to: url)
                    event(.success(sourceInfo))
                } catch {
                    event(.error(error))
                }
            }
            return Disposables.create()
        }
    }

    private func getNewPathURL() -> URL {
        return fileRepository.getPathURL(for: .temporaryFileForConvert)
    }
}
