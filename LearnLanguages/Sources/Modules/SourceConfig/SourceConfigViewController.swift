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

class SourceConfigViewController: BaseViewController, NibBasedViewController, UIDocumentPickerDelegate {

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
    private let fileDownloaderService = FileDownloaderService()
    private let disposeBag = DisposeBag()

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
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: Event handeling

    @IBAction private func closeButtonTouched() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction private func playButtonTouched() {
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


    // MARK: UIDocumentPickerDelegate

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            return
        }
        fileRepository.replaceItem(at: getDestinationURL(), with: url)

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
                self?.openBrowserInputDialog()

            case .directLink?:
                self?.openDirectLinkInputDialog()

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

    private func openDirectLinkInputDialog() {
        let title: String = currentPickerMode == .video ? .SOURCE_FILE_TITLE : .SUBTITLE_FILE_TITLE
        let desc: String = .SOURCE_OPTION_DIRECT_LINK
        presentInput(title: title, message: desc) { [weak self] directLink in
            guard let `self` = self,
                let link = directLink,
                let url = URL(string: link) else {
                    return
            }
            self.downloadFile(url: url)
        }
    }

    private func openBrowserInputDialog() {
        let title: String = currentPickerMode == .video ? .SOURCE_FILE_TITLE : .SUBTITLE_FILE_TITLE
        let desc: String = .SOURCE_OPTION_BROWSER
        presentInput(title: title, message: desc) { [weak self] directLink in
            guard let `self` = self,
                let link = directLink,
                let url = URL(string: link) else {
                    return
            }
            self.openWebView(url: url)
        }
    }

    private func downloadFile(url: URL) {
        let progressViewController = presentMessage(title: .DOWNLOADING)
        var progressText: String = ""
        fileDownloaderService
            .downloadFile(fromURL: url, toPath: getDestinationURL())
            .subscribeOn(MainScheduler.asyncInstance)
            .observeOn(MainScheduler.instance)
            .do(onNext: { event in
                if event.type == .progress, let data = event.progress {
                    progressText = "\(data.progress) %"
                    progressViewController.message = "\(progressText)\nspeed: \(data.speed)KB/s"
                } else if let message = event.messsage {
                    progressViewController.message = "\(progressText)\n\(message)"
                }
            },
                onError: { [weak self] error in
                    progressViewController.dismiss(animated: false, completion: nil)
                    self?.presentOKMessage(title: .ERROR, message: error.localizedDescription)
            },
                onCompleted: {
                    progressViewController.dismiss(animated: true, completion: nil)
            })
            .subscribe()
            .disposed(by: disposeBag)
    }

    private func openWebView(url: URL) {

    }

    private func configureTitleViews() {
        titleLabel.attributedText = pageTitle.set(style: Style.pageTitleTextStyle)
        subtitleLabel.attributedText = pageSubtitle.set(style: Style.pageSubtitleTextStyle)
        videoFileTitleLabel.attributedText = String.SOURCE_FILE_TITLE.set(style: Style.itemTitleTextStyle)
        videoFileDescriptionLabel.attributedText = String.SOURCE_FILE_DESC.set(style: Style.itemDescriptionTextStyle)
        subtitleFileTitleLabel.attributedText = String.SUBTITLE_FILE_TITLE.set(style: Style.itemTitleTextStyle)
        subtitleFileDescriptionLabel.attributedText = String.SUBTITLE_FILE_DESC.set(style: Style.itemDescriptionTextStyle)
    }

    private func getDestinationURL() -> URL {
        return currentPickerMode == .video ? fileRepository.getURLForVideoFile() : fileRepository.getURLForSubtitleFile()
    }
}
