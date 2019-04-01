//
//  SourceConfigViewController.swift
//  LearnLanguages
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


class SourceConfigViewController: BaseViewController, NibBasedViewController {

    // MARK: Constants

    enum SourceType {

        // MARK: Cases

        case watching
        case speaking
        case writing
    }

    enum SourcePikcerMode {

        // MARK: Cases

        case video
        case subtitle
    }

    enum SourcePickerOption: Int {

        // MARK: Cases

        case youtube
        case browser
        case directLink
        case documentPicker
    }


    // MARK: Properties

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    private let sourceType: SourceType
    private let pageTitle: String
    private let pageSubtitle: String
    private let fileRepository = FileRepository()
    private let youtubeSourceService = YoutubeSourceService()
    private let disposeBag = DisposeBag()
    private var currentPickerMode: SourcePikcerMode?
    private var lastSubtitleSourceName: String? = UserDefaultsService.shared.subtitleSourceName
    private var lastVideoSourceName: String? = UserDefaultsService.shared.videoSourceName
    private var sourceDownloaderService: SourceDownloaderService!
    private var downloadProgressViewController: UIAlertController?

    // MARK: Outlets

    @IBOutlet private weak var startButton: UIButton!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var videoFileTitleLabel: UILabel!
    @IBOutlet private weak var videoFileDescriptionLabel: UILabel!
    @IBOutlet private weak var subtitleFileTitleLabel: UILabel!
    @IBOutlet private weak var subtitleFileDescriptionLabel: UILabel!


