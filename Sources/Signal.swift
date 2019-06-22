//
//  The MIT License (MIT)
//
//  Copyright (c) 2016-2019 Srdan Rasic (@srdanrasic)
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

import Dispatch
import Foundation

/// A signal represents a sequence of elements.
public struct Signal<Element, Error: Swift.Error>: SignalProtocol {
    
    public typealias Producer = (AtomicObserver<Element, Error>) -> Disposable
    
    private let producer: Producer
    
    /// Create a new signal given the producer closure.
    public init(_ producer: @escaping Producer) {
        self.producer = producer
    }
    
    /// Register the observer that will receive events from the signal.
    public func observe(with observer: @escaping Observer<Element, Error>) -> Disposable {
        let serialDisposable = SerialDisposable(otherDisposable: nil)
        let observer = AtomicObserver(disposable: serialDisposable, observer: observer)
        serialDisposable.otherDisposable = producer(observer)
        return observer.disposable
    }
}

/// A Signal compile-time guaranteed never to emit an error.
public typealias SafeSignal<Element> = Signal<Element, Never>

extension Signal {

    /// Create a signal that completes immediately without emitting any elements.
    public static func completed() -> Signal<Element, Error> {
        return Signal { observer in
            observer.receive(completion: .finished)
            return NonDisposable.instance
        }
    }

    /// Create a signal that terminates immediately with the given error.
    ///
    /// - Parameter error: An error to fail with.
    public static func failed(_ error: Error) -> Signal<Element, Error> {
        return Signal { observer in
            observer.receive(completion: .failure(error))
            return NonDisposable.instance
        }
    }

    /// Create a signal that never completes and never fails.
    public static func never() -> Signal<Element, Error> {
        return Signal { observer in
            return NonDisposable.instance
        }
    }

    /// Create a signal and an observer that can be used to send events on the signal.
    public static func withObserver() -> (Signal<Element, Error>, AnyObserver<Element, Error>) {
        let subject = PassthroughSubject<Element, Error>()
        return (subject.toSignal(), AnyObserver(observer: subject.on))
    }
}

extension Signal {

    /// Create a signal that emits the given element and completes immediately.
    ///
    /// - Parameter element: An element to emit in the `next` event.
    public init(just element: Element) {
        self = Signal(performing: { element })
    }

    /// Create a signal that emits the given element after the given number of seconds and then completes immediately.
    ///
    /// - Parameter element: An element to emit in the `next` event.
    /// - Parameter interval: A number of seconds to delay the emission.
    /// - Parameter queue: A queue used to delay the emission. Defaults to a new serial queue.
    public init(just element: Element, after interval: Double, queue: DispatchQueue = DispatchQueue(label: "reactive_kit.just_after")) {
        self = Signal(just: element).delay(interval: interval, on: queue)
    }

    /// Create a signal that performs the given closure, emits the returned element and completes immediately.
    ///
    /// - Parameter body: A closure to perform whose return element will be emitted in the `next` event.
    public init(performing body: @escaping () -> Element) {
        self.init { observer in
            observer.receive(lastElement: body())
            return NonDisposable.instance
        }
    }

    /// Create a signal by evaluating the given result, propagating the success element as a
    /// next event and completing immediately, or propagating the failure error as a failed event.
    ///
    /// - Parameter result: A result to evaluate.
    public init(result: Result<Element, Error>) {
        self = Signal(evaluating: { result })
    }

    /// Defer the signal creation until an observer stars observing it.
    /// A new signal is created for each observer.
    ///
    /// - Parameter makeSignal: A closure to creates the signal.
    public init<Other: SignalProtocol>(deferring makeSignal: @escaping () -> Other) where Other.Element == Element, Other.Error == Error {
        self.init { observer in
            return makeSignal().observe(with: observer)
        }
    }

    /// Create a signal by evaluating a closure that returns result, propagating the success element as a
    /// next event and completing immediately, or propagating the failure error as a failed event.
    ///
    /// - Parameter body: A closure that returns a result to evaluate.
    public init(evaluating body: @escaping () -> Result<Element, Error>) {
        self.init { observer in
            switch body() {
            case .success(let element):
                observer.receive(lastElement: element)
            case .failure(let error):
                observer.receive(completion: .failure(error))
            }
            return NonDisposable.instance
        }
    }

