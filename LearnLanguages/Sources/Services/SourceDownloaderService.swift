//
//  SourceDownloaderService.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 2/24/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import RxCocoa
import RxSwift

class SourceDownloaderService {

    // MARK: Constants

    struct ProgressMessage {

        // MARK: Properties

        let message: String
        let sourceInfo: SourceInfo
    }


    // MARK: Properties

    var progressMessageObservable: Observable<ProgressMessage> {
        return progressMessageBehaviorRelay.asObservable().compactMap()
    }

    private let fileRepository: FileRepository
    private let progressMessageBehaviorRelay = BehaviorRelay<ProgressMessage?>( value: nil)


    // MARK: Life cycle

    init(fileRepository: FileRepository) {
        self.fileRepository = fileRepository
    }


    // MARK: Public functions


    func startDownload(sourceInfo: SourceInfo) -> Single<SourceInfo> {
        return downloadFile(sourceInfo: sourceInfo)
    }


    // MARK: Private functions

    private func downloadFile(sourceInfo: SourceInfo) -> Single<SourceInfo> {
        guard let sourceURL = sourceInfo.sourceURL else {
                return .never()
        }
        var progressText = ""
        let destinationURL = fileRepository.getPathURL(for: .temporaryFileForDownload)
        progressMessageBehaviorRelay.accept(nil)
        let sequence = FileDownloader()
            .downloadFile(fromURL: sourceURL, toPath: destinationURL)
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
                        self?.progressMessageBehaviorRelay.accept(
                            ProgressMessage(message: message, sourceInfo: sourceInfo)
                        )
                    }
                },
                onSubscribe: { [weak self] in
                    try? self?.fileRepository.removeItem(at: destinationURL)
                })
            .takeLast(1)
            .asSingle()
            .map({ event -> SourceInfo in
                var sourceInfo = sourceInfo
                sourceInfo.destinationURL = destinationURL
                sourceInfo.lastDownloadEvent = event
                return sourceInfo
            })

        return sequence
    }

}
