//
//  TitleDesc.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 4/20/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

struct TitleDesc {

    // MARK: Properties

    var title: String
    var description: String
    var isEmpty: Bool {
        return title.isEmpty && description.isEmpty
    }

    static let empty = TitleDesc(title: "", description: "")


    // MARK: Lifecycle

    init(title: String = "", description: String = "") {
        self.title = title
        self.description = description
    }

}
