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

    /// Propagate events only from a signal that starts emitting first.
    public func amb<O: SignalProtocol>(with other: O) -> Signal<Element, Error> where O.Element == Element, O.Error == Error {
        return Signal { observer in
            let lock = NSRecursiveLock(name: "reactive_kit.amb")
            let disposable = (my: SerialDisposable(otherDisposable: nil), other: SerialDisposable(otherDisposable: nil))
            var dispatching = (me: false, other: false)
            disposable.my.otherDisposable = self.observe { event in
                lock.lock(); defer { lock.unlock() }
                guard !dispatching.other else { return }
                dispatching.me = true
                observer.on(event)
                if !disposable.other.isDisposed {
                    disposable.other.dispose()
                }
            }
            disposable.other.otherDisposable = other.observe { event in
                lock.lock(); defer { lock.unlock() }
                guard !dispatching.me else { return }
                dispatching.other = true
                observer.on(event)
                if !disposable.my.isDisposed {
                    disposable.my.dispose()
                }
            }
            return CompositeDisposable([disposable.my, disposable.other])
        }
    }

    /// Emit a combination of latest elements from each signal. Starts when both signals emit at least one element,
    /// and emits `.next` when either signal generates an element by calling `combine` on the two latest elements.
    public func combineLatest<O: SignalProtocol, U>(with other: O, combine: @escaping (Element, O.Element) -> U) -> Signal<U, Error> where O.Error == Error {
        return Signal { observer in
            let lock = NSRecursiveLock(name: "reactive_kit.combine_latest_with")
            var elements: (my: Element?, other: O.Element?)
            var completions: (me: Bool, other: Bool) = (false, false)
            let compositeDisposable = CompositeDisposable()
            func onAnyNext() {
                if let myElement = elements.my, let otherElement = elements.other {
                    let combination = combine(myElement, otherElement)
                    observer.next(combination)
                }
            }
            func onAnyCompleted() {
                if completions.me == true && completions.other == true {
                    observer.completed()
                }
            }
            compositeDisposable += self.observe { event in
                lock.lock(); defer { lock.unlock() }
                switch event {
                case .next(let element):
                    elements.my = element
                    onAnyNext()
                case .failed(let error):
                    observer.failed(error)
                case .completed:
                    completions.me = true
                    onAnyCompleted()
                }
            }
            compositeDisposable += other.observe { event in
                lock.lock(); defer { lock.unlock() }
                switch event {
                case .next(let element):
                    elements.other = element
                    onAnyNext()
                case .failed(let error):
                    observer.failed(error)
                case .completed:
                    completions.other = true
                    onAnyCompleted()
                }
            }
            return compositeDisposable
        }
    }

    /// Emit a pair of latest elements from each signal. Starts when both signals emit at least one element,
    /// and emits `.next` when either signal generates an element.
    public func combineLatest<O: SignalProtocol>(with other: O) -> Signal<(Element, O.Element), Error> where O.Error == Error {
        return combineLatest(with: other, combine: { ($0, $1) })
    }

    /// First emit events from source and then from `other` signal.
    public func concat(with other: Signal<Element, Error>) -> Signal<Element, Error> {
        return Signal { observer in
            let serialDisposable = SerialDisposable(otherDisposable: nil)
            serialDisposable.otherDisposable = self.observe { event in
                switch event {
                case .next(let element):
                    observer.next(element)
                case .failed(let error):
                    observer.failed(error)
                case .completed:
                    serialDisposable.otherDisposable = other.observe(with: observer.on)
                }
            }
            return serialDisposable
        }
    }

    /// Merge emissions from both the receiver and the other signal into one signal.
    public func merge<O: SignalProtocol>(with other: O) -> Signal<Element, Error> where O.Element == Element, O.Error == Error {
        return Signal(sequence: [self.toSignal(), other.toSignal()]).merge()
    }

    /// Emit elements from the receiver and the other signal in pairs.
    /// This differs from `combineLatest` in that the combinations are produced from elements at same positions.
    public func zip<O: SignalProtocol, U>(with other: O, combine: @escaping (Element, O.Element) -> U) -> Signal<U, Error> where O.Error == Error {
        return Signal { observer in
            let lock = NSRecursiveLock(name: "reactive_kit.zip")
            var buffers: (my: [Element], other: [O.Element]) = ([], [])
            var completions: (me: Bool, other: Bool) = (false, false)
            let compositeDisposable = CompositeDisposable()
            let dispatchIfPossible = {
                while !buffers.my.isEmpty && !buffers.other.isEmpty {
                    let element = combine(buffers.my[0], buffers.other[0])
                    observer.next(element)
                    buffers.my.removeFirst()
                    buffers.other.removeFirst()
                }
            }
            func completeIfPossible() {
                if (buffers.my.isEmpty && completions.me) || (buffers.other.isEmpty && completions.other) {
                    observer.completed()
                }
            }
            compositeDisposable += self.observe { event in
                lock.lock(); defer { lock.unlock() }
                switch event {
                case .next(let element):
                    buffers.my.append(element)
                case .failed(let error):
                    observer.failed(error)
                case .completed:
                    completions.me = true
                }
                dispatchIfPossible()
                completeIfPossible()
            }
            compositeDisposable += other.observe { event in
                lock.lock(); defer { lock.unlock() }
                switch event {
                case .next(let element):
                    buffers.other.append(element)
                case .failed(let error):
                    observer.failed(error)
                case .completed:
                    completions.other = true
                }
                dispatchIfPossible()
                completeIfPossible()
            }
            return compositeDisposable
        }
    }


    /// Emit elements from the receiver and the other signal in pairs.
    /// This differs from `combineLatest` in that the pairs are produced from elements at same positions.
    public func zip<O: SignalProtocol>(with other: O) -> Signal<(Element, O.Element), Error> where O.Error == Error {
        return zip(with: other, combine: { ($0, $1) })
    }

    /// Combines the receiver and the other signal into a signal of combinations of elements whenever the
    /// receiver emits an element with the latest element from the other signal.
    public func with<O: SignalProtocol, U>(latestFrom other: O, combine: @escaping (Element, O.Element) -> U) -> Signal<U, Error> where O.Error == Error {
        return Signal { observer in
            var latest: O.Element? = nil
            let compositeDisposable = CompositeDisposable()
            compositeDisposable += other.observe { event in
                switch event {
                case .next(let element):
                    latest = element
                case .failed(let error):
                    observer.failed(error)
                case .completed:
                    break
                }
            }
            compositeDisposable += self.observe { event in
                switch event {
                case .completed:
                    observer.completed()
                case .failed(let error):
                    observer.failed(error)
                case .next(let element):
                    if let latest = latest {
                        observer.next(combine(element, latest))
                    }
                }
            }
            return compositeDisposable
        }
    }

    /// Combines the receiver and the other signal into a signal of pairs of elements whenever the
    /// receiver emits an element with the latest element from the other signal.
    public func with<O: SignalProtocol>(latestFrom other: O) -> Signal<(Element, O.Element), Error> where O.Error == Error {
        return with(latestFrom: other, combine: { ($0, $1) })
    }
}

