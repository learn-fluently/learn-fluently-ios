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

    func onSourceReady(deafulSourceName: String, isYoutube: Bool)

}


class SourceDownloaderService {

    // MARK: Properties

    weak var delegate: SourceDownloaderServiceDelegate?

    private let hostViewController: UIViewController
    private let fileRepository = FileRepository()
    private let fileDownloaderService = FileDownloaderService()
    private let disposeBag = DisposeBag()
    private var youtubeSourceService: YoutubeSourceService!

    // MARK: Life cycle

    init(hostViewController: UIViewController, delegate: SourceDownloaderServiceDelegate) {
        self.hostViewController = hostViewController
        self.delegate = delegate
        self.youtubeSourceService = YoutubeSourceService(delegate: self)
    }


    // MARK: Functions

    func startDownloadWizard(title: String, desc: String, destUrl: URL, isArchive: Bool = false) {
        getLinkByInputDialog(title: title, desc: desc) { [weak self] url in
            self?.startDownload(url: url, destUrl: destUrl, isArchive: isArchive)
        }
    }

    func startDownload(url: URL, destUrl: URL, isArchive: Bool = false) {
        downloadFile(url: url, destUrl: destUrl, isArchive: isArchive)
    }

    func startDownloadFromYoutubeWizard() {
        let destUrl = fileRepository.getPathURL(for: .videoFile)
        getLinkByInputDialog(title: .ENTER_YOUTUBE_LINK, desc: "") { [weak self] url in
            self?.youtubeSourceService.getAvailableQualities(url: url) { items, error in
                let compatibleItems = items.filter { $0.isCompatible }
                if error != nil || compatibleItems.isEmpty {
                    self?.hostViewController.presentOKMessage(title: .ERROR, message: .FAILED_TO_GET_YOUTUBE_LINKS)
                } else {
                    let alert = UIAlertController(style: .actionSheet)
                    compatibleItems.forEach { item in
                        alert.addAction(title: item.name) { [weak self] _ in
                            self?.downloadFile(url: url, destUrl: destUrl)
                        }
                    }
                    self?.hostViewController.present(alert, animated: true, completion: nil)
                }
            }
        }
    }


    // MARK: Private functions

    private func getLinkByInputDialog(title: String, desc: String, completion: ((URL) -> Void)?) {
        hostViewController.presentInput(title: title, message: desc) { inputLink in
            guard let link = inputLink,
                let url = URL(string: link) else {
                    return
            }
            completion?(url)
        }
    }

    private func downloadFile(url: URL, destUrl: URL, isArchive: Bool = false) {
        let progressViewController = hostViewController.presentMessage(title: .DOWNLOADING)
        var progressText = ""
        let destinationURL = isArchive ? fileRepository.getPathURL(for: .archiveFile) : destUrl
        fileDownloaderService
            .downloadFile(fromURL: url, toPath: destinationURL)
            .subscribeOn(MainScheduler.asyncInstance)
            .observeOn(MainScheduler.instance)
            .do(onNext: { event in
                if event.type == .progress, let data = event.progress {
                    progressText = "\(data.progress) %"
                    progressViewController.message = "\(progressText)\n\(String.DOWNLOAD_SPEED): \(data.speed)KB/s"
                } else if let message = event.messsage {
                    progressViewController.message = "\(progressText)\n\(message)"
                }
            },
                onError: { [weak self] error in
                    progressViewController.dismiss(animated: false) {
                        self?.hostViewController.presentOKMessage(title: .ERROR, message: error.localizedDescription)
                    }
                },
                onCompleted: { [weak self] in
                    progressViewController.dismiss(animated: false) {
                        if isArchive {
                            self?.handleDownloadedArchive(destUrl: destUrl)
                        } else {
                            self?.onSourceReady(url: url)
                        }
                    }
            })
            .subscribe()
            .disposed(by: disposeBag)
    }

    private func handleDownloadedArchive(destUrl: URL) {
        fileRepository.decompressArchiveFile { [weak self] filesUrls in
            guard !filesUrls.isEmpty else {
                self?.hostViewController.presentOKMessage(title: .ERROR, message: .FAILED_TO_GET_CONTENTS_OF_ZIP_FILE)
                return
            }

            if filesUrls.count == 1 {
                saveFileToDestination(url: filesUrls.first!, destUrl: destUrl)
                return
            }

            let alert = UIAlertController(style: .actionSheet)
            filesUrls.forEach { url in
                alert.addAction(title: url.lastPathComponent) { [weak self] _ in
                    self?.saveFileToDestination(url: url, destUrl: destUrl)
                }
            }
            self?.hostViewController.present(alert, animated: true, completion: nil)
        }
    }

    private func saveFileToDestination(url: URL, destUrl: URL) {
        fileRepository.replaceItem(at: destUrl, with: url)
        onSourceReady(url: url)
    }

    private func onSourceReady(url: URL) {
        self.delegate?.onSourceReady(deafulSourceName: url.lastPathComponent, isYoutube: false)
    }

}


extension SourceDownloaderService: YoutubeSourceServiceDelegate {
    func onSourceReady(sourceName: String) {

    }


}
