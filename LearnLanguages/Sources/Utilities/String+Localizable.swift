//
//  String+Localizable.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 2/16/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import Foundation

extension String {

    // swiftlint:disable identifier_name
    //start-of-generated-keys//
    static let CANCEL = "CANCEL".localize()
    static let CHOOSE_SOURCE_TITLE = "CHOOSE_SOURCE_TITLE".localize()
    static let DOWNLOADER_CONNECTION_WAITING = "DOWNLOADER_CONNECTION_WAITING".localize()
    static let DOWNLOADER_ERROR_NO_DEST = "DOWNLOADER_ERROR_NO_DEST".localize()
    static let DOWNLOADER_MOVING_FILE = "DOWNLOADER_MOVING_FILE".localize()
    static let DOWNLOADER_RESUMING = "DOWNLOADER_RESUMING".localize()
    static let DOWNLOADER_RETRYING = "DOWNLOADER_RETRYING".localize()
    static let DOWNLOADING = "DOWNLOADING".localize()
    static let ERROR = "ERROR".localize()
    static let MENU_ITEM_GOOGLE_IMAGES = "MENU_ITEM_GOOGLE_IMAGES".localize()
    static let MENU_ITEM_GOOGLE_SEARCH = "MENU_ITEM_GOOGLE_SEARCH".localize()
    static let MENU_ITEM_SPEECH = "MENU_ITEM_SPEECH".localize()
    static let MENU_ITEM_TRANSLATE = "MENU_ITEM_TRANSLATE".localize()
    static let OK = "OK".localize()
    static let SOURCE_OPTION_BROWSER = "SOURCE_OPTION_BROWSER".localize()
    static let SOURCE_OPTION_DIRECT_LINK = "SOURCE_OPTION_DIRECT_LINK".localize()
    static let SOURCE_OPTION_DOCUMENT = "SOURCE_OPTION_DOCUMENT".localize()
    static let SOURCE_OPTION_YOUTUBE = "SOURCE_OPTION_YOUTUBE".localize()
    //end-of-generated-keys//
}

extension String {

    func localize(withComment comment: String? = nil) -> String {
        return NSLocalizedString(self, comment: comment ?? "")
    }

}
