//
//  DownloaderModels.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 4/18/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

struct DownloadUpdateEvent {

    // MARK: Constants

    enum `Type` {

        // MARK: Cases

        case info
        case progress
    }


    struct ProgressData {

        // MARK: Properties

        let progress: Int
        let speed: Int
    }


    // MARK: Static functions

    static func with(progress: ProgressData) -> DownloadUpdateEvent {
        return DownloadUpdateEvent(type: .progress,
                                   messsage: nil,
                                   error: nil,
                                   progress: progress)
    }

    static func with(info: String) -> DownloadUpdateEvent {
        return DownloadUpdateEvent(type: .info,
                                   messsage: info,
                                   error: nil,
                                   progress: nil)
    }


    // MARK: Properties

    let type: Type
    let messsage: String?
    let error: Error?
    let progress: ProgressData?

}
