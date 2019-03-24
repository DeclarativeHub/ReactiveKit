//
//  SignalProtocol+Sequence.swift
//  ReactiveKit-iOS
//
//  Created by Srdan Rasic on 24/03/2019.
//  Copyright © 2019 DeclarativeHub. All rights reserved.
//

import Foundation

extension SignalProtocol {

    /// Map element into a collection, flattening the collection into next elements.
    /// Shorthand for `map(transform).unwrap()`.
    public func flatMap<NewElement>(_ transform: @escaping (Element) -> [NewElement]) -> Signal<NewElement, Error> {
        return map(transform).flattenElements()
    }
}

extension SignalProtocol where Element: Sequence {

    /// Map inner sequence.
    public func mapElement<NewElement>(_ transform: @escaping (Element.Iterator.Element) -> NewElement) -> Signal<[NewElement], Error> {
        return map { $0.map(transform) }
    }

    /// Unwraps elements from each emitted sequence into events of their own.
    public func flattenElements() -> Signal<Element.Iterator.Element, Error> {
        return Signal { observer in
            return self.observe { event in
                switch event {
                case .next(let sequence):
                    sequence.forEach(observer.next)
                case .completed:
                    observer.completed()
                case .failed(let error):
                    observer.failed(error)
                }
            }
        }
    }
}
