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

import Foundation

extension SignalProtocol {

    /// Transform each element by applying `transform` on it.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#map](https://rxmarbles.com/#map)
    public func map<U>(_ transform: @escaping (Element) -> U) -> Signal<U, Error> {
        return Signal { observer in
            return self.observe { event in
                switch event {
                case .next(let element):
                    observer.receive(transform(element))
                case .failed(let error):
                    observer.receive(completion: .failure(error))
                case .completed:
                    observer.receive(completion: .finished)
                }
            }
        }
    }

    /// Map each element into a signal and then flatten inner signals using the given strategy.
    /// `flatMap` is just a shorthand for `map(transform).flatten(strategy)`.
    ///
    /// Check out interactive examples for various strategies:
    /// * Strategy `.concat`: [https://rxmarbles.com/#concatMap](https://rxmarbles.com/#concatMap)
    /// * Strategy `.latest`: [https://rxmarbles.com/#switchMap](https://rxmarbles.com/#switchMap)
    /// * Strategy `.merge`: [https://rxmarbles.com/#mergeMap](https://rxmarbles.com/#mergeMap)
    public func flatMap<O: SignalProtocol>(_ strategy: FlattenStrategy, _ transform: @escaping (Element) -> O) -> Signal<O.Element, Error> where O.Error == Error {
        return map(transform).flatten(strategy)
    }

    /// Map each element into a signal and then flatten inner signals using `.concat` strategy.
    /// Shorthand for `flatMap(.concat, transform)`.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#concatMap](https://rxmarbles.com/#concatMap)
    public func flatMapConcat<O: SignalProtocol>(_ transform: @escaping (Element) -> O) -> Signal<O.Element, Error> where O.Error == Error {
        return flatMap(.concat, transform)
    }

    /// Map each element into a signal and then flatten inner signals using `.latest` strategy.
    /// Shorthand for `flatMap(.latest, transform)`.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#switchMap](https://rxmarbles.com/#switchMap)
    public func flatMapLatest<O: SignalProtocol>(_ transform: @escaping (Element) -> O) -> Signal<O.Element, Error> where O.Error == Error {
        return flatMap(.latest, transform)
    }

    /// Map each element into a signal and then flatten inner signals using `.merge` strategy.
    /// Shorthand for `flatMap(.merge, transform)`.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#mergeMap](https://rxmarbles.com/#mergeMap)
    public func flatMapMerge<O: SignalProtocol>(_ transform: @escaping (Element) -> O) -> Signal<O.Element, Error> where O.Error == Error {
        return flatMap(.merge, transform)
    }

    /// Map failure element into a signal and continue with that signal. Also known as `catch`.
    public func flatMapError<S: SignalProtocol>(_ recover: @escaping (Error) -> S) -> Signal<Element, S.Error> where S.Element == Element {
        return Signal { observer in
            let serialDisposable = SerialDisposable(otherDisposable: nil)
            serialDisposable.otherDisposable = self.observe { taskEvent in
                switch taskEvent {
                case .next(let value):
                    observer.receive(value)
                case .completed:
                    observer.receive(completion: .finished)
                case .failed(let error):
                    serialDisposable.otherDisposable = recover(error).observe(with: observer.on)
                }
            }
            return serialDisposable
        }
    }
}

extension SignalProtocol where Error == Swift.Error {

    /// Transform each element by applying `transform` on it.
    /// Throwing an error will be emitted as `.failed` event on the Signal.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#map](https://rxmarbles.com/#map)
    public func map<U>(_ transform: @escaping (Element) throws -> U) -> Signal<U, Error> {
        return Signal { observer in
            return self.observe { event in
                switch event {
                case .next(let element):
                    do {
                        observer.receive(try transform(element))
                    } catch {
                        observer.receive(completion: .failure(error))
                    }
                case .failed(let error):
                    observer.receive(completion: .failure(error))
                case .completed:
                    observer.receive(completion: .finished)
                }
            }
        }
    }
}

