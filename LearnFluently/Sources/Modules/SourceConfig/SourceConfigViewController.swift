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

    func onPlayButtonTouched(viewController: SourceConfigViewController)

    func onCloseButtonTouched(viewController: SourceConfigViewController)

}


class SourceConfigViewController: BaseViewController, NibBasedViewController {

    // MARK: Properties

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    private let disposeBag = DisposeBag()
    private var progressViewController: UIAlertController?

    let viewModel: SourceConfigViewModel
    private weak var delegate: SourceConfigViewControllerDelegate?

    @IBOutlet private weak var startButton: UIButton!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var videoFileTitleLabel: UILabel!
    @IBOutlet private weak var videoFileDescriptionLabel: UILabel!
    @IBOutlet private weak var subtitleFileTitleLabel: UILabel!
    @IBOutlet private weak var subtitleFileDescriptionLabel: UILabel!


    // MARK: Lifecycle

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
        configureViews()
    }


    // MARK: Event handeling

    @IBAction private func closeButtonTouched() {
        delegate?.onCloseButtonTouched(viewController: self)
    }

    @IBAction private func playButtonTouched() {
        if viewModel.canPlay {
            delegate?.onPlayButtonTouched(viewController: self)
        } else {
            showAlert(.PLEASE_MAKE_SURE_SOURCE_SELECTED)
        }
    }

    @IBAction private func chooseVideoSourceButtonTouched() {
        startPickingSource(sourceInfo: .init(type: .video))
    }

    @IBAction private func chooseSubtitleSourceButtonTouched() {
        startPickingSource(sourceInfo: .init(type: .subtitle))
    }


    // MARK: Private functions

    private func startPickingSource(sourceInfo: SourceInfo) {
        createSelectingPicker(sourceInfo: sourceInfo)
            .flatMap(weak: self) {
                try $0.createPicker(sourceInfo: $1)
            }
            .flatMap(weak: self) {
                $0.viewModel.createDownloaderIfNeeded(sourceInfo: $1)
            }
            .flatMap(weak: self) {
                $0.viewModel.createSaver(sourceInfo: $1)
            }
            .flatMap(weak: self) {
                $0.createExtractorIfNeeded(sourceInfo: $1)
            }
            .do(onSuccess: {
                if !$0.isSupported {
                    throw Errors.Source.unsupported(.ERROR_SOURCE_NOT_SUPPORTED)
                }
            })
            .flatMap(weak: self) {
                $0.viewModel.createConverterIfNeeded(sourceInfo: $1)
            }
            .flatMap(weak: self) {
                $0.createAskAndSetSourceName(sourceInfo: $1)
            }
            .do(
                onSuccess: { [weak self] sourceInfo in
                    if let sourceInfo = sourceInfo.getNextAutoPickSourceInfo() {
                        self?.startPickingSource(sourceInfo: sourceInfo)
                    }
                },
                onError: { [weak self] error in
                    self?.present(error)
                }
            )
            .subscribeOn(MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe()
            .disposed(by: disposeBag)
    }

    private func createPicker(sourceInfo: SourceInfo) throws -> Single<SourceInfo> {
        switch sourceInfo.picker {
        case .sample?:
            try viewModel.loadSampleFiles()
            return .never()

        case .documentPicker?:
            return createFilePicker(sourceInfo: sourceInfo)

        case .browser?:
            return createWebBrowserPicker(sourceInfo: sourceInfo)

        case .directLink?:
            return createDirectLinkGetter(sourceInfo: sourceInfo)

        case .youtube?:
            return createYoutubeLinkGetter(sourceInfo: sourceInfo)
                .flatMap(weak: self) {
                    $0.viewModel.createYoutubeInfoGetter(sourceInfo: $1)
                }
                .flatMap(weak: self) {
                    $0.createYoutubeOptionChooser(sourceInfo: $1)
                }

        case .auto?:
            return .just(sourceInfo)

        case .none:
            return .never()
        }
    }

    private func createExtractorIfNeeded(sourceInfo: SourceInfo) -> Single<SourceInfo> {
        guard sourceInfo.isArchive else {
            return .just(sourceInfo)
        }
        return viewModel.createExtractor(sourceInfo: sourceInfo)
            .flatMap { sourceInfo in
                .create { [weak self] event in
                    self?.showChooseOneURL(urls: sourceInfo.extractedFiles) { [weak self] url in
                        do {
                            let sourceInfo = try self?.viewModel.selectItemFromExtractedDir(sourceInfo: sourceInfo, selectedURL: url) ?? sourceInfo
                            event(.success(sourceInfo))
                        } catch {
                            event(.error(error))
                        }
                    }
                    return Disposables.create()
                }
            }
    }

    private func createAskAndSetSourceName(sourceInfo: SourceInfo) -> Single<SourceInfo> {
        if sourceInfo.picker == .auto {
            dismissProgressDialog()
            return .just(sourceInfo)
        }
        return .create { [weak self] event in
            self?.dismissProgressDialog {
                self?.presentInput(title: .ENTER_SOURCE_NAME, defaultValue: sourceInfo.defaultName) { [weak self] name in
                    guard let self = self else {
                        return
                    }
                    var selectedName = name ?? sourceInfo.defaultName
                    if selectedName.lengthOfBytes(using: .utf8) < 1 {
                        selectedName = sourceInfo.defaultName
                    }
                    var sourceInfo = sourceInfo
                    sourceInfo.selectedName = selectedName
                    self.viewModel.updateSourceFileDescriptions(sourceInfo: sourceInfo)
                    event(.success(sourceInfo))
                }
            }
            return Disposables.create()
        }
    }

    private func createSelectingPicker(sourceInfo: SourceInfo) -> Single<SourceInfo> {
        if sourceInfo.picker != nil {
            return .just(sourceInfo)
        }
        return .create { [weak self] event -> Disposable in
            guard let self = self else {
                return Disposables.create()
            }
            self.presentActionSheet(title: "", message: .CHOOSE_ONE_OPTION, actions: self.viewModel.sourcePickerOptions) { selected in
                    guard let selected = selected else {
                        return
                    }
                    var sourceInfo = sourceInfo
                    sourceInfo.picker = selected.identifier
                    event(.success(sourceInfo))
            }
            return Disposables.create()
        }
    }

    private func createFilePicker(sourceInfo: SourceInfo) -> Single<SourceInfo> {
        return RxImportDocumentPickerViewController().createPresenter(viewController: self).map {
            var sourceInfo = sourceInfo
            sourceInfo.sourceURL = $0
            return sourceInfo
        }
    }

    private func createWebBrowserPicker(sourceInfo: SourceInfo) -> Single<SourceInfo> {
        return RxSourceWebBrowserViewController(viewController: self).createPresenter(sourceInfo: sourceInfo)
    }

    private func createDirectLinkGetter(sourceInfo: SourceInfo) -> Single<SourceInfo> {
        return self.getSourceInfoLinkByInputDialog(title: sourceInfo.typeName, desc: .SOURCE_OPTION_DIRECT_LINK, sourceInfo: sourceInfo)
    }

    private func createYoutubeLinkGetter(sourceInfo: SourceInfo) -> Single<SourceInfo> {
        let title: String = .SOURCE_OPTION_YOUTUBE
        let desc: String = .ENTER_YOUTUBE_LINK
        return self.getSourceInfoLinkByInputDialog(title: title, desc: desc, sourceInfo: sourceInfo)
    }

    private func getSourceInfoLinkByInputDialog(title: String, desc: String, sourceInfo: SourceInfo) -> Single<SourceInfo> {
        return self.getLinkByInputDialog(title: title, desc: desc).map { url in
            var sourceInfo = sourceInfo
            sourceInfo.sourceURL = url
            return sourceInfo
        }
    }

    private func configureViews() {
        titleLabel.setText(viewModel.pageInfo.title, style: .pageTitleTextStyle)
        subtitleLabel.setText(viewModel.pageInfo.description, style: .pageSubtitleTextStyle)

        viewModel.videoFileDescriptionObservable
            .subscribe(onNext: { [weak self] in
                self?.videoFileDescriptionLabel.setText($0, style: .itemDescriptionTextStyle)
            })
            .disposed(by: disposeBag)

        viewModel.subtitleFileDescriptionObservable
            .subscribe(onNext: { [weak self] in
                self?.subtitleFileDescriptionLabel.setText($0, style: .itemDescriptionTextStyle)
            })
            .disposed(by: disposeBag)

        viewModel.progressMessageObservable
            .subscribe(onNext: { [weak self] message in
                guard let self = self else {
                    return
                }
                if self.progressViewController == nil, !message.isEmpty {
                    self.progressViewController = self.presentMessage()
                }
                self.progressViewController?.title = message.title
                self.progressViewController?.message = message.description
            })
            .disposed(by: disposeBag)
    }

    private func present(_ error: Error) {
        dismissProgressDialog { [weak self] in
            self?.presentOKMessage(title: .ERROR, message: error.localizedDescription)
        }
    }

    private func dismissProgressDialog(completion: (() -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            if let progressViewController = self?.progressViewController {
                progressViewController.dismiss(animated: true) {
                    completion?()
                    self?.progressViewController = nil
                }
            } else {
                completion?()
            }
        }
    }

    private func getLinkByInputDialog(title: String, desc: String = "") -> Single<URL> {
        return .create(subscribe: { [weak self] event -> Disposable in
            self?.presentInput(title: title, message: desc) { inputLink in
                guard let link = inputLink, let url = URL(string: link) else {
                        return
                }
                event(.success(url))
            }
            return Disposables.create()
        })
    }

    private func showChooseOneURL(urls: [URL], completion: ((URL) -> Void)? = nil) {
        let alert = UIAlertController(style: .actionSheet, title: "", message: .CHOOSE_ONE_OPTION)
        urls.forEach { url in
            alert.addAction(title: url.lastPathComponent) { _ in
                completion?(url)
            }
        }
        dismissProgressDialog { [weak self] in
            self?.present(alert, animated: true)
        }
    }

}