extension SignalProtocol where Error == Never {

    /// Propagate events only from a signal that starts emitting first.
    public func amb<O: SignalProtocol>(with other: O) -> Signal<Element, O.Error> where O.Element == Element {
        return (castError() as Signal<Element, O.Error>).amb(with: other)
    }

    /// Emit a combination of latest elements from each signal. Starts when both signals emit at least one element,
    /// and emits `.next` when either signal generates an element by calling `combine` on the two latest elements.
    public func combineLatest<O: SignalProtocol, U>(with other: O, combine: @escaping (Element, O.Element) -> U) -> Signal<U, O.Error> {
        return (castError() as Signal<Element, O.Error>).combineLatest(with: other, combine: combine)
    }

    /// Emit a pair of latest elements from each signal. Starts when both signals emit at least one element,
    /// and emits `.next` when either signal generates an element.
    public func combineLatest<O: SignalProtocol>(with other: O) -> Signal<(Element, O.Element), O.Error> {
        return (castError() as Signal<Element, O.Error>).combineLatest(with: other, combine: { ($0, $1) })
    }

    /// Merge emissions from both the receiver and the other signal into one signal.
    public func merge<O: SignalProtocol>(with other: O) -> Signal<Element, O.Error> where O.Element == Element {
        return (castError() as Signal<Element, O.Error>).merge(with: other)
    }

    /// Emit elements from the receiver and the other signal in pairs.
    /// This differs from `combineLatest` in that the combinations are produced from elements at same positions.
    public func zip<O: SignalProtocol, U>(with other: O, combine: @escaping (Element, O.Element) -> U) -> Signal<U, O.Error> {
        return (castError() as Signal<Element, O.Error>).zip(with: other, combine: combine)
    }

    /// Emit elements from the receiver and the other signal in pairs.
    /// This differs from `combineLatest` in that the pairs are produced from elements at same positions.
    public func zip<O: SignalProtocol>(with other: O) -> Signal<(Element, O.Element), O.Error> {
        return (castError() as Signal<Element, O.Error>).zip(with: other, combine: { ($0, $1) })
    }

    /// Combines the receiver and the other signal into a signal of combinations of elements whenever the
    /// receiver emits an element with the latest element from the other signal.
    public func with<O: SignalProtocol, U>(latestFrom other: O, combine: @escaping (Element, O.Element) -> U) -> Signal<U, O.Error> {
        return (castError() as Signal<Element, O.Error>).with(latestFrom: other, combine: combine)
    }

    /// Combines the receiver and the other signal into a signal of pairs of elements whenever the
    /// receiver emits an element with the latest element from the other signal.
    public func with<O: SignalProtocol>(latestFrom other: O) -> Signal<(Element, O.Element), O.Error> {
        return (castError() as Signal<Element, O.Error>).with(latestFrom: other, combine: { ($0, $1) })
    }
}
