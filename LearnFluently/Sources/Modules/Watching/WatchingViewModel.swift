//
//  WatchingViewModel.swift
//  Learn Fluently
//
//  Created by Amir on 07/09/2019.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import Foundation
import AVFoundation
import AVKit
import RxSwift

class WatchingViewModel {

    // MARK: Properties

    private var subtitleRepository: SubtitleRepository?
    private let fileRepository: FileRepository
    private let speechSynthesizer = AVSpeechSynthesizer()
    private let disposeBag = DisposeBag()

    // MARK: Lifecycle

    init(fileRepository: FileRepository) {
        self.fileRepository = fileRepository
    }


    // MARK: Public functions

    func initSubtitleRepository() -> Completable {
        let url = fileRepository.getPathURL(for: .subtitleFile)
        return SubtitleRepository.initAsync(url: url)
            .do(onSuccess: { [weak self] in
                self?.subtitleRepository = $0 })
            .asCompletable()
    }

    func getSourcePathURL() -> URL {
        return fileRepository.getPathURL(for: .videoFile)
    }

    func getSubtitleForTime(_ time: Double) -> String? {
        return subtitleRepository?.getSubtitleForTime(time)
    }

    func speechText(_ text: String?) {
        guard let text = text else {
            return
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: UserDefaultsService.shared.learingLanguageCode)
        speechSynthesizer.speak(utterance)
    }

}
