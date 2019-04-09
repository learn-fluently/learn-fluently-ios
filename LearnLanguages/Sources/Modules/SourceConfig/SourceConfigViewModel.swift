//
//  SourceConfigViewModel.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 4/9/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

class SourceConfigViewModel {

    // MARK: Constants

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

    let title: String
    let subtitle: String

    private var lastSubtitleSourceName: String? = UserDefaultsService.shared.subtitleSourceName
    private var lastVideoSourceName: String? = UserDefaultsService.shared.videoSourceName
    private var currentPickerMode: SourcePikcerMode?
    private let fileRepository = FileRepository()
    private let youtubeSourceService = YoutubeSourceService()


    // MARK: Life cycle

    init(title: String, subtitle: String) {
        self.title = title
        self.subtitle = subtitle
    }

}
