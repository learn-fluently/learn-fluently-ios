//
//  SourceConfigViewController.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 2/10/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import Foundation
import UIKit
import SwiftRichString
import MobileCoreServices
import RxSwift
import RxCocoa
import RLBAlertsPickers

protocol SourceConfigViewControllerDelegate: AnyObject {

    func onPlayButtonTouched()

    func onCloseButtonTouched()

}


class SourceConfigViewController: BaseViewController, NibBasedViewController {


    // MARK: Properties

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    private let disposeBag = DisposeBag()
    private var sourceDownloaderService: SourceDownloaderService!
    private var downloadProgressViewController: UIAlertController?

    let viewModel: SourceConfigViewModel
    private weak var delegate: SourceConfigViewControllerDelegate?


    // MARK: Outlets

    @IBOutlet private weak var startButton: UIButton!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var videoFileTitleLabel: UILabel!
    @IBOutlet private weak var videoFileDescriptionLabel: UILabel!
    @IBOutlet private weak var subtitleFileTitleLabel: UILabel!
    @IBOutlet private weak var subtitleFileDescriptionLabel: UILabel!


    // MARK: Life cycle

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not available")
    }

    init(viewModel: SourceConfigViewModel, delegate: SourceConfigViewControllerDelegate) {
        self.viewModel = viewModel
        self.delegate = delegate
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        sourceDownloaderService = SourceDownloaderService(delegate: self)
        configureTitleViews()
    }


    // MARK: Event handeling

    @IBAction private func closeButtonTouched() {
        delegate?.onCloseButtonTouched()
    }

    @IBAction private func playButtonTouched() {
        viewModel.saveSourceNameIfNeeded()
        delegate?.onPlayButtonTouched()
    }

    @IBAction private func chooseVideoSourceButtonTouched() {
        openSourcePicker(mode: .video)
    }

    @IBAction private func chooseSubtitleSourceButtonTouched() {
        openSourcePicker(mode: .subtitle)
    }


    // MARK: Private functions

    private func openSourcePicker(mode: SourceConfigViewModel.SourcePikcerMode) {
        viewModel.currentPickerMode = mode
        presentActionSheet(title: "",
                           message: .CHOOSE_SOURCE_TITLE,
                           actions: viewModel.sourcePickerOptions) { [weak self] selected in

            switch selected?.identifier {
            case .documentPicker?:
                self?.openFilePicker()

            case .browser?:
                self?.openWebView()

            case .directLink?:
                self?.startWizardForDownloadByDirectLink()

            case .youtube?:
                self?.startYoutubeDownloadSourceWizard()

            default: break
            }
        }
    }

    private func openFilePicker() {
        let types: [String] = [
            kUTTypeVideo as String, kUTTypeText as String,
            kUTTypeData as String, kUTTypeUTF8PlainText as String,
            kUTTypeText as String, kUTTypeUTF16PlainText as String,
            kUTTypeTXNTextAndMultimediaData as String,
            "public.text", "public.content", "public.data"
        ]
        let documentPicker = UIDocumentPickerViewController(documentTypes: types, in: .import)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .formSheet
        if let popoverController = documentPicker.popoverPresentationController {
            popoverController.sourceView = self.view //to set the source of your alert
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0) // you can set this as per your requirement.
            popoverController.permittedArrowDirections = [] //to hide the arrow of any particular direction
        }
        self.present(documentPicker, animated: true, completion: nil)
    }

    private func askAndSetSourceName(defaultValue: String, isYoutube: Bool = false) {
        presentInput(title: .ENTER_SOURCE_NAME, defaultValue: defaultValue) { [weak self] name in
            guard let self = self else {
                return
            }
            var fileName = name ?? defaultValue
            if fileName.lengthOfBytes(using: .utf8) < 1 {
                fileName = defaultValue
            }
            self.viewModel.updateSourceFileDescriptions(sourceName: fileName, isYoutube: isYoutube)
        }
    }

    private func openWebView() {
        let alert = UIAlertController(style: .actionSheet)
        let browserViewController = WebBrowserViewController(parentView: view)
        browserViewController.delegate = self
        alert.set(vc: browserViewController)
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }

        self.present(alert, animated: true, completion: nil)
    }

    private func configureTitleViews() {
        titleLabel.attributedText = viewModel.title.set(style: Style.pageTitleTextStyle)
        subtitleLabel.attributedText = viewModel.subtitle.set(style: Style.pageSubtitleTextStyle)

        viewModel.videoFileDescription
            .subscribe(onNext: { [weak self] value in
                self?.videoFileDescriptionLabel.attributedText = value?.set(style: Style.itemDescriptionTextStyle)
            })
            .disposed(by: disposeBag)

        viewModel.subtitleFileDescription
            .subscribe(onNext: { [weak self] value in
                self?.subtitleFileDescriptionLabel.attributedText = value?.set(style: Style.itemDescriptionTextStyle)
            })
            .disposed(by: disposeBag)

        viewModel.updateSourceFileDescriptions()
    }

    private func proccessSourceFileIfNeeded(url: URL, completion: ((URL) -> Void)?) {
        if sourceDownloaderService.getSourceUrlType(mimeType: nil, url: url) == .convertible {
            self.convertFile(url: url) { [weak self] url, error in
                if let error = error {
                    self?.present(error)
                } else if let url = url {
                    completion?(url)
                }
            }
        } else {
            completion?(url)
        }
    }

    private func present(_ error: Error) {
        dismissDownloadProgressDialog {  [weak self] in
            self?.presentOKMessage(title: .ERROR, message: error.localizedDescription)
        }
    }

    private func dismissDownloadProgressDialog(completion: (() -> Void)?) {
        if let downloadProgressViewController = downloadProgressViewController {
            downloadProgressViewController.dismiss(animated: false) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    completion?()
                }
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                completion?()
            }
        }
        self.downloadProgressViewController = nil
    }

    private func startDownload(url: URL, type: SourceDownloaderService.SourceUrlType? = nil) -> Single<SourceDownloaderService.DownloadResult> {
        let type = type ?? sourceDownloaderService.getSourceUrlType(mimeType: nil, url: url)
        return sourceDownloaderService.startDownload(url: url, type: type)
            .do(onSubscribe: { [weak self] in
                guard let `self` = self else {
                    return
                }
                DispatchQueue.main.async {
                    if self.downloadProgressViewController == nil {
                        self.downloadProgressViewController = self.presentMessage(title: .DOWNLOADING)
                    }
                }
            })
    }
}


