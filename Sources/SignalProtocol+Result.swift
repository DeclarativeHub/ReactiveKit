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

    /// Maps signal elements into `Result.success` elements and signal errors into `Result.failure` elements.
    public func mapToResult() -> Signal<Result<Element, Error>, Never> {
        return materialize().compactMap { (event) -> Result<Element, Error>? in
            switch event {
            case .next(let element):
                return .success(element)
            case .failed(let error):
                return .failure(error)
            case .completed:
                return nil
            }
        }
    }

    /// Map element into a result, propagating success value as a next event or failure as a failed event.
    /// Shorthand for `map(transform).getValues()`.
    public func tryMap<U>(_ transform: @escaping (Element) -> Result<U, Error>) -> Signal<U, Error> {
        return map(transform).getValues()
    }
}

extension SignalProtocol where Error == Never {

    /// Map element into a result, propagating success value as a next event or failure as a failed event.
    /// Shorthand for `map(transform).getValues()`.
    public func tryMap<U, E>(_ transform: @escaping (Element) -> Result<U, E>) -> Signal<U, E> {
        return castError().map(transform).getValues()
    }
}

extension SignalProtocol where Element: _ResultProtocol {

    /// Map inner result.
    /// Shorthand for `map { $0.map(transform) }`.
    public func mapValue<NewSuccess>(_ transform: @escaping (Element.Value) -> NewSuccess) -> Signal<Result<NewSuccess, Element.Error>, Error> {
        return map { $0._unbox.map(transform) }
    }
}

extension SignalProtocol where Element: _ResultProtocol, Error == Element.Error {

    /// Unwraps values from result elements into elements of the signal.
    /// A failure result will trigger signal failure.
    public func getValues() -> Signal<Element.Value, Error> {
        return Signal { observer in
            return self.observe { event in
                switch event {
                case .next(let result):
                    switch result._unbox {
                    case .success(let element):
                        observer.receive(element)
                    case .failure(let error):
                        observer.receive(completion: .failure(error))
                    }
                case .completed:
                    observer.receive(completion: .finished)
                case .failed(let error):
                    observer.receive(completion: .failure(error))
                }
            }
        }
    }
}

extension SignalProtocol where Element: _ResultProtocol, Error == Never {

    /// Unwraps values from result elements into elements of the signal.
    /// A failure result will trigger signal failure.
    public func getValues() -> Signal<Element.Value, Element.Error> {
        return (castError() as Signal<Element, Element.Error>).getValues()
    }
}

public protocol _ResultProtocol {
    associatedtype Value
    associatedtype Error: Swift.Error
    var _unbox: Result<Value, Error> { get }
}

extension Result: _ResultProtocol {

    public var _unbox: Result {
        return self
    }
}
