//
//  SignalProtocol+Optional.swift
//  ReactiveKit-iOS
//
//  Created by Srdan Rasic on 24/03/2019.
//  Copyright © 2019 DeclarativeHub. All rights reserved.
//

import Foundation

public protocol OptionalProtocol {
    associatedtype Wrapped
    var _unbox: Optional<Wrapped> { get }
    init(nilLiteral: ())
    init(_ some: Wrapped)
}

extension Optional: OptionalProtocol {

    public var _unbox: Optional<Wrapped> {
        return self
    }
}

extension SignalProtocol {

    /// Map element into a result, propagating `.some` value as a next event or skipping an event in case of a `nil`.
    /// Shorthand for `map(transform).ignoreNils()`.
    public func compactMap<NewWrapped>(_ transform: @escaping (Element) -> NewWrapped?) -> Signal<NewWrapped, Error> {
        return map(transform).ignoreNils()
    }
}

extension SignalProtocol where Element: OptionalProtocol {

    /// Map inner optional.
    /// Shorthand for `map { $0.map(transform) }`.
    public func mapWrapped<NewWrapped>(_ transform: @escaping (Element.Wrapped) -> NewWrapped) -> Signal<NewWrapped?, Error> {
        return map { $0._unbox.map(transform) }
    }

    /// Replace all `nil`-elements with the provided replacement.
    public func replaceNils(with replacement: Element.Wrapped) -> Signal<Element.Wrapped, Error> {
        return compactMap { $0._unbox ?? replacement }
    }

    /// Suppress all `nil`-elements.
    public func ignoreNils() -> Signal<Element.Wrapped, Error> {
        return Signal { observer in
            return self.observe { event in
                switch event {
                case .next(let element):
                    if let element = element._unbox {
                        observer.next(element)
                    }
                case .failed(let error):
                    observer.failed(error)
                case .completed:
                    observer.completed()
                }
            }
        }
    }
}