/// Flattening strategy defines how to flatten (join) inner signals into one, flattened, signal.
/// - Tag: FlattenStrategy
public enum FlattenStrategy {

    /// Flatten the signal by sequentially observing inner signals in order in which they
    /// arrive, starting next observation only after previous one completes.
    case concat

    /// Flatten the signal by observing and propagating emissions only from latest signal.
    /// Previous signal observation gets disposed.
    case latest

    /// Flatten the signal by observing all inner signals and propagating elements from each one as they arrive.
    case merge
}

extension SignalProtocol where Element: SignalProtocol, Element.Error == Error {

    public typealias InnerElement = Element.Element

    /// Flatten the signal using the given strategy.
    ///
    /// - parameter strategy: Flattening strategy to use. Check out [FlattenStrategy](x-source-tag://FlattenStrategy) type from more info.
    public func flatten(_ strategy: FlattenStrategy) -> Signal<InnerElement, Error> {
        switch strategy {
        case .merge:
            return merge()
        case .latest:
            return switchToLatest()
        case .concat:
            return concat()
        }
    }

    /// Flatten the signal by observing all inner signals and propagating elements from each one as they arrive.
    public func merge() -> Signal<InnerElement, Error> {
        return Signal { observer in
            let lock = NSRecursiveLock(name: "com.reactive_kit.signal.merge")
            let compositeDisposable = CompositeDisposable()
            var _numberOfOperations = 1 // 1 for outer signal
            func _decrementNumberOfOperations() {
                _numberOfOperations -= 1
                if _numberOfOperations == 0 {
                    observer.receive(completion: .finished)
                }
            }
            compositeDisposable += self.observe { outerEvent in
                switch outerEvent {
                case .next(let innerSignal):
                    lock.lock(); defer { lock.unlock() }
                    _numberOfOperations += 1
                    compositeDisposable += innerSignal.observe { innerEvent in
                        switch innerEvent {
                        case .next(let element):
                            observer.receive(element)
                        case .failed(let error):
                            observer.receive(completion: .failure(error))
                        case .completed:
                            lock.lock(); defer { lock.unlock() }
                            _decrementNumberOfOperations()
                        }
                    }
                case .failed(let error):
                    observer.receive(completion: .failure(error))
                case .completed:
                    lock.lock(); defer { lock.unlock() }
                    _decrementNumberOfOperations()
                }
            }
            return compositeDisposable
        }
    }

    /// Flatten the signal by observing and propagating emissions only from latest signal.
    public func switchToLatest() -> Signal<InnerElement, Error> {
        return Signal { observer in
            let lock = NSRecursiveLock(name: "com.reactive_kit.signal.switch_to_latest")
            let serialDisposable = SerialDisposable(otherDisposable: nil)
            let compositeDisposable = CompositeDisposable([serialDisposable])
            var _completions = (outer: false, inner: false)
            compositeDisposable += self.observe { outerEvent in
                switch outerEvent {
                case .next(let innerSignal):
                    lock.lock(); defer { lock.unlock() }
                    _completions.inner = false
                    serialDisposable.otherDisposable?.dispose()
                    serialDisposable.otherDisposable = innerSignal.observe { innerEvent in
                        switch innerEvent {
                        case .next(let element):
                            observer.receive(element)
                        case .failed(let error):
                            observer.receive(completion: .failure(error))
                        case .completed:
                            lock.lock(); defer { lock.unlock() }
                            _completions.inner = true
                            if _completions.outer {
                                observer.receive(completion: .finished)
                            }
                        }
                    }
                case .failed(let error):
                    observer.receive(completion: .failure(error))
                case .completed:
                    lock.lock(); defer { lock.unlock() }
                    _completions.outer = true
                    if _completions.inner {
                        observer.receive(completion: .finished)
                    }
                }
            }

            return compositeDisposable
        }
    }

