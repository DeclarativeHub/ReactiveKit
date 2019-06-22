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
    
    /// Batch signal elements into arrays of the given size.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#bufferCount](https://rxmarbles.com/#bufferCount)
    public func buffer(ofSize size: Int) -> Signal<[Element], Error> {
        return Signal { observer in
            var buffer: [Element] = []
            return self.observe { event in
                switch event {
                case .next(let element):
                    buffer.append(element)
                    if buffer.count == size {
                        observer.receive(buffer)
                        buffer.removeAll()
                    }
                case .failed(let error):
                    observer.receive(completion: .failure(error))
                case .completed:
                    observer.receive(completion: .finished)
                }
            }
        }
    }

    /// Collect all elements into an array and emit the array as a single element.
    public func collect() -> Signal<[Element], Error> {
        return reduce([], { memo, new in memo + [new] })
    }

    /// Emit default element if the signal completes without emitting any element.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#defaultIfEmpty](https://rxmarbles.com/#defaultIfEmpty)
    public func defaultIfEmpty(_ element: Element) -> Signal<Element, Error> {
        return Signal { observer in
            var didEmitNonTerminal = false
            return self.observe { event in
                switch event {
                case .next(let element):
                    didEmitNonTerminal = true
                    observer.receive(element)
                case .failed(let error):
                    observer.receive(completion: .failure(error))
                case .completed:
                    if !didEmitNonTerminal {
                        observer.receive(element)
                    }
                    observer.receive(completion: .finished)
                }
            }
        }
    }

    /// Map all elements to instances of Void.
    public func eraseType() -> Signal<Void, Error> {
        return replaceElements(with: ())
    }

    /// Par each element with its predecessor, starting from the second element.
    /// Similar to `zipPrevious`, but starts from the second element.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#pairwise](https://rxmarbles.com/#pairwise)
    public func pairwise() -> Signal<(Element, Element), Error> {
        return zipPrevious().compactMap { a, b in a.flatMap { ($0, b) } }
    }

    /// Replace all emitted elements with the given element.
    public func replaceElements<ReplacementElement>(with element: ReplacementElement) -> Signal<ReplacementElement, Error> {
        return map { _ in element }
    }

    /// Reduce all elements to a single element. Similar to `scan`, but emits only the final element.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#reduce](https://rxmarbles.com/#reduce)
    public func reduce<U>(_ initial: U, _ combine: @escaping (U, Element) -> U) -> Signal<U, Error> {
        return scan(initial, combine).last()
    }

    /// Apply `combine` to each element starting with `initial` and emit each
    /// intermediate result. This differs from `reduce` which only emits the final result.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#scan](https://rxmarbles.com/#scan)
    public func scan<U>(_ initial: U, _ combine: @escaping (U, Element) -> U) -> Signal<U, Error> {
        return Signal { observer in
            var accumulator = initial
            observer.receive(accumulator)
            return self.observe { event in
                switch event {
                case .next(let element):
                    accumulator = combine(accumulator, element)
                    observer.receive(accumulator)
                case .failed(let error):
                    observer.receive(completion: .failure(error))
                case .completed:
                    observer.receive(completion: .finished)
                }
            }
        }
    }

    /// Prepend the given element to the signal element sequence.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#startWith](https://rxmarbles.com/#startWith)
    public func start(with element: Element) -> Signal<Element, Error> {
        return scan(element, { _, next in next })
    }

    /// Batch each `size` elements into another signal.
    public func window(ofSize size: Int) -> Signal<Signal<Element, Error>, Error> {
        return buffer(ofSize: size).map { Signal(sequence: $0) }
    }

    /// Par each element with its predecessor.
    /// Similar to `parwise`, but starts from the first element which is paird with `nil`.
    public func zipPrevious() -> Signal<(Element?, Element), Error> {
        return scan(nil) { (pair, next) in (pair?.1, next) }.ignoreNils()
    }
}
