//
//  String+Levenshtein.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 2/10/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import Foundation

extension String {

    public func levenshtein(_ other: String) -> Int {
        let sCount = self.count
        let oCount = other.count

        guard sCount != 0 else {
            return oCount
        }

        guard oCount != 0 else {
            return sCount
        }

        let line: [Int]  = Array(repeating: 0, count: oCount + 1)
        var mat: [[Int]] = Array(repeating: line, count: sCount + 1)

        for index in 0...sCount {
            mat[index][0] = index
        }

        for index in 0...oCount {
            mat[0][index] = index
        }

        for oIndex in 1...oCount {
            for sIndex in 1...sCount {
                if self[sIndex - 1] == other[oIndex - 1] {
                    mat[sIndex][oIndex] = mat[sIndex - 1][oIndex - 1]       // no operation
                } else {
                    let del = mat[sIndex - 1][oIndex] + 1         // deletion
                    let ins = mat[sIndex][oIndex - 1] + 1         // insertion
                    let sub = mat[sIndex - 1][oIndex - 1] + 1     // substitution
                    mat[sIndex][oIndex] = min(min(del, ins), sub)
                }
            }
        }

        return mat[sCount][oCount]
    }
}
