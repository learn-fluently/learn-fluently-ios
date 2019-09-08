//
//  SubtitleRepository.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 2/9/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import RxCocoa
import RxSwift

class SubtitleRepository {

    // MARK: Constants

    private struct Constants {

        static let subtitleCloseThreshold: Double = 0.01
    }

    // MARK: Static functions

    static func initAsync(url: URL) -> Single<SubtitleRepository> {
        return Single
            .create { event -> Disposable in
                let queue = DispatchQueue(
                    label: String(describing: SubtitleRepository.self),
                    qos: .background
                )
                queue.async {
                    event(.success(SubtitleRepository(url: url)))
                }
                return Disposables.create()
            }
            .subscribeOn(MainScheduler.asyncInstance)
            .observeOn(MainScheduler.instance)
    }


    // MARK: Properties

    private var url: URL

    private var subtitle: Subtitles!

    private var lastSubtitleCloseEndTime: Double?


    // MARK: Lifecycle

    init(url: URL) {
        self.url = url
        self.subtitle = Subtitles(itemsFileUrl: url)
    }


    // MARK: Public functions

    func getSubtitleForTime(_ time: Double) -> String? {
        guard time > 0 else {
            return nil
        }
        let texts = subtitle.items.first {
            time < $0.end && time > $0.start
        }?.texts
        return getSubtitleByTexts(texts)
    }

    func isTimeCloseToEndOfSubtitle(_ time: Double) -> Bool {
        let text = subtitle.items.first {
            abs(time - $0.end) < Constants.subtitleCloseThreshold && lastSubtitleCloseEndTime != $0.end
        }
        if text != nil {
            lastSubtitleCloseEndTime = text?.end
            return true
        }
        return false
    }

    func getStartOfNextSubtitle(currentTime: Double) -> Double {
        return getStartOfSubtitle(currentTime: currentTime, next: true)
    }

    func getStartOfPrevSubtitle(currentTime: Double) -> Double {
        return getStartOfSubtitle(currentTime: currentTime, next: false)
    }

    func getStartOfCurrentSubtitle() -> Double? {
        guard let lastEnd = lastSubtitleCloseEndTime else {
            return nil
        }
        let text = subtitle.items.first {
            lastEnd == $0.end
        }
        return text?.start
    }

    func cleanLastStop() {
        lastSubtitleCloseEndTime = nil
    }


    // MARK: Private functions

    private func getStartOfSubtitle(currentTime: Double, next: Bool) -> Double {
        var time = currentTime
        var currentItem: SubtitleItem?
        repeat {
            currentItem = subtitle.items.first {
                (time <= $0.end && time > $0.start) ||
                (time < $0.end && time >= $0.start)
            }
            time -= Constants.subtitleCloseThreshold
        } while currentItem == nil && time > 0.0

        if currentItem == nil {
            return currentTime
        }

        guard let itemIndex = subtitle.items.firstIndex(where: { $0.index == currentItem?.index }) else {
            return currentTime
        }

        if next, itemIndex + 1 < subtitle.items.count {
            return subtitle.items[itemIndex + 1].start
        }

        if !next, itemIndex > 0, subtitle.items.count > 1 {
            return subtitle.items[itemIndex - 1].start
        } else if !next {
            return 0
        }

        return currentTime
    }

    private func getSubtitleByTexts(_ texts: [String]?) -> String? {
        return texts?.joined(separator: "\n")
    }

}
