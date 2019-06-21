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

    /// Unwrap events into elements.
    public func materialize() -> Signal<Event<Element, Error>, Never> {
        return Signal { observer in
            return self.observe { event in
                switch event {
                case .next(let element):
                    observer.receive(.next(element))
                case .failed(let error):
                    observer.receive(.failed(error))
                    observer.receive(completion: .finished)
                case .completed:
                    observer.receive(.completed)
                    observer.receive(completion: .finished)
                }
            }
        }
    }

    /// Inverse of `materialize`.
    public func dematerialize<U, E>() -> Signal<U, E> where Element == Event<U, E>, E == Error {
        return Signal { observer in
            return self.observe { event in
                switch event {
                case .next(let innerEvent):
                    switch innerEvent {
                    case .next(let element):
                        observer.receive(element)
                    case .failed(let error):
                        observer.receive(completion: .failure(error))
                    case .completed:
                        observer.receive(completion: .finished)
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

extension SignalProtocol where Error == Never {

    /// Inverse of `materialize`.
    public func dematerialize<U, E>() -> Signal<U, E> where Element == Event<U, E> {
        return (castError() as Signal<Element, E>).dematerialize()
    }
}
