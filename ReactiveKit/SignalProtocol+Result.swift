//
//  SignalProtocol+Result.swift
//  ReactiveKit-iOS
//
//  Created by Srdan Rasic on 24/03/2019.
//  Copyright © 2019 DeclarativeHub. All rights reserved.
//

import Foundation

public protocol _ResultProtocol {
    associatedtype Value
    associatedtype Error: Swift.Error
    var _unbox: Result<Value, Error> { get }
}

extension Result: _ResultProtocol {

    public var _unbox: Result {
        return self
    }
}

extension SignalProtocol {

    /// Map element into a result, propagating success value as a next event or failure as a failed event.
    /// Shorthand for `map(transform).getValues()`.
    public func tryMap<U>(_ transform: @escaping (Element) -> Result<U, Error>) -> Signal<U, Error> {
        return map(transform).getValues()
    }
}

extension SignalProtocol where Error == Never {

    /// Map element into a result, propagating success value as a next event or failure as a failed event.
    /// Shorthand for `map(transform).getValues()`.
    public func tryMap<U, E>(_ transform: @escaping (Element) -> Result<U, E>) -> Signal<U, E> {
        return castError().map(transform).getValues()
    }
}

extension SignalProtocol where Element: _ResultProtocol {

    /// Map inner result.
    /// Shorthand for `map { $0.map(transform) }`.
    public func mapValue<NewSuccess>(_ transform: @escaping (Element.Value) -> NewSuccess) -> Signal<Result<NewSuccess, Element.Error>, Error> {
        return map { $0._unbox.map(transform) }
    }
}

extension SignalProtocol where Element: _ResultProtocol, Error == Element.Error {

    /// Unwraps values from result elements into elements of the signal.
    /// A failure result will trigger signal failure.
    public func getValues() -> Signal<Element.Value, Error> {
        return Signal { observer in
            return self.observe { event in
                switch event {
                case .next(let result):
                    switch result._unbox {
                    case .success(let element):
                        observer.next(element)
                    case .failure(let error):
                        observer.failed(error)
                    }
                case .completed:
                    observer.completed()
                case .failed(let error):
                    observer.failed(error)
                }
            }
        }
    }
}

extension SignalProtocol where Element: _ResultProtocol, Error == Never {

    /// Unwraps values from result elements into elements of the signal.
    /// A failure result will trigger signal failure.
    public func getValues() -> Signal<Element.Value, Element.Error> {
        return (castError() as Signal<Element, Element.Error>).getValues()
    }
}
