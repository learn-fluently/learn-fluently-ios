//
//  SourceDownloaderService.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 2/24/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import RLBAlertsPickers


protocol SourceDownloaderServiceDelegate: AnyObject {

    func chooseOneFromMany(urls: [URL], onSelected: ((URL) -> Void)?)
    func convertFile(url: URL, completion: ((URL?, Error?) -> Void)?)
    func onProgressUpdate(message: String)
}


class SourceDownloaderService {

    // MARK: Constants

    enum SourceUrlType {

        // MARK: Cases

        case regular // normal source
        case archive // a zip file that should unzip then choose the source from its content
        case convertible // a file that should convert to another format
    }


    // MARK: Properties

    weak var delegate: SourceDownloaderServiceDelegate?

    private let fileRepository = FileRepository()


    // MARK: Life cycle

    init(delegate: SourceDownloaderServiceDelegate) {
        self.delegate = delegate
    }


    // MARK: Functions


    func startDownload(url: URL, type: SourceUrlType = .regular) -> Single<DownloadResult> {
        return downloadFile(url: url,
                            isArchive: type == .archive,
                            isConvertible: type == .convertible)
    }


    // MARK: Private functions

    private func downloadFile(url: URL,
                              isArchive: Bool = false,
                              isConvertible: Bool = false) -> Single<DownloadResult> {
        var progressText = ""
        let destinationURL = fileRepository.getPathURL(for: .temporaryFileForDownload)
        let sequence = FileDownloader()
            .downloadFile(fromURL: url, toPath: destinationURL)
            .subscribeOn(MainScheduler.asyncInstance)
            .observeOn(MainScheduler.instance)
            .do(
                onNext: { [weak self] event in
                    var downloadMessage: String?
                    if event.type == .progress, let data = event.progress {
                        progressText = "\(data.progress) %"
                        downloadMessage = "\(progressText)\n\(String.DOWNLOAD_SPEED): \(data.speed)KB/s"
                    } else if let message = event.messsage {
                        downloadMessage = "\(progressText)\n\(message)"
                    }
                    if let message = downloadMessage {
                        self?.delegate?.onProgressUpdate(message: message)
                    }
                },
                onSubscribe: { [weak self] in
                    ((try? self?.fileRepository.removeItem(at: destinationURL)) as ()??)
                })
            .takeLast(1)
            .asSingle()
            .map({ _ -> DownloadResult in
                DownloadResult(sourceURL: url, destinationURL: destinationURL)
            })

        if isArchive {
            return sequence
                .flatMap { [weak self] result -> Single<DownloadResult> in
                    if let `self` = self {
                        self.delegate?.onProgressUpdate(message: "unziping")//TODO:
                        return self.handleDownloadedArchive(result: result)
                    }
                    return .never()
                }
        } else if isConvertible {
            return sequence
                .flatMap { [weak self] result -> Single<DownloadResult> in
                    if let `self` = self {
                        self.delegate?.onProgressUpdate(message: "converting")//TODO:
                        return self.handleDownloadedConvertible(result: result)
                    }
                    return .never()
                }
        } else {
            return sequence
        }

    }

    private func handleDownloadedConvertible(result: DownloadResult) -> Single<DownloadResult> {
        return .create(subscribe: { [weak self] event -> Disposable in
            self?.delegate?.convertFile(url: result.destinationURL) { convertedFileUrl, error in
                if let convertedFileUrl = convertedFileUrl {
                    var result = result
                    result.destinationURL = convertedFileUrl
                    event(.success(result))
                } else if let error = error {
                    event(.error(error))
                }
            }
            return Disposables.create {}
        })
    }

    private func handleDownloadedArchive(result: DownloadResult) -> Single<DownloadResult> {
        return .create(subscribe: { [weak self] event -> Disposable in
            guard let `self` = self else {
                return Disposables.create {}
            }
            self.fileRepository.decompressArchiveFile { [weak self] filesUrls in
                guard !filesUrls.isEmpty else {
                    event(.error(Errors.Download.archive(.FAILED_TO_GET_CONTENTS_OF_ZIP_FILE)))
                    return
                }
                var result = result

                if filesUrls.count == 1 {
                    result.destinationURL = filesUrls.first!
                    event(.success(result))
                    return
                } else {
                    DispatchQueue.main.async { [weak self] in
                        self?.delegate?.chooseOneFromMany(urls: filesUrls) { url in
                            result.destinationURL = url
                            event(.success(result))
                        }
                    }
                }
            }

            return Disposables.create {}
        })
    }

}


extension SourceDownloaderService {

    struct DownloadResult {

        // MARK: Properties

        var sourceURL: URL
        var destinationURL: URL
    }

}