    /// Flatten the signal by sequentially observing inner signals in order in which they
    /// arrive, starting next observation only after previous one completes.
    public func concat() -> Signal<InnerElement, Error> {
        return Signal { observer in
            let lock = NSRecursiveLock(name: "com.reactive_kit.signal.concat")
            let serialDisposable = SerialDisposable(otherDisposable: nil)
            let compositeDisposable = CompositeDisposable([serialDisposable])
            var _completions = (outer: false, inner: true)
            var _innerSignalQueue: [Element] = []
            func _startNextOperation() {
                _completions.inner = false
                let innerSignal = _innerSignalQueue.removeFirst()
                serialDisposable.otherDisposable?.dispose()
                serialDisposable.otherDisposable = innerSignal.observe { event in
                    lock.lock(); defer { lock.unlock() }
                    switch event {
                    case .next(let element):
                        observer.receive(element)
                    case .failed(let error):
                        observer.receive(completion: .failure(error))
                    case .completed:
                        _completions.inner = true
                        if !_innerSignalQueue.isEmpty {
                            _startNextOperation()
                        } else if _completions.outer {
                            observer.receive(completion: .finished)
                        }
                    }
                }
            }
            compositeDisposable += self.observe { outerEvent in
                lock.lock(); defer { lock.unlock() }
                switch outerEvent {
                case .next(let innerSignal):
                    _innerSignalQueue.append(innerSignal)
                    if _completions.inner {
                        _startNextOperation()
                    }
                case .failed(let error):
                    observer.receive(completion: .failure(error))
                case .completed:
                    _completions.outer = true
                    if _completions.inner {
                        observer.receive(completion: .finished)
                    }
                }
            }
            return compositeDisposable
        }
    }
}

extension SignalProtocol where Error == Never {

    /// Map each element into a signal and then flatten inner signals using the given strategy.
    /// `flatMap` is just a shorthand for `map(transform).flatten(strategy)`.
    ///
    /// Check out interactive examples for various strategies:
    /// * Strategy `.concat`: [https://rxmarbles.com/#concatMap](https://rxmarbles.com/#concatMap)
    /// * Strategy `.latest`: [https://rxmarbles.com/#switchMap](https://rxmarbles.com/#switchMap)
    /// * Strategy `.merge`: [https://rxmarbles.com/#mergeMap](https://rxmarbles.com/#mergeMap)
    public func flatMap<O: SignalProtocol>(_ strategy: FlattenStrategy, _ transform: @escaping (Element) -> O) -> Signal<O.Element, O.Error> {
        return (castError() as Signal<Element, O.Error>).map(transform).flatten(strategy)
    }

    /// Map each element into a signal and then flatten inner signals using `.concat` strategy.
    /// Shorthand for `flatMap(.concat, transform)`.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#concatMap](https://rxmarbles.com/#concatMap)
    public func flatMapConcat<O: SignalProtocol>(_ transform: @escaping (Element) -> O) -> Signal<O.Element, O.Error>  {
        return flatMap(.concat, transform)
    }

    /// Map each element into a signal and then flatten inner signals using `.latest` strategy.
    /// Shorthand for `flatMap(.latest, transform)`.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#switchMap](https://rxmarbles.com/#switchMap)
    public func flatMapLatest<O: SignalProtocol>(_ transform: @escaping (Element) -> O) -> Signal<O.Element, O.Error> {
        return flatMap(.latest, transform)
    }

    /// Map each element into a signal and then flatten inner signals using `.merge` strategy.
    /// Shorthand for `flatMap(.merge, transform)`.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#mergeMap](https://rxmarbles.com/#mergeMap)
    public func flatMapMerge<O: SignalProtocol>(_ transform: @escaping (Element) -> O) -> Signal<O.Element, O.Error> {
        return flatMap(.merge, transform)
    }
}

extension SignalProtocol where Element: SignalProtocol, Error == Never {

    /// Flatten the signal using the given strategy.
    ///
    /// - parameter strategy: Flattening strategy to use. Check out [FlattenStrategy](x-source-tag://FlattenStrategy) type from more info.
    public func flatten(_ strategy: FlattenStrategy) -> Signal<Element.Element, Element.Error> {
        return (castError() as Signal<Element, Element.Error>).flatten(strategy)
    }
}
