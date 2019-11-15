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

import Dispatch
import Foundation

@available(*, deprecated, message: "Event<Element, Error> has been renamed to Signal<Element, Error>.Event")
public typealias Event<Element, Error: Swift.Error> = Signal<Element, Error>.Event

@available(*, deprecated, renamed: "Never")
public typealias NoError = Never

@available(*, deprecated, renamed: "SafeSignal")
public typealias Signal1<Element> = Signal<Element, Never>

@available(*, deprecated, renamed: "SafeObserver")
public typealias Observer1<Element> = (Event<Element, Never>) -> Void

@available(*, deprecated, renamed: "SafePublishSubject")
public typealias PublishSubject1<Element> = PublishSubject<Element, Never>

@available(*, deprecated, renamed: "SafeReplaySubject")
public typealias ReplaySubject1<Element> = ReplaySubject<Element, Never>

@available(*, deprecated, renamed: "SafeReplayOneSubject")
public typealias ReplayOneSubject1<Element> = ReplayOneSubject<Element, Never>

extension SignalProtocol {

    @available(*, deprecated, renamed: "init(just:)")
    public static func just(_ element: Element) -> Signal<Element, Error> {
        return Signal(just: element)
    }

    @available(*, deprecated, renamed: "init(sequence:)")
    public static func sequence<S: Sequence>(_ sequence: S) -> Signal<Element, Error> where S.Iterator.Element == Element {
        return Signal(sequence: sequence)
    }

    @available(*, deprecated, message: "Please use Signal(sequence: 0..., interval: N) instead")
    public static func interval(_ interval: Double, queue: DispatchQueue = DispatchQueue(label: "com.reactivekit.interval")) -> Signal<Int, Error> {
        return Signal(sequence: 0..., interval: interval, queue: queue)
    }

    @available(*, deprecated, message: "Please use Signal(just:after:) instead")
    public static func timer(element: Element, time: Double, queue: DispatchQueue = DispatchQueue(label: "com.reactivekit.timer")) -> Signal<Element, Error> {
        return Signal(just: element, after: time, queue: queue)
    }
}

@available(*, deprecated, message: "Please use Signal(flattening: signals, strategy: .merge")
public func merge<Element, Error>(_ signals: [Signal<Element, Error>]) -> Signal<Element, Error> {
    return Signal(sequence: signals).flatten(.merge)
}

@available(*, deprecated, renamed: "Signal(combiningLatest:combine:)")
public func combineLatest<Element, Result, Error>(_ signals: [Signal<Element, Error>], combine: @escaping ([Element]) -> Result) -> Signal<Result, Error> {
    return Signal(combiningLatest: signals, combine: combine)
}

extension SignalProtocol where Element: OptionalProtocol {

    @available(*, deprecated, renamed: "replaceNils")
    public func replaceNil(with replacement: Element.Wrapped) -> Signal<Element.Wrapped, Error> {
        return replaceNils(with: replacement)
    }

    @available(*, deprecated, renamed: "ignoreNils")
    public func ignoreNil() -> Signal<Element.Wrapped, Error> {
        return ignoreNils()
    }
}

extension Signal where Error == Never {

    @available(*, deprecated, message: "Replace with compactMap { $0.element }`")
    public func elements<U, E>() -> Signal<U, Never> where Element == Signal<U, E>.Event {
        return compactMap { $0.element }
    }

    @available(*, deprecated, message: "Replace with compactMap { $0.error }`")
    public func errors<U, E>() -> Signal<E, Never> where Element == Signal<U, E>.Event {
        return compactMap { $0.error }
    }
}

extension SignalProtocol {

    @available(*, deprecated, renamed: "debounce(interval:queue:)")
    public func debounce(interval: Double, on queue: DispatchQueue) -> Signal<Element, Error> {
        return debounce(interval: interval, queue: queue)
    }

    @available(*, deprecated, renamed: "distinctUntilChanged")
    public func distinct(areDistinct: @escaping (Element, Element) -> Bool) -> Signal<Element, Error> {
        return distinctUntilChanged(areDistinct)
    }

