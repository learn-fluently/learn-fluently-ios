//
//  Rx+Utilities.swift
//  Learn Fluently
//
//  Created by Amir Khorsandi on 4/18/19.
//  Copyright © 2019 Amir Khorsandi. All rights reserved.
//

import RxSwift

extension PrimitiveSequenceType where Trait == SingleTrait {

    // MARK: Functions

    func flatMap<T: AnyObject, R>(weak param: T?,
                                  _ selector: @escaping (T, Element) throws ->
        PrimitiveSequence<SingleTrait, R>) -> PrimitiveSequence<SingleTrait, R> {

        return flatMap { [weak param] element in
            guard let param = param else {
                return .never()
            }
            return try selector(param, element)
        }

    }

}


extension ObservableType {

    public func compactMap<R>() -> RxSwift.Observable<R> {
        //swiftlint:disable force_cast
        return filter { $0 is R }.map { $0 as! R }
    }
}
