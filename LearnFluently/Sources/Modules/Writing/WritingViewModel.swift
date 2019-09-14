//
//  WritingViewModel.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 9/9/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

class WritingViewModel: InputViewModel {

    // MARK: Properties

    var subtitleRepository: SubtitleRepository?
    var fileRepository: FileRepository


    // MARK: Lifecycle

    init(fileRepository: FileRepository) {
        self.fileRepository = fileRepository
    }

}