extension SourceConfigViewController {

    private func handleDownloadingSourceSequences(
        _ sequences: [Single<SourceDownloaderService.DownloadResult>],
        sourceDefaultName: String = "",
        isYoutube: Bool = false) {

        var sourceName: String = ""

        let completables = sequences.map {
            $0.do(onSuccess: { [weak self] result in
                sourceName = sourceDefaultName.isEmpty ? result.sourceURL.lastPathComponent : sourceDefaultName
                self?.viewModel.handleDownloadResult(result)
                }, onError: { [weak self] error in
                    self?.present(error)
                })
                .asCompletable()
        }

        Completable
            .merge(completables)
            .do(onCompleted: { [weak self] in
                self?.dismissDownloadProgressDialog {
                    self?.askAndSetSourceName(defaultValue: sourceName, isYoutube: isYoutube)
                }
            })
            .subscribe()
            .disposed(by: disposeBag)
    }

}


extension SourceConfigViewController: WebBrowserViewControllerDelegate {

    func getDownloadHandlerBlock(mimeType: String, url: URL) -> (() -> Void)? {
        let downloadHandler: () -> Void = { [weak self] in
            guard let `self` = self else {
                return
            }
            let type = self.sourceDownloaderService.getSourceUrlType(mimeType: mimeType, url: url)
            self.handleDownloadingSourceSequences(
                [self.startDownload(url: url, type: type)],
                sourceDefaultName: url.lastPathComponent
            )
        }

        let isSupported = viewModel.isSupported(mimeType: mimeType, url: url)
        return isSupported ? downloadHandler : nil
    }

}


extension SourceConfigViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            return
        }
        proccessSourceFileIfNeeded(url: url) { [weak self] url in
            self?.viewModel.handleDocumentPickerResult(url: url)
            self?.askAndSetSourceName(defaultValue: url.lastPathComponent)
        }
    }

}


extension SourceConfigViewController: SourceDownloaderServiceDelegate {

    func chooseOneFromMany(urls: [URL], onSelected: ((URL) -> Void)?) {
        let alert = UIAlertController(style: .actionSheet)
        urls.forEach { url in
            alert.addAction(title: url.lastPathComponent) { _ in
                onSelected?(url)
            }
        }
        dismissDownloadProgressDialog { [weak self] in
            self?.present(alert, animated: true, completion: nil)
        }
    }

