//
//  InputViewModel.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 9/8/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import RxSwift

protocol InputViewModel: class {

    // MARK: Properties

    var subtitleRepository: SubtitleRepository? { get set }
    var fileRepository: FileRepository { get }

}

extension InputViewModel {

    // MARK: Public functions

    func initSubtitleRepository() -> Completable {
        let url = fileRepository.getPathURL(for: .subtitleFile)
        return SubtitleRepository.initAsync(url: url)
            .do(onSuccess: { [weak self] in
                self?.subtitleRepository = $0 })
            .asCompletable()
    }

    func isTimeCloseToEndOfSubtitle(_ time: Double) -> Bool {
        return subtitleRepository?.isTimeCloseToEndOfSubtitle(time) ?? false
    }

    func getStartOfNextSubtitle(currentTime: Double) -> Double? {
        return subtitleRepository?.getStartOfNextSubtitle(currentTime: currentTime)
    }

    func getStartOfPrevSubtitle(currentTime: Double) -> Double? {
        return subtitleRepository?.getStartOfPrevSubtitle(currentTime: currentTime)
    }

    func getStartOfCurrentSubtitle() -> Double? {
        return subtitleRepository?.getStartOfCurrentSubtitle()
    }

    func cleanLastStop() {
        subtitleRepository?.cleanLastStop()
    }

    func getSubtitleForTime(_ time: Double) -> String? {
        return subtitleRepository?.getSubtitleForTime(time)
    }

    func getSourcePathURL() -> URL {
        return fileRepository.getPathURL(for: .videoFile)
    }

}
