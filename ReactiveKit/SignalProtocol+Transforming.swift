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
    
    /// Batch the elements into arrays of given size.
    public func buffer(ofSize size: Int) -> Signal<[Element], Error> {
        return Signal { observer in
            var buffer: [Element] = []
            return self.observe { event in
                switch event {
                case .next(let element):
                    buffer.append(element)
                    if buffer.count == size {
                        observer.next(buffer)
                        buffer.removeAll()
                    }
                case .failed(let error):
                    observer.failed(error)
                case .completed:
                    observer.completed()
                }
            }
        }
    }

    /// Collect all elements into an array and emit just that array.
    public func collect() -> Signal<[Element], Error> {
        return reduce([], { memo, new in memo + [new] })
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

    /// Emit default element if signal completes without emitting any element.
    public func defaultIfEmpty(_ element: Element) -> Signal<Element, Error> {
        return Signal { observer in
            var didEmitNonTerminal = false
            return self.observe { event in
                switch event {
                case .next(let element):
                    didEmitNonTerminal = true
                    observer.next(element)
                case .failed(let error):
                    observer.failed(error)
                case .completed:
                    if !didEmitNonTerminal {
                        observer.next(element)
                    }
                    observer.completed()
                }
            }
        }
    }

    /// Map elements to Void.
    public func eraseType() -> Signal<Void, Error> {
        return map { _ in }
    }

    /// Replace all emitted elements with the given element.
    public func replaceElements<ReplacementElement>(with element: ReplacementElement) -> Signal<ReplacementElement, Error> {
        return map { _ in element }
    }

    /// Reduce signal events to a single event by applying given function on each emission.
    public func reduce<U>(_ initial: U, _ combine: @escaping (U, Element) -> U) -> Signal<U, Error> {
        return scan(initial, combine).take(last: 1)
    }

    /// Replays the latest element when other signal fires an element.
    public func replayLatest<S: SignalProtocol>(when other: S) -> Signal<Element, Error> where S.Error == Never {
        return Signal { observer in
            var latest: Element? = nil
            let disposable = CompositeDisposable()
            disposable += other.observe { event in
                switch event {
                case .next:
                    if let latest = latest {
                        observer.next(latest)
                    }
                case .completed:
                    break
                }
            }
            disposable += self.observe { event in
                switch event {
                case .next(let element):
                    latest = element
                    observer.next(element)
                case .failed(let error):
                    observer.failed(error)
                case .completed:
                    observer.completed()
                }
            }
            return disposable
        }
    }

    /// Apply `combine` to each element starting with `initial` and emit each
    /// intermediate result. This differs from `reduce` which emits only final result.
    public func scan<U>(_ initial: U, _ combine: @escaping (U, Element) -> U) -> Signal<U, Error> {
        return Signal { observer in
            var accumulator = initial
            observer.next(accumulator)
            return self.observe { event in
                switch event {
                case .next(let element):
                    accumulator = combine(accumulator, element)
                    observer.next(accumulator)
                case .failed(let error):
                    observer.failed(error)
                case .completed:
                    observer.completed()
                }
            }
        }
    }

    /// Prepend the given element to the signal emission.
    public func start(with element: Element) -> Signal<Element, Error> {
        return Signal { observer in
            observer.next(element)
            return self.observe { event in
                observer.on(event)
            }
        }
    }

    /// Batch each `size` elements into another signal.
    public func window(ofSize size: Int) -> Signal<Signal<Element, Error>, Error> {
        return buffer(ofSize: size).map { Signal(sequence: $0) }
    }

    /// Par each element with its predecessor. First element is paired with `nil`.
    public func zipPrevious() -> Signal<(Element?, Element), Error> {
        return Signal { observer in
            var previous: Element? = nil
            return self.observe { event in
                switch event {
                case .next(let element):
                    let lastPrevious = previous
                    previous = element
                    observer.next((lastPrevious, element))
                case .failed(let error):
                    observer.failed(error)
                case .completed:
                    observer.completed()
                }
            }
        }
    }
}
