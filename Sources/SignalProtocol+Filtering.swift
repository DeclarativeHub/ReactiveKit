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
    public func debounce(interval: Double, queue: DispatchQueue = DispatchQueue(label: "reactive_kit.debounce")) -> Signal<Element, Error> {
        return Signal { observer in
            var timerSubscription: Disposable? = nil
            var previousElement: Element? = nil
            return self.observe { event in
                timerSubscription?.dispose()
                switch event {
                case .next(let element):
                    previousElement = element
                    timerSubscription = queue.disposableAfter(when: interval) {
                        if let _element = previousElement {
                            observer.next(_element)
                            previousElement = nil
                        }
                    }
                case .failed(let error):
                    observer.failed(error)
                case .completed:
                    if let previousElement = previousElement {
                        observer.next(previousElement)
                        observer.completed()
                    }
                }

            }
        }
    }

    /// Emit first element and then all elements that are not equal to their predecessor(s).
    ///
    /// Check out interactive example at [https://rxmarbles.com/#distinctUntilChanged](https://rxmarbles.com/#distinctUntilChanged)
    public func distinctUntilChanged(_ areDistinct: @escaping (Element, Element) -> Bool) -> Signal<Element, Error> {
        return zipPrevious().compactMap { (prev, next) -> Element? in
            prev == nil || areDistinct(prev!, next) ? next : nil
        }
    }

    /// Emit only the element at given index (if such element is produced).
    ///
    /// Check out interactive example at [https://rxmarbles.com/#elementAt](https://rxmarbles.com/#elementAt)
    public func element(at index: Int) -> Signal<Element, Error> {
        return take(first: index + 1).last()
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
                        observer.next(element)
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
        return take(first: 1)
    }

    /// Ignore all elements (just propagate terminal events).
    ///
    /// Check out interactive example at [https://rxmarbles.com/#ignoreElements](https://rxmarbles.com/#ignoreElements)
    public func ignoreElements() -> Signal<Element, Error> {
        return filter { _ in false }
    }

    /// Ignore all terminal events (just propagate next events). The signal will never complete or error out.
    public func ignoreTerminal() -> Signal<Element, Error> {
        return Signal { observer in
            return self.observe { event in
                if case .next(let element) = event {
                    observer.next(element)
                }
            }
        }
    }

    /// Emit only the last element of the signal and then complete.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#last](https://rxmarbles.com/#last)
    public func last() -> Signal<Element, Error> {
        return take(last: 1)
    }

    /// Supress elements while the last element on the other signal is `false`.
    public func pausable<O: SignalProtocol>(by other: O) -> Signal<Element, Error> where O.Element == Bool {
        return Signal { observer in
            var allowed: Bool = true
            let compositeDisposable = CompositeDisposable()
            compositeDisposable += other.observeNext { value in
                allowed = value
            }
            compositeDisposable += self.observe { event in
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
    public func sample(interval: Double, on queue: DispatchQueue = DispatchQueue(label: "reactive_kit.sample")) -> Signal<Element, Error> {
        return Signal { observer in
            let serialDisposable = SerialDisposable(otherDisposable: nil)
            var latestElement: Element? = nil
            var dispatch: (() -> Void)!
            dispatch = {
                queue.after(when: interval) {
                    guard !serialDisposable.isDisposed else { dispatch = nil; return }
                    if let element = latestElement {
                        observer.next(element)
                        latestElement = nil
                    }
                    dispatch()
                }
            }
            serialDisposable.otherDisposable = self.observe { event in
                switch event {
                case .next(let element):
                    latestElement = element
                default:
                    observer.on(event)
                    serialDisposable.dispose()
                }
            }
            dispatch()
            return serialDisposable
        }
    }

    /// Suppress first `count` elements generated by the signal.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#skip](https://rxmarbles.com/#skip)
    public func skip(first count: Int) -> Signal<Element, Error> {
        return Signal { observer in
            var count = count
            return self.observe { event in
                switch event {
                case .next(let element):
                    if count > 0 {
                        count -= 1
                    } else {
                        observer.next(element)
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
    public func skip(last count: Int) -> Signal<Element, Error> {
        guard count > 0 else { return self.toSignal() }
        return Signal { observer in
            var buffer: [Element] = []
            return self.observe { event in
                switch event {
                case .next(let element):
                    buffer.append(element)
                    if buffer.count > count {
                        observer.next(buffer.removeFirst())
                    }
                default:
                    observer.on(event)
                }
            }
        }
    }

    /// Suppress elements for first `interval` seconds.
    public func skip(interval: Double) -> Signal<Element, Error> {
        return Signal { observer in
            let startTime = Date().addingTimeInterval(interval)
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
    public func take(first count: Int) -> Signal<Element, Error> {
        guard count > 0 else { return .completed() }
        return Signal { observer in
            var taken = 0
            return self.observe { event in
                switch event {
                case .next(let element):
                    if taken < count {
                        taken += 1
                        observer.next(element)
                    }
                    if taken == count {
                        observer.completed()
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
    public func take(last count: Int) -> Signal<Element, Error> {
        return Signal { observer in
            var values: [Element] = []
            values.reserveCapacity(count)
            return self.observe(with: { (event) in
                switch event {
                case .completed:
                    values.forEach(observer.next)
                    observer.completed()
                case .failed(let error):
                    observer.failed(error)
                case .next(let element):
                    if event.isTerminal {
                        observer.on(event)
                    } else {
                        if values.count + 1 > count {
                            values.removeFirst(values.count - count + 1)
                        }
                        values.append(element)
                    }
                }
            })
        }
    }

    /// Emit elements until the given closure returns first `false`.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#takeWhile](https://rxmarbles.com/#takeWhile)
    public func take(while shouldContinue: @escaping (Element) -> Bool) -> Signal<Element, Error> {
        return Signal { observer in
            return self.observe { event in
                switch event {
                case .next(let element):
                    if shouldContinue(element) {
                        observer.next(element)
                    } else {
                        observer.completed()
                    }
                default:
                    observer.on(event)
                }
            }
        }
    }

    /// Emit elements until the given signal sends an event (of any kind)
    /// and then complete and dispose the signal.
    public func take<S: SignalProtocol>(until signal: S) -> Signal<Element, Error> {
        return Signal { observer in
            let disposable = CompositeDisposable()
            disposable += signal.observe { _ in
                observer.completed()
            }
            disposable += self.observe { event in
                switch event {
                case .completed:
                    observer.completed()
                case .failed(let error):
                    observer.failed(error)
                case .next(let element):
                    observer.next(element)
                }
            }
            return disposable
        }
    }

    /// Throttle the signal to emit at most one element per given `seconds` interval.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#throttle](https://rxmarbles.com/#throttle)
    public func throttle(seconds: Double) -> Signal<Element, Error> {
        return Signal { observer in
            var lastEventTime: DispatchTime?
            return self.observe { event in
                switch event {
                case .next(let element):
                    let now = DispatchTime.now()
                    if lastEventTime == nil || now.rawValue > (lastEventTime! + seconds).rawValue {
                        lastEventTime = now
                        observer.next(element)
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
    public func distinctUntilChanged() -> Signal<Element, Error> {
        return distinctUntilChanged(!=)
    }
}
