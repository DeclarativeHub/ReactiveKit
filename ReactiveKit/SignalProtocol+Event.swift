//
//  SignalProtocol+Event.swift
//  ReactiveKit-iOS
//
//  Created by Srdan Rasic on 24/03/2019.
//  Copyright © 2019 DeclarativeHub. All rights reserved.
//

import Foundation

extension SignalProtocol {

    /// Unwrap events into elements.
    public func materialize() -> Signal<Event<Element, Error>, Never> {
        return Signal { observer in
            return self.observe { event in
                switch event {
                case .next(let element):
                    observer.next(.next(element))
                case .failed(let error):
                    observer.next(.failed(error))
                    observer.completed()
                case .completed:
                    observer.next(.completed)
                    observer.completed()
                }
            }
        }
    }

    /// Inverse of `materialize`.
    public func dematerialize<U, E>() -> Signal<U, E> where Element == Event<U, E>, E == Error {
        return Signal { observer in
            return self.observe { event in
                switch event {
                case .next(let innerEvent):
                    switch innerEvent {
                    case .next(let element):
                        observer.next(element)
                    case .failed(let error):
                        observer.failed(error)
                    case .completed:
                        observer.completed()
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

extension SignalProtocol where Error == Never {

    /// Inverse of `materialize`.
    public func dematerialize<U, E>() -> Signal<U, E> where Element == Event<U, E> {
        return (castError() as Signal<Element, E>).dematerialize()
    }
}
