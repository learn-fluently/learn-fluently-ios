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
    private var currentPickerMode: SourcePikcerMode?
    private let fileRepository = FileRepository()
    private var lastSubtitleSourceName: String? = UserDefaultsService.shared.subtitleSourceName
    private var lastVideoSourceName: String? = UserDefaultsService.shared.videoSourceName
    private var sourceDownloaderService: SourceDownloaderService!


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
        sourceDownloaderService = SourceDownloaderService(hostViewController: self, delegate: self)
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
        if sourceType == .watching {
            show(WatchingViewController(), sender: nil)
        }
        if sourceType == .speaking {
            show(SpeakingViewController(), sender: nil)
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
                self?.startWizardForDownloadByDirectLink()

            case .youtube?:
                self?.sourceDownloaderService.startDownloadFromYoutubeWizard()

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
        self.present(documentPicker, animated: true, completion: nil)
    }

    private func startWizardForDownloadByDirectLink() {
        let title: String = currentPickerMode == .video ? .SOURCE_FILE_TITLE : .SUBTITLE_FILE_TITLE
        let desc: String = .SOURCE_OPTION_DIRECT_LINK
        sourceDownloaderService.startDownloadWizard(title: title,
                                                    desc: desc,
                                                    destUrl: getDestinationURL())
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

}


extension SourceConfigViewController: WebBrowserViewControllerDelegate {

    func getDownloadHandlerBlock(mimeType: String, url: URL) -> (() -> Void)? {
        let downloadHandler: () -> Void = { [weak self] in
            guard let `self` = self else {
                return
            }
            self.sourceDownloaderService.startDownload(url: url,
                                                       destUrl: self.getDestinationURL(),
                                                       isArchive: mimeType == "application/zip")
        }
        if currentPickerMode == .video, mimeType == "video/mp4" {
            return downloadHandler
        } else if currentPickerMode == .subtitle {
            if mimeType == "application/zip" {
                return downloadHandler
            } else if mimeType == "text/plain", url.absoluteString.hasSuffix(".srt") {
                return downloadHandler
            }
        }
        return nil
    }

}


extension SourceConfigViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            return
        }
        fileRepository.replaceItem(at: getDestinationURL(), with: url)
        askAndSetSourceName(defaultValue: url.lastPathComponent)
    }

}


extension SourceConfigViewController: SourceDownloaderServiceDelegate {

    func onSourceReady(deafulSourceName: String, isYoutube: Bool) {
        askAndSetSourceName(defaultValue: deafulSourceName, isYoutube: isYoutube)
    }

}
