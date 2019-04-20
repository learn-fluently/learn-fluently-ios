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

    // MARK: Properties

    let pageInfo: TitleDesc

    let sourcePickerOptions: [UIAlertAction.ActionData<SourceInfo.Picker>] = [
        .init(identifier: .browser, title: .SOURCE_OPTION_BROWSER),
        .init(identifier: .youtube, title: .SOURCE_OPTION_YOUTUBE),
        .init(identifier: .directLink, title: .SOURCE_OPTION_DIRECT_LINK),
        .init(identifier: .documentPicker, title: .SOURCE_OPTION_DOCUMENT)
    ]

    var videoFileDescriptionObservable: Observable<String> {
        return UserDefaultsService.shared.videoSourceName.map { $0 ?? .SOURCE_FILE_DESC }
    }

    var subtitleFileDescriptionObservable: Observable<String> {
        return UserDefaultsService.shared.subtitleSourceName.map { $0 ?? .SUBTITLE_FILE_DESC }
    }

    var progressMessageObservable: Observable<TitleDesc> {
        return progressMessageBehaviorRelay.asObservable()
    }

    private let progressMessageBehaviorRelay = BehaviorRelay<TitleDesc>(value: .empty)
    private let fileRepository = FileRepository()
    private let youtubeSourceService = YoutubeSourceService()
    private let sourceConverterService: SourceConverterService
    private let sourceDownloaderService: SourceDownloaderService
    private let disposeBag = DisposeBag()


    // MARK: Life cycle

    init(pageInfo: TitleDesc) {
        self.pageInfo = pageInfo
        self.sourceConverterService = SourceConverterService(fileRepository: fileRepository)
        self.sourceDownloaderService = SourceDownloaderService(fileRepository: fileRepository)
        subscribeToDownladerMessages()
    }


    // MARK: Functions

    func createYoutubeInfoGetter(sourceInfo: SourceInfo) -> Single<SourceInfo> {
        guard let url = sourceInfo.sourceURL else {
            return .never()
        }
        return youtubeSourceService.getVideoInfo(url: url)?.map {
            var sourceInfo = sourceInfo
            sourceInfo.youtubeVideoInfo = $0
            return sourceInfo
        } ?? .never()
    }

    func createDownloaderIfNeeded(sourceInfo: SourceInfo) -> Single<SourceInfo> {
        switch sourceInfo.picker {
        case .documentPicker?:
            return .just(sourceInfo)

        default:
            return createDownloader(sourceInfo: sourceInfo)
        }
    }

    func createConverterIfNeeded(sourceInfo: SourceInfo) -> Single<SourceInfo> {
        guard sourceInfo.shouldConvert else {
            return .just(sourceInfo)
        }
        return sourceConverterService.createConverter(sourceInfo: sourceInfo).do(onSubscribed: { [weak self] in
            self?.progressMessageBehaviorRelay.accept(
                .init(title: sourceInfo.typeName, description: .CONVERTING)
            )
        })
    }

    func createSaver(sourceInfo: SourceInfo) -> Single<SourceInfo> {
        return .create { [weak self] event in
            guard let self = self else {
                return Disposables.create {}
            }
            do {
                let sourceInfo = try self.saveSource(sourceInfo: sourceInfo)
                event(.success(sourceInfo))
            } catch {
                event(.error(error))
            }
            return Disposables.create {}
        }
    }

    func updateSourceFileDescriptions(sourceInfo: SourceInfo) {
        guard let selectedName = sourceInfo.selectedName else {
            return
        }
        if sourceInfo.picker == .youtube {
            UserDefaultsService.shared.videoSourceName.accept(selectedName)
            UserDefaultsService.shared.subtitleSourceName.accept(selectedName)
        } else if sourceInfo.type == .video {
            UserDefaultsService.shared.videoSourceName.accept(selectedName)
        } else if sourceInfo.type == .subtitle {
            UserDefaultsService.shared.subtitleSourceName.accept(selectedName)
        }
    }

    func handleDownloadedArchive(sourceInfo: SourceInfo) -> Single<SourceInfo> {
        return .create(subscribe: { [weak self] event -> Disposable in
            guard let `self` = self, let sourceInfoDestinationURL = sourceInfo.destinationURL else {
                return Disposables.create {}
            }
            self.fileRepository.decompressArchiveFile(sourceURL: sourceInfoDestinationURL) { [weak self] filesUrls in
                try? self?.fileRepository.removeItem(at: sourceInfoDestinationURL)
                guard !filesUrls.isEmpty else {
                    event(.error(Errors.Download.archive(.FAILED_TO_GET_CONTENTS_OF_ZIP_FILE)))
                    return
                }
                var sourceInfo = sourceInfo
                sourceInfo.extractedFiles = filesUrls
                event(.success(sourceInfo))
            }

            return Disposables.create {}
        })
    }

    // MARK: Private functions

    private func createDownloader(sourceInfo: SourceInfo) -> Single<SourceInfo> {
        return sourceDownloaderService.startDownload(sourceInfo: sourceInfo)
    }

    private func saveSource(sourceInfo: SourceInfo) throws -> SourceInfo {
        guard sourceInfo.picker != .documentPicker else {
            return try copySourceFile(sourceInfo: sourceInfo)
        }
        guard let sourceInfoDestinationURL = sourceInfo.destinationURL else {
            return sourceInfo
        }
        let destinationURL = getDestinationURL(sourceInfo: sourceInfo)
        try fileRepository.replaceItem(at: destinationURL, with: sourceInfoDestinationURL)
        try fileRepository.removeItem(at: sourceInfoDestinationURL)
        var sourceInfo = sourceInfo
        sourceInfo.destinationURL = destinationURL
        return sourceInfo
    }

    private func getDestinationURL(sourceInfo: SourceInfo) -> URL {
        return sourceInfo.type == .video ? fileRepository.getPathURL(for: .videoFile) : fileRepository.getPathURL(for: .subtitleFile)
    }

    private func copySourceFile(sourceInfo: SourceInfo) throws -> SourceInfo {
        guard let sourceURL = sourceInfo.sourceURL else {
            return sourceInfo
        }
        var sourceInfo = sourceInfo
        let destinationURL = getDestinationURL(sourceInfo: sourceInfo)
        try fileRepository.replaceItem(at: destinationURL, with: sourceURL)
        sourceInfo.destinationURL = destinationURL
        return sourceInfo
    }

    private func subscribeToDownladerMessages() {
        sourceDownloaderService.progressMessageObservable
            .subscribe(onNext: { [weak self] progress in
                self?.progressMessageBehaviorRelay.accept(
                    .init(
                        title: "\(String.DOWNLOADING) \(progress.sourceInfo.typeName)",
                        description: progress.message
                    )
                )
            })
            .disposed(by: disposeBag)
    }

}