    @available(*, deprecated, renamed: "replaceElements")
    public func replace<T>(with element: T) -> Signal<T, Error> {
        return replaceElements(with: element)
    }
}

extension SignalProtocol where Element: Equatable {

    @available(*, deprecated, renamed: "distinctUntilChanged")
    public func distinct() -> Signal<Element, Error> {
        return distinctUntilChanged()
    }
}

extension SignalProtocol where Element: Sequence {

    @available(*, deprecated, renamed: "flattenElements")
    public func unwrap() -> Signal<Element.Iterator.Element, Error> {
        return flattenElements()
    }
}

@available(*, deprecated, renamed: "PassthroughSubject")
public final class PublishSubject<Element, Error: Swift.Error>: Subject<Element, Error> {}

@available(*, deprecated, renamed: "PassthroughSubject")
public typealias SafePublishSubject<Element> = PublishSubject<Element, Never>

extension ObserverProtocol {

    @available(*, deprecated, renamed: "receive(_:)")
    public func next(_ element: Element) {
        on(.next(element))
    }

    @available(*, deprecated, message: "Please use receive(completion: .failure(error))")
    public func failed(_ error: Error) {
        on(.failed(error))
    }

    @available(*, deprecated, message: "Please use receive(completion: .finished)")
    public func completed() {
        on(.completed)
    }

    @available(*, deprecated, renamed: "receive(lastElement:)")
    public func completed(with element: Element) {
        next(element)
        completed()
    }
}

extension ObserverProtocol where Element == Void {

    @available(*, deprecated, renamed: "receive")
    public func next() {
        next(())
    }
}

extension SubjectProtocol {


    @available(*, deprecated, renamed: "send(_:)")
    public func next(_ element: Element) {
        on(.next(element))
    }

    @available(*, deprecated, message: "Please use send(completion: .failure(error))")
    public func failed(_ error: Error) {
        on(.failed(error))
    }

    @available(*, deprecated, message: "Please use send(completion: .finished)")
    public func completed() {
        on(.completed)
    }

    @available(*, deprecated, renamed: "send(lastElement:)")
    public func completed(with element: Element) {
        next(element)
        completed()
    }
}

extension SubjectProtocol where Element == Void {

    @available(*, deprecated, renamed: "send")
    public func next() {
        next(())
    }
}

extension Subject {

    @available(*, deprecated, renamed: "receive(event:)")
    open func send(_ event: Event<Element, Error>) {
        on(event)
    }
}

extension SignalProtocol {

    @available(*, deprecated, renamed: "share(limit:)")
    public func shareReplay(limit: Int = Int.max) -> Signal<Element, Error> {
        return share(limit: limit)
    }
}

extension SignalProtocol {

    /// Set the execution context in which to execute the signal (i.e. in which to run
    /// the signal's producer).
    @available(*, deprecated, renamed: "subscribe(on:)")
    public func executeIn(_ context: ExecutionContext) -> Signal<Element, Error> {
        return subscribe(on: context)
    }

    /// Set the dispatch queue on which to execute the signal (i.e. on which to run
    /// the signal's producer).
    @available(*, deprecated, renamed: "subscribe(on:)")
    public func executeOn(_ queue: DispatchQueue) -> Signal<Element, Error> {
        return subscribe(on: queue)
    }

    /// Set the execution context used to dispatch events (i.e. to run the observers).
    @available(*, deprecated, renamed: "receive(on:)")
    public func observeIn(_ context: ExecutionContext) -> Signal<Element, Error> {
        return receive(on: context)
    }

    /// Set the dispatch queue used to dispatch events (i.e. to run the observers).
    @available(*, deprecated, renamed: "receive(on:)")
    public func observeOn(_ queue: DispatchQueue) -> Signal<Element, Error> {
        return receive(on: queue)
    }
}

extension SignalProtocol {
    
