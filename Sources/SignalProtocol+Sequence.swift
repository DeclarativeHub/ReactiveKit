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
    /// Map element into a collection, flattening the collection into next elements.
    /// Shorthand for `map(transform).flattenElements()`.
    public func flatMap<NewElement>(_ transform: @escaping (Element) -> [NewElement]) -> Signal<NewElement, Error> {
        return map(transform).flattenElements()
    }
}

extension SignalProtocol where Element: Sequence {
    /// Map inner sequence.
    public func mapElement<NewElement>(_ transform: @escaping (Element.Iterator.Element) -> NewElement) -> Signal<[NewElement], Error> {
        return map { $0.map(transform) }
    }

    /// Unwrap elements from each emitted sequence into the elements of the signal.
    public func flattenElements() -> Signal<Element.Iterator.Element, Error> {
        return Signal { observer in
            self.observe { event in
                switch event {
                case let .next(sequence):
                    sequence.forEach(observer.receive(_:))
                case .completed:
                    observer.receive(completion: .finished)
                case let .failed(error):
                    observer.receive(completion: .failure(error))
                }
            }
        }
    }
}
