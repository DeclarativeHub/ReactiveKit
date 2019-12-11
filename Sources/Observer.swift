//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Srdan Rasic (@srdanrasic)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

/// Represents a type that receives events.
public typealias Observer<Element, Error: Swift.Error> = (Signal<Element, Error>.Event) -> Void

/// An observer of safe signals.
public typealias SafeObserver<Element> = (Signal<Element, Never>.Event) -> Void

/// Represents a type that receives events.
public protocol ObserverProtocol {
    
    /// Type of elements being received.
    associatedtype Element
    
    /// Type of error that can be received.
    associatedtype Error: Swift.Error
    
    /// Send the event to the observer.
    func on(_ event: Signal<Element, Error>.Event)
}

/// Represents a type that receives events. Observer is just a convenience
/// wrapper around a closure observer `Observer<Element, Error>`.
public struct AnyObserver<Element, Error: Swift.Error>: ObserverProtocol {
    
    public let observer: Observer<Element, Error>
    
    /// Creates an observer that wraps a closure observer.
    public init(observer: @escaping Observer<Element, Error>) {
        self.observer = observer
    }
    
    /// Calles wrapped closure with the given element.
    @inlinable
    public func on(_ event: Signal<Element, Error>.Event) {
        observer(event)
    }
}

/// Observer that ensures events are sent atomically.
public final class AtomicObserver<Element, Error: Swift.Error>: ObserverProtocol, Disposable {

    private var observer: Observer<Element, Error>?
    private var upstreamDisposables: [Disposable] = []
    private let observerLock = NSRecursiveLock(name: "com.reactive_kit.atomic_observer.observer")
    private let disposablesQueue = DispatchQueue(label: "com.reactive_kit.atomic_observer.disposables", qos: .userInitiated)

    public var isDisposed: Bool {
        observerLock.lock(); defer { observerLock.unlock() }
        return observer == nil
    }

    /// Creates an observer that wraps given closure.
    public init(_ observer: @escaping Observer<Element, Error>) {
        self.observer = observer
    }

    @available(*, deprecated, message: "Will be remove in favour of `init(_:)`. AtomicObserver is a Disposable itself now.")
    public convenience init(disposable: Disposable, observer: @escaping Observer<Element, Error>) {
        self.init(observer)
        upstreamDisposables.append(disposable)
    }

    /// Calles wrapped closure with the given element.
    public func on(_ event: Signal<Element, Error>.Event) {
        observerLock.lock()
        if let observer = observer {
            observer(event)
            if event.isTerminal {
                self.observer = nil
                observerLock.unlock()
                disposablesQueue.async {
                    self.upstreamDisposables.forEach { $0.dispose() }
                }
            } else {
                observerLock.unlock()
            }
        } else {
            observerLock.unlock()
        }
    }

    public func attach(_ producer: Signal<Element, Error>.Producer) {
        let disposable = producer(self)
        disposablesQueue.async {
            if self.isDisposed {
                disposable.dispose()
            } else {
                self.upstreamDisposables.append(disposable)
            }
        }
    }

    public func dispose() {
        observerLock.lock()
        observer = nil
        observerLock.unlock()
        disposablesQueue.async {
            self.upstreamDisposables.forEach { $0.dispose() }
        }
    }
}

// MARK: - Extensions

extension ObserverProtocol {

    /// Convenience method to send `.next` event.
    public func receive(_ element: Element) {
        on(.next(element))
    }

    /// Convenience method to send `.failed` or `.completed` event.
    public func receive(completion: Subscribers.Completion<Error>) {
        switch completion {
        case .finished:
            on(.completed)
        case .failure(let error):
            on(.failed(error))
        }
    }

    /// Convenience method to send `.next` event followed by a `.completed` event.
    public func receive(lastElement element: Element) {
        receive(element)
        receive(completion: .finished)
    }

    /// Converts the receiver to the Observer closure.
    public func toObserver() -> Observer<Element, Error> {
        return on
    }
}

extension ObserverProtocol where Element == Void {

    /// Convenience method to send `.next` event.
    public func receive() {
        on(.next(()))
    }
}
