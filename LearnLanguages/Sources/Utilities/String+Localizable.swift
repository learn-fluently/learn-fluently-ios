// swiftlint:disable file_header
// swiftlint:disable identifier_name
import Foundation

extension String {

    static let CANCEL = "CANCEL".localize()
    static let CHOOSE_SOURCE_TITLE = "CHOOSE_SOURCE_TITLE".localize()
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

}

extension String {

    func localize(withComment comment: String? = nil) -> String {
        return NSLocalizedString(self, comment: comment ?? "")
    }

}
