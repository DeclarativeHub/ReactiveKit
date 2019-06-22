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

    /// Map element into a result, propagating `.some` value as a next event or skipping an element in case of a `nil`.
    /// Shorthand for `map(transform).ignoreNils()`.
    public func compactMap<NewWrapped>(_ transform: @escaping (Element) -> NewWrapped?) -> Signal<NewWrapped, Error> {
        return map(transform).ignoreNils()
    }
}

extension SignalProtocol where Element: OptionalProtocol {

    /// Map inner optional.
    /// Shorthand for `map { $0.map(transform) }`.
    public func mapWrapped<NewWrapped>(_ transform: @escaping (Element.Wrapped) -> NewWrapped) -> Signal<NewWrapped?, Error> {
        return map { $0._unbox.map(transform) }
    }

    /// Replace all `nil`-elements with the provided replacement.
    public func replaceNils(with replacement: Element.Wrapped) -> Signal<Element.Wrapped, Error> {
        return compactMap { $0._unbox ?? replacement }
    }

    /// Suppress all `nil`-elements.
    public func ignoreNils() -> Signal<Element.Wrapped, Error> {
        return Signal { observer in
            return self.observe { event in
                switch event {
                case .next(let element):
                    if let element = element._unbox {
                        observer.receive(element)
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

public protocol OptionalProtocol {
    associatedtype Wrapped
    var _unbox: Optional<Wrapped> { get }
    init(nilLiteral: ())
    init(_ some: Wrapped)
}

extension Optional: OptionalProtocol {

    public var _unbox: Optional<Wrapped> {
        return self
    }
}
