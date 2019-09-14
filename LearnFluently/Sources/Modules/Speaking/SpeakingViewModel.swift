//
//  SpeakingViewModel.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 9/8/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import RxSwift
import RxCocoa
import Speech

class SpeakingViewModel: NSObject, InputViewModel {

    // MARK: Properties

    var subtitleRepository: SubtitleRepository?
    var fileRepository: FileRepository
    var descriptionTextObservable: Observable<String> {
        return descriptionTextBehaviorRelay.asObservable()
    }

    var isRecording: Bool {
        return speechRecognizer?.isRecording ?? false
    }

    var isRecordingObservable: Observable<Bool> {
        return isRecordingBehaviorRelay.asObservable()
    }

    var bestTranscription: String {
        return speechRecognizer?.bestTranscription ?? ""
    }

    private(set) var isRecordingPossible = true

    private var onError: ((String) -> Void)?
    private let speechRecognizer: SpeechRecognizerService?
    private let descriptionTextBehaviorRelay = BehaviorRelay(value: "")
    private let isRecordingBehaviorRelay: BehaviorRelay<Bool>
    private let disposeBag = DisposeBag()


    // MARK: Lifecycle

    init(fileRepository: FileRepository) {
        self.fileRepository = fileRepository
        self.speechRecognizer = SpeechRecognizerService(
            locale: Locale(identifier: UserDefaultsService.shared.learingLanguageCode)
        )
        isRecordingBehaviorRelay = BehaviorRelay(value: speechRecognizer?.isRecording ?? false)
    }


    // MARK: Public functions

    func requestAuthorization() -> Single<Bool> {
        guard let speechRecognizer = speechRecognizer else {
            return .never()
        }
        return .create(subscribe: { subscribe -> Disposable in
            speechRecognizer.requestAuthorization { isAuthorized, errorDescription in
                if let desc = errorDescription {
                    subscribe(.error(SpeechAuthorizationError(errorDescription: desc)))
                } else {
                    subscribe(.success(isAuthorized))
                }
            }
            return Disposables.create {}
        })
    }

    func configureSpeechRecognizerService(onError: @escaping (String) -> Void) {
        self.onError = onError
        speechRecognizer?.delegate = self
        speechRecognizer?.recordingDelegate = self
        speechRecognizer?.bestTranscriptionObservable
            .subscribe(onNext: { [weak self] value in
                self?.descriptionTextBehaviorRelay.accept(value ?? "")
            })
            .disposed(by: self.disposeBag)
    }

    func startRecognition() throws {
        try speechRecognizer?.startRecognition()
    }

    func stopRecognitionTaskIfNeeded(keepResult: Bool) {
        speechRecognizer?.stopRecognitionTaskIfNeeded(cancel: !keepResult)
    }

}


extension SpeakingViewModel: SFSpeechRecognizerDelegate, SpeechRecognizerRecordingDelegate {


    // MARK: Functions

    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if !available {
            isRecordingPossible = false
            onError?(.ERROR_RECOGNATION_NOT_AVAILABLE)
            descriptionTextBehaviorRelay.accept("")
        }
    }

    func onRecordingStateChanged(isRecording: Bool) {
        if isRecording {
            descriptionTextBehaviorRelay.accept(.START_SPEAKING_HINT)
        } else if speechRecognizer?.bestTranscription == nil {
            descriptionTextBehaviorRelay.accept("")
        }
        isRecordingBehaviorRelay.accept(isRecording)
    }

}


extension SpeakingViewModel {

    struct SpeechAuthorizationError: LocalizedError {

        var errorDescription: String?
    }
}
