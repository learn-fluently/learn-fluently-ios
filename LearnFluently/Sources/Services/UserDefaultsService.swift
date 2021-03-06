//
//  UserDefaultsService.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 2/16/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import RxCocoa
import RxSwift

class UserDefaultsService {

    // MARK: Constants

    private enum Key: String {

        // MARK: Cases

        case subtitleSourceName
        case videoSourceName
        case learingLanguageCode
    }

    static let shared = UserDefaultsService()


    // MARK: Public properties

    var subtitleSourceName: BehaviorRelay<String?> {
        return getBehaviorRelayForKey(.subtitleSourceName)
    }

    var videoSourceName: BehaviorRelay<String?> {
        return getBehaviorRelayForKey(.videoSourceName)
    }

    var learingLanguageCodeObservable: Observable<String> {
        return getBehaviorRelayForKey(.learingLanguageCode).map({ $0 ?? self.learingLanguageCode })
    }

    var learingLanguageCode: String {
        set { getBehaviorRelayForKey(.learingLanguageCode).accept(newValue) }
        get { return get(key: .learingLanguageCode) ?? "en-US" }
    }


    // MARK: Private properties

    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder
    private var behaviorRelays: [Key: Any] = [:]
    private let disposeBag = DisposeBag()


    // MARK: Lifecycle

    init() {
        self.jsonEncoder = JSONEncoder()
        self.jsonDecoder = JSONDecoder()
    }


    // MARK: Private functions

    private func set<T: Encodable>(key: Key, value: T?) {
        let data: Any
        if let value = value {
            do {
                data = try jsonEncoder.encode(value)
            } catch {
                //try to store the value itself
                data = value
            }
            UserDefaults.standard.set(data, forKey: key.rawValue)
        } else {
            UserDefaults.standard.removeObject(forKey: key.rawValue)
        }
    }

    private func get<T: Decodable>(key: Key) -> T? {
        if let value = UserDefaults.standard.value(forKey: key.rawValue) as? Data {
            do {
                return try jsonDecoder.decode(T.self, from: value)
            } catch {
                NSLog("Failed to decode data for: \(key.rawValue)")
                return nil
            }
        } else if let value = UserDefaults.standard.value(forKey: key.rawValue) as? T {
            return value
        }
        return nil
    }

    private func getBehaviorRelayForKey<T: Codable>(_ key: Key) -> BehaviorRelay<T?> {
        if let observable = behaviorRelays[key] as? BehaviorRelay<T?> {
            return observable
        }
        let currentValue: T? = get(key: key)
        let newBehaviorRelay = BehaviorRelay(value: currentValue)
        newBehaviorRelay
            .skip(1)
            .subscribe(onNext: { [weak self] newValue in
                self?.set(key: key, value: newValue)
            })
            .disposed(by: disposeBag)
        behaviorRelays[key] = newBehaviorRelay
        return newBehaviorRelay
    }

}
