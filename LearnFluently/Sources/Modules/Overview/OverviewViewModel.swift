//
//  OverviewViewModel.swift
//  Learn Fluently
//
//  Created by Amir on 07/09/2019.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import RxSwift
import Speech

class OverviewViewModel {

    // MARK: Properties

    var learingLanguageName: Observable<String> {
        return UserDefaultsService.shared.learingLanguageCodeObservable.map {
            (Locale.current as NSLocale).displayName(forKey: .identifier, value: $0) ?? ""
        }
    }

    var supportedLanguagesActions: [UIAlertAction.ActionData<String>] {
        return SFSpeechRecognizer.supportedLocales()
            .map {
                .init(identifier: $0.identifier,
                      title: locale.displayName(forKey: .identifier, value: $0.identifier) ?? "")
            }
            .sorted { actionA, actionB in
                actionA.title < actionB.title
            }
    }

    private var locale: NSLocale {
        return (Locale.current as NSLocale)
    }


    // MARK: Public functions

    func onLearningLanguageSelected(code: String) {
        UserDefaultsService.shared.learingLanguageCode = code
    }

}
