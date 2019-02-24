//
//  Subtitles.swift
//  LearnLanguages
//
//  Created by Amir Khorsandi on 12/26/18.
//  Copyright © 2018 Amir Khorsandi. All rights reserved.
//

import Foundation
import SWXMLHash

struct Subtitle {

    // MARK: Constants

    enum ParseError: Error {
        case failed
        case invalidFormat
    }


    // MARK: Properties

    private(set) var items: [SubtitleItem] = []


    // MARK: Life cycle

    public init(fileUrl: URL) {

        do {
            let fileContent = try String(contentsOf: fileUrl, encoding: String.Encoding.utf8)
            do {
                if isXML(fileContent: fileContent) {
                    items = self.parseXMLSub(fileContent)
                } else {
                    items = try self.parseSRTSub(fileContent)
                }
            } catch {
                debugPrint(error)
            }
        } catch {
            debugPrint(error)
        }
    }


    // MARK: Private functions

    private func isXML(fileContent: String) -> Bool {
        return fileContent.starts(with: "<?xml")
    }

    private func parseXMLSub(_ rawXML: String) -> [SubtitleItem] {
        let delay = 0.0
        let xml = SWXMLHash.parse(rawXML)
        var items: [SubtitleItem] = []
        var index = 0
        let texts = xml["transcript"].children
        texts.forEach { xmlIndexer in
            guard let element = xmlIndexer.element,
                let start = element.attribute(by: "start")?.text,
                let duration = element.attribute(by: "dur")?.text else {
                    return
            }
            var end = delay + (Double(start) ?? 0) + (Double(duration) ?? 0)
            if index + 1 < texts.count {
                if let endText = texts[index + 1].element!.attribute(by: "start")?.text {
                    end = delay + (Double(endText) ?? 0) - 0.01
                }
            }

            items.append(
                SubtitleItem(
                    texts: [htmlToText(encodedString: element.text)],
                    start: delay + (Double(start) ?? 0),
                    end: end,
                    index: index + 1
                )
            )
            index += 1
        }
        return items
    }

    private func parseSRTSub(_ rawSub: String) throws -> [SubtitleItem] {
        var allTitles = [SubtitleItem]()
        var components = rawSub.components(separatedBy: "\r\n\r\n")

        // Fall back to \n\n separation
        if components.count == 1 {
            components = rawSub.components(separatedBy: "\n\n")
        }

        for component in components {
            if component.isEmpty {
                continue
            }

            let scanner = Scanner(string: component)

            var indexResult: Int = -99
            var startResult: NSString?
            var endResult: NSString?
            var textResult: NSString?

            let indexScanSuccess = scanner.scanInt(&indexResult)
            let startTimeScanResult = scanner.scanUpToCharacters(from: CharacterSet.whitespaces, into: &startResult)
            let dividerScanSuccess = scanner.scanUpTo("> ", into: nil)
            scanner.scanLocation += 2
            let endTimeScanResult = scanner.scanUpToCharacters(from: CharacterSet.newlines, into: &endResult)
            scanner.scanLocation += 1

            var textLines = [String]()

            // Iterate over text lines
            while scanner.isAtEnd == false {
                let textLineScanResult = scanner.scanUpToCharacters(from: CharacterSet.newlines, into: &textResult)

                guard textLineScanResult else {
                    throw ParseError.invalidFormat
                }

                let plainText = htmlToText(encodedString: textResult! as String)

                if plainText
                    .lowercased()
                    .filter({ char -> Bool in
                        String(char).rangeOfCharacter(from: NSCharacterSet.lowercaseLetters) != nil
                    })
                    .lengthOfBytes(using: .utf8) > 2 {
                    textLines.append(plainText)
                }
            }

            guard indexScanSuccess && startTimeScanResult && dividerScanSuccess && endTimeScanResult else {
                throw ParseError.invalidFormat
            }

            let startTimeInterval: TimeInterval = timeIntervalFromString(startResult! as String)
            let endTimeInterval: TimeInterval = timeIntervalFromString(endResult! as String)

            if !textLines.isEmpty {
                let title = SubtitleItem(texts: textLines, start: startTimeInterval, end: endTimeInterval, index: indexResult)
                allTitles.append(title)
            }
        }

        return allTitles
    }

    private func timeIntervalFromString(_ timeString: String) -> TimeInterval {
        let scanner = Scanner(string: timeString)

        var hoursResult: Int = 0
        var minutesResult: Int = 0
        var secondsResult: NSString?
        var millisecondsResult: NSString?

        // Extract time components from string
        scanner.scanInt(&hoursResult)
        scanner.scanLocation += 1
        scanner.scanInt(&minutesResult)
        scanner.scanLocation += 1
        scanner.scanUpTo(",", into: &secondsResult)
        scanner.scanLocation += 1
        scanner.scanUpToCharacters(from: CharacterSet.newlines, into: &millisecondsResult)

        let secondsString = secondsResult! as String
        let seconds = Int(secondsString)

        let millisecondsString = millisecondsResult! as String
        let milliseconds = Int(millisecondsString)

        let timeInterval: Double = Double(hoursResult) * 3_600 + Double(minutesResult) * 60 + Double(seconds!) + Double(Double(milliseconds!) / 1_000)

        return timeInterval as TimeInterval
    }


    private func htmlToText(encodedString: String) -> String {
        return encodedString.attributedHtmlString?.string ?? ""
    }

}

private extension String {

    var utfData: Data {
        return Data(utf8)
    }

    var attributedHtmlString: NSAttributedString? {

        do {
            return try NSAttributedString(
                data: utfData,
                options:
                [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil)
        } catch {
            print("Error:", error)
            return nil
        }
    }
}