    // MARK: Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTitleViews()
    }

    init(title: String, subtitle: String, type: SourceType) {
        sourceType = type
        pageTitle = title
        pageSubtitle = subtitle
        super.init(nibName: SourceConfigViewController.nibName, bundle: nil)
        sourceDownloaderService = SourceDownloaderService(delegate: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not available")
    }


    // MARK: Event handeling

    @IBAction private func closeButtonTouched() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction private func playButtonTouched() {
        if lastVideoSourceName != nil {
            UserDefaultsService.shared.videoSourceName = lastVideoSourceName
        }
        if lastSubtitleSourceName != nil {
            UserDefaultsService.shared.subtitleSourceName = lastSubtitleSourceName
        }
        switch sourceType {
        case .watching:
            show(WatchingViewController(), sender: nil)

        case .speaking:
            show(SpeakingViewController(), sender: nil)

        case .writing:
            show(WritingViewController(), sender: nil)
        }
    }

    @IBAction private func chooseVideoSourceButtonTouched() {
        openSourcePicker(mode: .video)
    }

    @IBAction private func chooseSubtitleSourceButtonTouched() {
        openSourcePicker(mode: .subtitle)
    }


    // MARK: Private functions

    private func openSourcePicker(mode: SourcePikcerMode) {
        currentPickerMode = mode

        let actions: [ActionData<SourcePickerOption>] = [
            ActionData(identifier: .browser, title: .SOURCE_OPTION_BROWSER),
            ActionData(identifier: .youtube, title: .SOURCE_OPTION_YOUTUBE),
            ActionData(identifier: .directLink, title: .SOURCE_OPTION_DIRECT_LINK),
            ActionData(identifier: .documentPicker, title: .SOURCE_OPTION_DOCUMENT)
        ]

        presentActionSheet(title: "", message: .CHOOSE_SOURCE_TITLE, actions: actions) { [weak self] selected in

            switch selected?.identifier {
            case .documentPicker?:
                self?.openFilePicker()

            case .browser?:
                self?.openWebView()

            case .directLink?:
                if let sequence = self?.startWizardForDownloadByDirectLink() {
                    self?.handleDownloadingSourceSequences([sequence])
                }

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
            guard let `self` = self else {
                return
            }

            var fileName = name ?? defaultValue
            if fileName.lengthOfBytes(using: .utf8) < 1 {
                fileName = defaultValue
            }
            self.updateSourceFileDescriptions(sourceName: fileName, isYoutube: isYoutube)
        }
    }

    private func openWebView() {
        let alert = UIAlertController(style: .actionSheet)
        let browserViewController = WebBrowserViewController(parentView: view)
        browserViewController.delegate = self
        alert.set(vc: browserViewController)
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = self.view //to set the source of your alert
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0) // you can set this as per your requirement.
            popoverController.permittedArrowDirections = [] //to hide the arrow of any particular direction
        }

        self.present(alert, animated: true, completion: nil)
    }

    private func configureTitleViews() {
        titleLabel.attributedText = pageTitle.set(style: Style.pageTitleTextStyle)
        subtitleLabel.attributedText = pageSubtitle.set(style: Style.pageSubtitleTextStyle)
        videoFileTitleLabel.attributedText = String.SOURCE_FILE_TITLE.set(style: Style.itemTitleTextStyle)
        subtitleFileTitleLabel.attributedText = String.SUBTITLE_FILE_TITLE.set(style: Style.itemTitleTextStyle)

        updateSourceFileDescriptions()
    }

    private func updateSourceFileDescriptions(sourceName: String? = nil, isYoutube: Bool = false) {
        if let sourceName = sourceName {
            if isYoutube {
                self.lastVideoSourceName = sourceName
                self.lastSubtitleSourceName = sourceName
            } else if self.currentPickerMode == .video {
                self.lastVideoSourceName = sourceName
            } else if self.currentPickerMode == .subtitle {
                self.lastSubtitleSourceName = sourceName
            }
        }

        let videoDesc = lastVideoSourceName ?? .SOURCE_FILE_DESC
        videoFileDescriptionLabel.attributedText = videoDesc.set(style: Style.itemDescriptionTextStyle)

        let subtitleDesc = lastSubtitleSourceName ?? .SUBTITLE_FILE_DESC
        subtitleFileDescriptionLabel.attributedText = subtitleDesc.set(style: Style.itemDescriptionTextStyle)
    }

    private func getDestinationURL() -> URL {
        return currentPickerMode == .video ? fileRepository.getPathURL(for: .videoFile) : fileRepository.getPathURL(for: .subtitleFile)
    }

    private func proccessSourceFileIfNeeded(url: URL, completion: ((URL) -> Void)?) {

        completion?(url)
    }

    private func present(_ error: Error) {
        if let downloadProgressViewController = downloadProgressViewController {
            downloadProgressViewController.dismiss(animated: false) { [weak self] in
                self?.presentOKMessage(title: .ERROR, message: error.localizedDescription)
            }
        } else {
            presentOKMessage(title: .ERROR, message: error.localizedDescription)
        }
    }

}


extension SourceConfigViewController {

    private func handleDownloadingSourceSequences(_ sequences: [Single<URL>]) {
        let completables = sequences.map {
            $0.do(onSuccess: { [weak self] url in
                if let `self` = self {
                    self.fileRepository.replaceItem(at: self.getDestinationURL(), with: url)
                    try? self.fileRepository.removeItem(at: url)
                }
                }, onError: { [weak self] error in
                    self?.present(error)
                })
                .asCompletable()
        }

        Completable
            .merge(completables)
            .do(onCompleted: { [weak self] in
                    self?.downloadProgressViewController?.dismiss(animated: true) { [weak self] in
                        self?.askAndSetSourceName(defaultValue: "")
                    }
                },
                onSubscribed: { [weak self] in
                    guard let `self` = self else {
                        return
                    }
                    if self.downloadProgressViewController == nil {
                        self.downloadProgressViewController = self.presentMessage(title: .DOWNLOADING)
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
            var type: SourceDownloaderService.SourceUrlType
            switch mimeType {

            case "application/zip":
                type = .archive

            case "application/octet-stream":
                type = .convertible

            default:
                type = .regular
            }
            self.handleDownloadingSourceSequences(
                [self.sourceDownloaderService.startDownload(url: url, type: type)]
            )
        }

        var isSupported = false

        if currentPickerMode == .video {
            if mimeType == "video/mp4" ||
                (mimeType == "application/octet-stream" && url.pathExtension.lowercased() == "mkv") {
                isSupported = true
            }
        } else if currentPickerMode == .subtitle {
            if mimeType == "application/zip" {
                isSupported = true
            } else if mimeType == "text/plain", url.pathExtension.lowercased() == "srt" {
                isSupported = true
            }
        }

        return isSupported ? downloadHandler : nil
    }

}


extension SourceConfigViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            return
        }
        let destinationURL = getDestinationURL()
        proccessSourceFileIfNeeded(url: url) { [weak self] url in
            self?.fileRepository.replaceItem(at: destinationURL, with: url)
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
        present(alert, animated: true, completion: nil)
    }

