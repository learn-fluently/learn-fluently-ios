//
//  String+Localizable.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 2/16/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import Foundation

extension String {

    // swiftlint:disable identifier_name
    //start-of-generated-keys//
    static let CANCEL = "CANCEL".localize()
    static let CHOOSE_ONE_OPTION = "CHOOSE_ONE_OPTION".localize()
    static let CONVERTING = "CONVERTING".localize()
    static let DOWNLOADER_CONNECTION_WAITING = "DOWNLOADER_CONNECTION_WAITING".localize()
    static let DOWNLOADER_ERROR_NO_DEST = "DOWNLOADER_ERROR_NO_DEST".localize()
    static let DOWNLOADER_MOVING_FILE = "DOWNLOADER_MOVING_FILE".localize()
    static let DOWNLOADER_RESUMING = "DOWNLOADER_RESUMING".localize()
    static let DOWNLOADER_RETRYING = "DOWNLOADER_RETRYING".localize()
    static let DOWNLOADING = "DOWNLOADING".localize()
    static let DOWNLOAD_SPEED = "DOWNLOAD_SPEED".localize()
    static let DOWNLOAD_SUCCESSFUL = "DOWNLOAD_SUCCESSFUL".localize()
    static let ENTER_SOURCE_NAME = "ENTER_SOURCE_NAME".localize()
    static let ENTER_YOUTUBE_LINK = "ENTER_YOUTUBE_LINK".localize()
    static let ERROR = "ERROR".localize()
    static let ERROR_SOURCE_NOT_SUPPORTED = "ERROR_SOURCE_NOT_SUPPORTED".localize()
    static let EXTRACTING = "EXTRACTING".localize()
    static let FAILED_TO_GET_CONTENTS_OF_ZIP_FILE = "FAILED_TO_GET_CONTENTS_OF_ZIP_FILE".localize()
    static let FAILED_TO_GET_YOUTUBE_LINKS = "FAILED_TO_GET_YOUTUBE_LINKS".localize()
    static let MENU_ITEM_GOOGLE_IMAGES = "MENU_ITEM_GOOGLE_IMAGES".localize()
    static let MENU_ITEM_GOOGLE_SEARCH = "MENU_ITEM_GOOGLE_SEARCH".localize()
    static let MENU_ITEM_SPEECH = "MENU_ITEM_SPEECH".localize()
    static let MENU_ITEM_TRANSLATE = "MENU_ITEM_TRANSLATE".localize()
    static let OK = "OK".localize()
    static let SECTION_SPEAKING_DESC = "SECTION_SPEAKING_DESC".localize()
    static let SECTION_SPEAKING_TITLE = "SECTION_SPEAKING_TITLE".localize()
    static let SECTION_WATCHING_DESC = "SECTION_WATCHING_DESC".localize()
    static let SECTION_WATCHING_TITLE = "SECTION_WATCHING_TITLE".localize()
    static let SECTION_WRITING_DESC = "SECTION_WRITING_DESC".localize()
    static let SECTION_WRITING_TITLE = "SECTION_WRITING_TITLE".localize()
    static let SOURCE_FILE_DESC = "SOURCE_FILE_DESC".localize()
    static let SOURCE_FILE_TITLE = "SOURCE_FILE_TITLE".localize()
    static let SOURCE_OPTION_BROWSER = "SOURCE_OPTION_BROWSER".localize()
    static let SOURCE_OPTION_DIRECT_LINK = "SOURCE_OPTION_DIRECT_LINK".localize()
    static let SOURCE_OPTION_DOCUMENT = "SOURCE_OPTION_DOCUMENT".localize()
    static let SOURCE_OPTION_YOUTUBE = "SOURCE_OPTION_YOUTUBE".localize()
    static let SUBTITLE_FILE_DESC = "SUBTITLE_FILE_DESC".localize()
    static let SUBTITLE_FILE_TITLE = "SUBTITLE_FILE_TITLE".localize()
    static let YOUTUBE_QUALITY_CHOOSE = "YOUTUBE_QUALITY_CHOOSE".localize()
    static let YOUTUBE_SUBTITLE_AUTO_GENERATED = "YOUTUBE_SUBTITLE_AUTO_GENERATED".localize()
    static let YOUTUBE_SUBTITLE_CHOOSE = "YOUTUBE_SUBTITLE_CHOOSE".localize()
    static let YOUTUBE_VIDEO_HD = "YOUTUBE_VIDEO_HD".localize()
    static let YOUTUBE_VIDEO_MEDIUM = "YOUTUBE_VIDEO_MEDIUM".localize()
    static let YOUTUBE_VIDEO_SMALL = "YOUTUBE_VIDEO_SMALL".localize()
    //end-of-generated-keys//
}

extension String {

    func localize(withComment comment: String? = nil) -> String {
        return NSLocalizedString(self, comment: comment ?? "")
    }

}
