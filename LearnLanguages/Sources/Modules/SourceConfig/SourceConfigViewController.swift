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


    // MARK: Outlets

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!


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
        let fileRepo = FileRepository()
        let toUrl = currentPickerMode == .video ? fileRepo.getURLForVideoFile() : fileRepo.getURLForSubtitleFile()
        try? FileManager.default.removeItem(at: toUrl)
        do {
            try FileManager.default.copyItem(at: url, to: toUrl)
        } catch {
            print(error)
        }
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
                self?.openFilePicker()
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


    private func configureTitleViews() {
        titleLabel.attributedText = pageTitle.set(style: Style.pageTitleTextStyle)
        subtitleLabel.attributedText = pageSubtitle.set(style: Style.pageSubtitleTextStyle)
    }
}