extension SourceConfigViewController {

    private func createYoutubeOptionChooser(sourceInfo: SourceInfo) -> Single<SourceInfo> {
        guard let youtubeVideoInfo = sourceInfo.youtubeVideoInfo else {
            return .just(sourceInfo)
        }
        return showVideoAndSubtitleDialogs(videoInfo: youtubeVideoInfo).map {
            var sourceInfo = sourceInfo
            sourceInfo.youtubeSelectedUrls = $0
            sourceInfo.sourceURL = $0[sourceInfo.type]
            return sourceInfo
        }
    }

    private func showVideoAndSubtitleDialogs(videoInfo: Youtube.VideoInfo) -> Single<[SourceInfo.`Type`: URL]> {
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
            return Disposables.create()
        }
    }

    private func showChooseVideoQuality(videoInfo: Youtube.VideoInfo?, completion: ((URL) -> Void)? = nil) {
        let alert = UIAlertController(style: .actionSheet, title: "", message: .YOUTUBE_QUALITY_CHOOSE)
        videoInfo?.videos.forEach { item in
            alert.addAction(title: item.name) { _ in
                completion?(item.url)
            }
        }
        present(alert, animated: true, completion: nil)
    }

    private func showChooseSubtitle(videoInfo: Youtube.VideoInfo?, completion: ((URL) -> Void)? = nil) {
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