    /// Emit first element and then all elements that are not equal to their predecessor(s).
    ///
    /// Check out interactive example at [https://rxmarbles.com/#distinctUntilChanged](https://rxmarbles.com/#distinctUntilChanged)
    @available(*, deprecated, message: "Please use `removeDuplicates(by:)` instead, but note that the closure should now return `true` when the element are equal!")
    public func distinctUntilChanged(_ areDistinct: @escaping (Element, Element) -> Bool) -> Signal<Element, Error> {
        return removeDuplicates(by: { !areDistinct($0, $1) })
    }

    /// Emit an element only if `interval` time passes without emitting another element.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#debounceTime](https://rxmarbles.com/#debounceTime)
    @available(*, deprecated, renamed: "debounce(for:queue:)")
    public func debounce(interval: Double, queue: DispatchQueue = DispatchQueue(label: "com.reactive_kit.signal.debounce")) -> Signal<Element, Error> {
        return debounce(for: interval, queue: queue)
    }
    
    /// Emit only the element at given index (if such element is produced).
    ///
    /// Check out interactive example at [https://rxmarbles.com/#elementAt](https://rxmarbles.com/#elementAt)
    @available(*, deprecated, renamed: "output(at:)")
    public func element(at index: Int) -> Signal<Element, Error> {
        return output(at: index)
    }

    /// Suppress first `count` elements generated by the signal.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#skip](https://rxmarbles.com/#skip)
    @available(*, deprecated, renamed: "dropFirst(_:)")
    public func skip(first count: Int) -> Signal<Element, Error> {
        return dropFirst(count)
    }

    /// Suppress last `count` elements generated by the signal.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#skip](https://rxmarbles.com/#skip)
    @available(*, deprecated, renamed: "dropLast(_:)")
    public func skip(last count: Int) -> Signal<Element, Error> {
        return dropLast(count)
    }

    /// Suppress elements for first `interval` seconds.
    @available(*, deprecated, renamed: "dropFirst(for:)")
    public func skip(interval: Double) -> Signal<Element, Error> {
        return dropFirst(for: interval)
    }

    /// Emit elements until the given closure returns first `false`.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#takeWhile](https://rxmarbles.com/#takeWhile)
    @available(*, deprecated, renamed: "prefix(while:)")
    public func take(while shouldContinue: @escaping (Element) -> Bool) -> Signal<Element, Error> {
        return prefix(while: shouldContinue)
    }

    /// Emit elements until the given signal sends an event (of any kind)
    /// and then complete and dispose the signal.
    @available(*, deprecated, renamed: "prefix(untilOutputFrom:)")
    public func take<S: SignalProtocol>(until signal: S) -> Signal<Element, Error> {
        return prefix(untilOutputFrom: signal)
    }

    /// Emit only first `count` elements of the signal and then complete.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#take](https://rxmarbles.com/#take)
    @available(*, deprecated, renamed: "prefix(maxLength:)")
    public func take(first count: Int) -> Signal<Element, Error> {
        return prefix(maxLength: count)
    }

    /// Emit only last `count` elements of the signal and then complete.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#takeLast](https://rxmarbles.com/#takeLast)
    @available(*, deprecated, renamed: "suffix(maxLength:)")
    public func take(last count: Int) -> Signal<Element, Error> {
        return suffix(maxLength: count)
    }

    /// Throttle the signal to emit at most one element per given `seconds` interval.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#throttle](https://rxmarbles.com/#throttle)
    @available(*, deprecated, renamed: "throttle(for:)")
    public func throttle(seconds: Double) -> Signal<Element, Error> {
        return throttle(for: seconds)
    }
}

extension SignalProtocol where Element: Equatable {

    /// Emit first element and then all elements that are not equal to their predecessor(s).
    ///
    /// Check out interactive example at [https://rxmarbles.com/#distinctUntilChanged](https://rxmarbles.com/#distinctUntilChanged)
    @available(*, deprecated, renamed: "removeDuplicates")
    public func distinctUntilChanged() -> Signal<Element, Error> {
        return removeDuplicates()
    }
}

extension SignalProtocol {

