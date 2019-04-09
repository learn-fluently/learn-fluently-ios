//
//  Errors.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 3/25/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

struct Errors {

    enum Download: Error {

        // MARK: Cases

        case saving(String)
        case archive(String)
        case convert(String)
    }

}