    func convertFile(url: URL, completion: ((URL?, Error?) -> Void)?) {
        if !fileRepository.fileExists(at: url) {
            completion?(nil, Errors.Download.convert("source file doesn't exist"))//TODO:
        }
        var srcVideoUrl = url
        if srcVideoUrl.pathExtension.isEmpty {
            let newUrl = srcVideoUrl.appendingPathExtension("mkv")
            try? fileRepository.moveItem(at: srcVideoUrl, to: newUrl)
            srcVideoUrl = newUrl
        }
        let destVideoUrl = fileRepository.getPathURL(for: .temporaryFileForConvert).appendingPathExtension("mp4")
        try? fileRepository.removeItem(at: destVideoUrl)

        let command = "-i \(srcVideoUrl.path) -codec copy \(destVideoUrl.path)"
        let queue = DispatchQueue(
            label: String(describing: SourceConfigViewController.self),
            qos: .background
        )
        queue.async { [weak self] in
            MobileFFmpeg.execute(command)
            if self?.fileRepository.fileExists(at: destVideoUrl) == true {
                completion?(destVideoUrl, nil)
                ((try? self?.fileRepository.removeItem(at: srcVideoUrl)) as ()??)
            } else {
                completion?(nil, Errors.Download.convert("failed to convert"))//TODO:
            }
        }
    }

    func onProgressUpdate(message: String) {
        downloadProgressViewController?.message = message
    }

}


extension SourceConfigViewController {

    private func startWizardForDownloadByDirectLink() -> Single<URL> {
        let title: String = currentPickerMode == .video ? .SOURCE_FILE_TITLE : .SUBTITLE_FILE_TITLE
        let desc: String = .SOURCE_OPTION_DIRECT_LINK
        return startDownloadWizard(title: title, desc: desc)
    }

    private func startDownloadWizard(title: String, desc: String, isArchive: Bool = false) -> Single<URL> {
        return getLinkByInputDialog(title: title, desc: desc).flatMap { [weak self] url -> Single<URL> in
            self?.sourceDownloaderService.startDownload(url: url) ?? .never()
        }
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
        getLinkByInputDialog(title: .ENTER_YOUTUBE_LINK)
            .flatMap { [weak self] url -> Single<YoutubeSourceService.YoutubeVideoInfo> in
                self?.youtubeSourceService.getVideoInfo(url: url) ?? .never()
            }
            .flatMap { [weak self] videoInfo -> Single<[SourcePikcerMode: URL]> in
                self?.showVideoAndSubtitleDialogs(videoInfo: videoInfo) ?? .never()
            }
            .subscribeOn(MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] urls in
                    let sequences = urls.compactMap({ pickerMode, url in
                        self?.sourceDownloaderService.startDownload(url: url).do(onSuccess: { [weak self] _ in
                            self?.currentPickerMode = pickerMode
                        })
                    })
                    self?.handleDownloadingSourceSequences(sequences)
                },
                onError: { [weak self] error in
                    self?.present(error)
                })
            .disposed(by: disposeBag)
            }

    private func showVideoAndSubtitleDialogs(videoInfo: YoutubeSourceService.YoutubeVideoInfo) -> Single<[SourcePikcerMode: URL]> {
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
