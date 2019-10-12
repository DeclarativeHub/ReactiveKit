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

    /// Emit an element only if `interval` time passes without emitting another element.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#debounceTime](https://rxmarbles.com/#debounceTime)
    public func debounce(for seconds: Double, queue: DispatchQueue = DispatchQueue(label: "com.reactive_kit.signal.debounce")) -> Signal<Element, Error> {
        return Signal { observer in
            let lock = NSRecursiveLock(name: "com.reactive_kit.signal.debounce")
            var timerSubscription: Disposable?
            var previousElement: Element?
            return self.observe { event in
                lock.lock()
                timerSubscription?.dispose()
                lock.unlock()
                switch event {
                case .next(let element):
                    lock.lock()
                    previousElement = element
                    timerSubscription = queue.disposableAfter(when: seconds) {
                        lock.lock(); defer { lock.unlock() }
                        if let _element = previousElement {
                            observer.receive(_element)
                            previousElement = nil
                        }
                    }
                    lock.unlock()
                case .failed(let error):
                    observer.receive(completion: .failure(error))
                case .completed:
                    if let previousElement = previousElement {
                        observer.receive(previousElement)
                        observer.receive(completion: .finished)
                    }
                }

            }
        }
    }

    /// Emit first element and then all elements that are not equal to their predecessor(s).
    ///
    /// Check out interactive example at [https://rxmarbles.com/#distinctUntilChanged](https://rxmarbles.com/#distinctUntilChanged)
    public func removeDuplicates(by areEqual: @escaping (Element, Element) -> Bool) -> Signal<Element, Error> {
        return zipPrevious().compactMap { (prev, next) -> Element? in
            prev == nil || !areEqual(prev!, next) ? next : nil
        }
    }

    /// Emit only the element at given index (if such element is produced).
    ///
    /// Check out interactive example at [https://rxmarbles.com/#elementAt](https://rxmarbles.com/#elementAt)
    public func output(at index: Int) -> Signal<Element, Error> {
        return prefix(maxLength: index + 1).last()
    }

    /// Emit only elements that pass the `include` test.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#filter](https://rxmarbles.com/#filter)
    public func filter(_ isIncluded: @escaping (Element) -> Bool) -> Signal<Element, Error> {
        return Signal { observer in
            return self.observe { event in
                switch event {
                case .next(let element):
                    if isIncluded(element) {
                        observer.receive(element)
                    }
                default:
                    observer.on(event)
                }
            }
        }
    }

    /// Filter the signal by executing `isIncluded` in each element and
    /// propagate that element only if the returned signal emits `true`.
    public func flatMapFilter(_ strategy: FlattenStrategy = .concat, _ isIncluded: @escaping (Element) -> SafeSignal<Bool>) -> Signal<Element, Error> {
        return flatMap(strategy) { element -> Signal<Element, Error> in
            return isIncluded(element)
                .first()
                .map { isIncluded -> Element? in
                    if isIncluded {
                        return element
                    } else {
                        return nil
                    }
                }
                .ignoreNils()
                .castError()
        }
    }

    /// Emit only the first element of the signal and then complete.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#first](https://rxmarbles.com/#first)
    public func first() -> Signal<Element, Error> {
        return prefix(maxLength: 1)
    }

    /// Ignore all elements (just propagate terminal events).
    ///
    /// Check out interactive example at [https://rxmarbles.com/#ignoreElements](https://rxmarbles.com/#ignoreElements)
    public func ignoreOutput() -> Signal<Element, Error> {
        return filter { _ in false }
    }

    /// Ignore all terminal events (just propagate next events). The signal will never complete or error out.
    public func ignoreTerminal() -> Signal<Element, Error> {
        return Signal { observer in
            return self.observe { event in
                if case .next(let element) = event {
                    observer.receive(element)
                }
            }
        }
    }

    /// Emit only the last element of the signal and then complete.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#last](https://rxmarbles.com/#last)
    public func last() -> Signal<Element, Error> {
        return suffix(maxLength: 1)
    }

    /// Supress elements while the last element on the other signal is `false`.
    public func pausable<O: SignalProtocol>(by other: O) -> Signal<Element, Error> where O.Element == Bool {
        return Signal { observer in
            let lock = NSRecursiveLock(name: "com.reactive_kit.signal.pausable")
            var allowed: Bool = true
            let compositeDisposable = CompositeDisposable()
            compositeDisposable += other.observeNext { value in
                lock.lock(); defer { lock.unlock() }
                allowed = value
            }
            compositeDisposable += self.observe { event in
                lock.lock(); defer { lock.unlock() }
                if event.isTerminal || allowed {
                    observer.on(event)
                }
            }
            return compositeDisposable
        }
    }

    /// Periodically sample the signal and emit the latest element from each interval.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#sample](https://rxmarbles.com/#sample)
    public func sample(interval: Double, on queue: DispatchQueue = DispatchQueue(label: "com.reactive_kit.signal.sample")) -> Signal<Element, Error> {
        return Signal { observer in
            let lock = NSRecursiveLock(name: "com.reactive_kit.signal.sample")
            let serialDisposable = SerialDisposable(otherDisposable: nil)
            var _latestElement: Element?
            var _dispatch: (() -> Void)?
            _dispatch = {
                queue.asyncAfter(deadline: .now() + interval) {
                    lock.lock(); defer { lock.unlock() }
                    guard !serialDisposable.isDisposed else {
                        _dispatch = nil;
                        return
                    }
                    if let element = _latestElement {
                        observer.receive(element)
                        _latestElement = nil
                    }
                    _dispatch?()
                }
            }
            serialDisposable.otherDisposable = self.observe { event in
                switch event {
                case .next(let element):
                    lock.lock(); defer { lock.unlock() }
                    _latestElement = element
                default:
                    observer.on(event)
                    serialDisposable.dispose()
                }
            }
            lock.lock(); defer { lock.unlock() }
            _dispatch?()
            return serialDisposable
        }
    }

    /// Suppress first `count` elements generated by the signal.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#skip](https://rxmarbles.com/#skip)
    public func dropFirst(_ count: Int) -> Signal<Element, Error> {
        return Signal { observer in
            let lock = NSRecursiveLock(name: "com.reactive_kit.signal.skip")
            var _count = count
            return self.observe { event in
                switch event {
                case .next(let element):
                    lock.lock(); defer { lock.unlock() }
                    if _count > 0 {
                        _count -= 1
                    } else {
                        observer.receive(element)
                    }
                default:
                    observer.on(event)
                }
            }
        }
    }

    /// Suppress last `count` elements generated by the signal.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#skip](https://rxmarbles.com/#skip)
    public func dropLast(_ count: Int) -> Signal<Element, Error> {
        guard count > 0 else { return self.toSignal() }
        return Signal { observer in
            let lock = NSRecursiveLock(name: "com.reactive_kit.signal.skip")
            var _buffer: [Element] = []
            return self.observe { event in
                switch event {
                case .next(let element):
                    lock.lock(); defer { lock.unlock() }
                    _buffer.append(element)
                    if _buffer.count > count {
                        observer.receive(_buffer.removeFirst())
                    }
                default:
                    observer.on(event)
                }
            }
        }
    }

    /// Suppress elements for first `interval` seconds.
    public func dropFirst(for seconds: Double) -> Signal<Element, Error> {
        return Signal { observer in
            let startTime = Date().addingTimeInterval(seconds)
            return self.observe { event in
                switch event {
                case .next:
                    if startTime < Date() {
                        observer.on(event)
                    }
                case .completed, .failed:
                    observer.on(event)
                }
            }
        }
    }

    /// Emit only first `count` elements of the signal and then complete.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#take](https://rxmarbles.com/#take)
    public func prefix(maxLength: Int) -> Signal<Element, Error> {
        guard maxLength > 0 else { return .completed() }
        return Signal { observer in
            let lock = NSRecursiveLock(name: "com.reactive_kit.signal.take")
            var _taken = 0
            return self.observe { event in
                switch event {
                case .next(let element):
                    lock.lock(); defer { lock.unlock() }
                    if _taken < maxLength {
                        _taken += 1
                        observer.receive(element)
                    }
                    if _taken == maxLength {
                        observer.receive(completion: .finished)
                    }
                default:
                    observer.on(event)
                }
            }
        }
    }

    /// Emit only last `count` elements of the signal and then complete.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#takeLast](https://rxmarbles.com/#takeLast)
    public func suffix(maxLength: Int) -> Signal<Element, Error> {
        return Signal { observer in
            let lock = NSRecursiveLock(name: "com.reactive_kit.signal.take")
            var _values: [Element] = []
            _values.reserveCapacity(maxLength)
            return self.observe(with: { (event) in
                switch event {
                case .completed:
                    lock.lock(); defer { lock.unlock() }
                    _values.forEach(observer.receive(_:))
                    observer.receive(completion: .finished)
                case .failed(let error):
                    observer.receive(completion: .failure(error))
                case .next(let element):
                    if event.isTerminal {
                        observer.on(event)
                    } else {
                        lock.lock(); defer { lock.unlock() }
                        if _values.count + 1 > maxLength {
                            _values.removeFirst(_values.count - maxLength + 1)
                        }
                        _values.append(element)
                    }
                }
            })
        }
    }

    /// Emit elements until the given closure returns first `false`.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#takeWhile](https://rxmarbles.com/#takeWhile)
    public func prefix(while shouldContinue: @escaping (Element) -> Bool) -> Signal<Element, Error> {
        return Signal { observer in
            return self.observe { event in
                switch event {
                case .next(let element):
                    if shouldContinue(element) {
                        observer.receive(element)
                    } else {
                        observer.receive(completion: .finished)
                    }
                default:
                    observer.on(event)
                }
            }
        }
    }

    /// Emit elements until the given signal sends an event (of any kind)
    /// and then complete and dispose the signal.
    public func prefix<S: SignalProtocol>(untilOutputFrom signal: S) -> Signal<Element, Error> {
        return Signal { observer in
            let disposable = CompositeDisposable()
            disposable += signal.observe { _ in
                observer.receive(completion: .finished)
            }
            disposable += self.observe { event in
                switch event {
                case .completed:
                    observer.receive(completion: .finished)
                case .failed(let error):
                    observer.receive(completion: .failure(error))
                case .next(let element):
                    observer.receive(element)
                }
            }
            return disposable
        }
    }

    /// Throttle the signal to emit at most one element per given `seconds` interval.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#throttle](https://rxmarbles.com/#throttle)
    public func throttle(for seconds: Double) -> Signal<Element, Error> {
        return Signal { observer in
            let lock = NSRecursiveLock(name: "com.reactive_kit.signal.throttle")
            var _lastEventTime: DispatchTime?
            return self.observe { event in
                switch event {
                case .next(let element):
                    lock.lock(); defer { lock.unlock() }
                    let now = DispatchTime.now()
                    if _lastEventTime == nil || now.rawValue > (_lastEventTime! + seconds).rawValue {
                        _lastEventTime = now
                        observer.receive(element)
                    }
                default:
                    observer.on(event)
                }
            }
        }
    }
}

extension SignalProtocol where Element: Equatable {

    /// Emit first element and then all elements that are not equal to their predecessor(s).
    ///
    /// Check out interactive example at [https://rxmarbles.com/#distinctUntilChanged](https://rxmarbles.com/#distinctUntilChanged)
    public func removeDuplicates() -> Signal<Element, Error> {
        return removeDuplicates(by: ==)
    }
}