    /// Batch signal elements into arrays of the given size.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#bufferCount](https://rxmarbles.com/#bufferCount)
    @available(*, deprecated, renamed: "buffer(size:)")
    public func buffer(ofSize size: Int) -> Signal<[Element], Error> {
        return buffer(size: size)
    }

    /// Emit default element if the signal completes without emitting any element.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#defaultIfEmpty](https://rxmarbles.com/#defaultIfEmpty)
    @available(*, deprecated, renamed: "replaceEmpty(with:)")
    public func defaultIfEmpty(_ element: Element) -> Signal<Element, Error> {
        return replaceEmpty(with: element)
    }

    /// Prepend the given element to the signal element sequence.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#startWith](https://rxmarbles.com/#startWith)
    @available(*, deprecated, renamed: "prepend(_:)")
    public func start(with element: Element) -> Signal<Element, Error> {
        return prepend(element)
    }

    /// Ignore all elements (just propagate terminal events).
    ///
    /// Check out interactive example at [https://rxmarbles.com/#ignoreElements](https://rxmarbles.com/#ignoreElements)
    @available(*, deprecated, renamed: "ignoreOutput")
    public func ignoreElements() -> Signal<Element, Error> {
        return ignoreOutput()
    }

    /// Recover the signal by propagating default element if an error happens.
    @available(*, deprecated, renamed: "replaceError(with:)")
    public func recover(with element: Element) -> Signal<Element, Never> {
        return replaceError(with: element)
    }

    /// Retry the signal in case of failure at most `times` number of times.
    @available(*, deprecated, renamed: "retry(_:)")
    public func retry(times: Int) -> Signal<Element, Error> {
        return retry(times)
    }

    /// Do side-effect upon various events.
    @available(*, deprecated, renamed: "handleEvents(receiveSubscription:receiveOutput:receiveCompletion:receiveCancel:)")
    public func doOn(next: ((Element) -> ())? = nil,
                     start: (() -> Void)? = nil,
                     failed: ((Error) -> Void)? = nil,
                     completed: (() -> Void)? = nil,
                     disposed: (() -> ())? = nil) -> Signal<Element, Error> {
        return Signal { observer in
            start?()
            let disposable = self.observe { event in
                switch event {
                case .next(let value):
                    next?(value)
                case .failed(let error):
                    failed?(error)
                case .completed:
                    completed?()
                }
                observer.on(event)
            }
            return BlockDisposable {
                disposable.dispose()
                disposed?()
            }
        }
    }
}

extension SignalProtocol {

    /// First propagate all elements from the source signal and then all elements from the `other` signal.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#concat](https://rxmarbles.com/#concat)
    @available(*, deprecated, renamed: "append(_:)")
    public func concat<O: SignalProtocol>(with other: O) -> Signal<Element, Error> where O.Element == Element, O.Error == Error {
        return append(other)
    }

    /// First propagate all elements from the source signal and then all elements from the `other` signal.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#concat](https://rxmarbles.com/#concat)
    @available(*, deprecated, renamed: "append(_:)")
    public func concat<O: SignalProtocol>(with other: O) -> Signal<Element, Error> where O.Element == Element, O.Error == Never {
        return append((other.castError() as Signal<O.Element, Error>))
    }
}

extension SignalProtocol where Error == Never {

    /// First propagate all elements from the source signal and then all elements from the `other` signal.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#concat](https://rxmarbles.com/#concat)
    @available(*, deprecated, renamed: "append(_:)")
    public func concat<O: SignalProtocol>(with other: O) -> Signal<Element, O.Error> where O.Element == Element {
        return (castError() as Signal<Element, O.Error>).append(other)
    }
}

extension SignalProtocol {

    @available(*, deprecated, message: "Please provide `receiveCompletion` argument when observing signals with error type other than `Never`.")
    public func sink(receiveValue: @escaping ((Element) -> Void)) -> AnyCancellable {
        return sink(receiveCompletion: { _ in }, receiveValue: receiveValue)
    }
}