    /// Create a signal that emits the given sequence of elements and completes immediately.
    ///
    /// - Parameter sequence: A sequence of elements to convert into a series of `next` events.
    public init<S: Sequence>(sequence: S) where S.Iterator.Element == Element {
        self.init { observer in
            sequence.forEach(observer.receive(_:))
            observer.receive(completion: .finished)
            return NonDisposable.instance
        }
    }

    /// Create a signal that emits next element from the given sequence every `interval` seconds.
    ///
    /// - Parameter sequence: A sequence of elements to convert into a series of `next` events.
    /// - Parameter interval: A number of seconds to wait between each emission.
    /// - Parameter queue: A queue used to delay the emissions. Defaults to a new serial queue.
    public init<S: Sequence>(sequence: S, interval: Double, queue: DispatchQueue = DispatchQueue(label: "reactive_kit.sequence_interval"))
        where S.Iterator.Element == Element {
        self.init { observer in
            var iterator = sequence.makeIterator()
            var dispatch: (() -> Void)!
            let disposable = SimpleDisposable()
            dispatch = {
                queue.after(when: interval) {
                    guard !disposable.isDisposed else {
                        dispatch = nil
                        return
                    }
                    guard let element = iterator.next() else {
                        dispatch = nil
                        observer.receive(completion: .finished)
                        return
                    }
                    observer.receive(element)
                    dispatch()
                }
            }
            dispatch()
            return disposable
        }
    }

    /// Create a signal that flattens events from the given signals into a single sequence of events.
    ///
    /// - Parameter signals: A sequence of signals whose elements should be propageted as own elements.
    /// - Parameter strategy: Flattening strategy. Check out `FlattenStrategy` for more info.
    ///
    /// A failure on any of the inner signals will be propagated as own failure.
    public init<S: Sequence>(flattening signals: S, strategy: FlattenStrategy)
        where S.Element: SignalProtocol, S.Element.Element == Element, S.Element.Error == Error {
        self = Signal<S.Element, Error>(sequence: signals).flatten(strategy)
    }

    /// Create a signal that emits a combination of elements made from the elements of the given signals.
    /// The signal starts when all the given signals emit at least one element.
    ///
    /// - Parameter signals: A sequence of signals whose elements should be combined.
    /// - Parameter combine: A closure that combines an array of elements from the given signal into a desired type.
    /// - Parameter elements: An array containing elements from each of the given signals.
    /// Guaranteed to have the same number of elements as the given array of signals.
    public init<S: Collection>(combiningLatest signals: S, combine: @escaping (_ elements: [S.Element.Element]) -> Element)
        where S.Element: SignalProtocol, S.Element.Error == Error {
        self = signals.dropFirst().reduce(signals.first?.map { [$0] }) { (running, new) in
            return running?.combineLatest(with: new) { $0 + [$1] }
        }?.map(combine) ?? Signal.completed()
    }
}

extension Signal where Error == Swift.Error {

    /// Create a new signal by evaluating a throwing closure, capturing the
    /// returned value as a next event followed by a completion event, or any thrown error as a failure event.
    ///
    /// - Parameter body: A throwing closure to evaluate.
    public init(catching body: @escaping () throws -> Element) {
        self = Signal(result: Result(catching: body))
    }
}

extension Signal where Error == Never {

    /// Create a new signal and assign its next element observer to the given variable.
    /// Calling the closure assigned to the varaible will send the next element on the signal.
    ///
    /// - Parameter nextObserver: A variable that will be assigned the observer of next elements.
    ///
    /// - Note: Calling this initializer will replace the value of the given variable.
    public init(takingOver nextObserver: inout (Element) -> Void) {
        let (signal, observer) = Signal.withObserver()
        nextObserver = { observer.receive($0) }
        self = signal
    }
}

extension Signal where Element == Void, Error == Never {

    /// Create a new signal and assign its next element observer to the given variable.
    /// Calling the closure assigned to the varaible will send the next element on the signal.
    ///
    /// - Parameter nextObserver: A variable that will be assigned the observer of next elements.
    ///
    /// - Note: Calling this initializer will replace the value of the given variable.
    public init(takingOver nextObserver: inout () -> Void) {
        let (signal, observer) = Signal.withObserver()
        nextObserver = { observer.receive() }
        self = signal
    }
}