    func convertFile(url: URL, completion: ((URL?, Error?) -> Void)?) {
        viewModel.convertFile(url: url, completion: completion)
    }

    func onProgressUpdate(message: String) {
        downloadProgressViewController?.message = message
    }

}


extension SourceConfigViewController {

    private func startWizardForDownloadByDirectLink() {
        let title = viewModel.downloadByDirectLinkTitle
        let desc: String = .SOURCE_OPTION_DIRECT_LINK
        let sequence = getLinkByInputDialog(title: title, desc: desc).flatMap { [weak self] url -> Single<SourceDownloaderService.DownloadResult> in
            self?.startDownload(url: url) ?? .never()
        }
        handleDownloadingSourceSequences([sequence])
    }

    private func getLinkByInputDialog(title: String, desc: String = "") -> Single<URL> {
        return .create(subscribe: { [weak self] event -> Disposable in
            self?.presentInput(title: title, message: desc) { inputLink in
                guard let link = inputLink,
                    let url = URL(string: link) else {
                        return
                }
                event(.success(url))
            }
            return Disposables.create {}
        })
    }

    private func startYoutubeDownloadSourceWizard() {
        var videoTitle: String = ""
        getLinkByInputDialog(title: .ENTER_YOUTUBE_LINK)
            .flatMap { [weak self] url -> Single<YoutubeSourceService.YoutubeVideoInfo> in
                self?.viewModel.getYoutubeVideoInfo(url: url) ?? .never()
            }
            .flatMap { [weak self] videoInfo -> Single<[SourceConfigViewModel.SourcePikcerMode: URL]> in
                videoTitle = videoInfo.title
                return self?.showVideoAndSubtitleDialogs(videoInfo: videoInfo) ?? .never()
            }
            .subscribeOn(MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] urls in
                    let sequences = urls.compactMap { pickerMode, url in
                        self?.startDownload(url: url).do(onSuccess: { [weak self] _ in
                            self?.viewModel.currentPickerMode = pickerMode
                        })
                    }
                    self?.handleDownloadingSourceSequences(sequences, sourceDefaultName: videoTitle, isYoutube: true)
                },
                onError: { [weak self] error in
                    self?.present(error)
                })
            .disposed(by: disposeBag)
    }

    private func showVideoAndSubtitleDialogs(videoInfo: YoutubeSourceService.YoutubeVideoInfo) -> Single<[SourceConfigViewModel.SourcePikcerMode: URL]> {
        let shouldShowChooseSubtitle = !videoInfo.captionURLs.isEmpty
        return .create { [weak self] event -> Disposable in
            self?.showChooseVideoQuality(videoInfo: videoInfo) { [weak self] videoUrl in
                if shouldShowChooseSubtitle {
                    self?.showChooseSubtitle(videoInfo: videoInfo) { subtitleUrl in
                        event(.success([.video: videoUrl, .subtitle: subtitleUrl]))
                    }
                } else {
                    event(.success([.video: videoUrl]))
                }
            }
            return Disposables.create {}
        }
    }

    private func showChooseVideoQuality(videoInfo: YoutubeSourceService.YoutubeVideoInfo?, completion: ((URL) -> Void)? = nil) {
        let alert = UIAlertController(style: .actionSheet, title: "", message: .YOUTUBE_QUALITY_CHOOSE)
        videoInfo?.videos.forEach { item in
            alert.addAction(title: item.name) { _ in
                completion?(item.url)
            }
        }
        present(alert, animated: true, completion: nil)
    }

    private func showChooseSubtitle(videoInfo: YoutubeSourceService.YoutubeVideoInfo?, completion: ((URL) -> Void)? = nil) {
        let alert = UIAlertController(style: .actionSheet, title: "", message: .YOUTUBE_SUBTITLE_CHOOSE)
        videoInfo?.captionURLs.forEach { item in
            let autoGeneratedSuffix = item.isAutoGenerated ? " (\(String.YOUTUBE_SUBTITLE_AUTO_GENERATED))" : ""
            alert.addAction(title: item.languageCode + " - " + item.languageName + autoGeneratedSuffix) { _ in
                completion?(item.url)
            }
        }
        present(alert, animated: true, completion: nil)
    }

}
