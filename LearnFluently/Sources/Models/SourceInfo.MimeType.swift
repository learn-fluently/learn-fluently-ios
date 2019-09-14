//
//  SourceMetaData.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 4/17/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

extension SourceInfo {

    // MARK: Constants

    struct MimeType {

        // MARK: Properties

        let type: Type
        let rawValue: String


        // MARK: Lifecycle

        init(rawValue: String) {
            self.rawValue = rawValue

            let type: Type
            switch rawValue {
            case "video/mp4":
                type = .video
            case "application/zip":
                type = .archive
            case "text/plain":
                type = .text

            default:
                type = .unknown
            }
            self.type = type
        }
    }
}


extension SourceInfo.MimeType {

    // MARK: Constants

    enum `Type` {

        // MARK: Cases

        case video
        case archive
        case text
        case unknown
    }

}
