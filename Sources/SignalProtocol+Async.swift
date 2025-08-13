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

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension SignalProtocol where Error == Never {

    public func toAsyncStream() -> AsyncStream<Element> {
        AsyncStream<Element> { continuation in
            let disposable = self.observe { event in
                switch event {
                case .next(let element):
                    continuation.yield(element)
                case .completed:
                    continuation.finish()
                }
            }
            continuation.onTermination = { @Sendable _ in
                disposable.dispose()
            }
        }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension SignalProtocol where Error == Swift.Error {

    public func toAsyncThrowingStream() -> AsyncThrowingStream<Element, Error> {
        AsyncThrowingStream<Element, Error> { continuation in
            let disposable = self.observe { event in
                switch event {
                case .next(let element):
                    continuation.yield(element)
                case .failed(let error):
                    continuation.finish(throwing: error)
                case .completed:
                    continuation.finish()
                }
            }
            continuation.onTermination = { @Sendable _ in
                disposable.dispose()
            }
        }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension AsyncSequence {

    public func toSignal() -> Signal<Element, Swift.Error> {
        Signal<Element, Swift.Error> { observer in
            let task = Task {
                do {
                    for try await element in self {
                        observer.receive(element)
                    }
                    observer.receive(completion: .finished)
                } catch {
                    observer.receive(completion: .failure(error))
                }
            }
            return BlockDisposable(task.cancel)
        }
    }
}

#if swift(>=6.0)
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, *)
extension AsyncSequence {
    
    public func toFullyTypedSignal() -> Signal<Element, Failure> {
        Signal<Element, Failure> { observer in
            let task = Task {
                do {
                    for try await element in self {
                        observer.receive(element)
                    }
                    observer.receive(completion: .finished)
                } catch let error as Failure {
                    observer.receive(completion: .failure(error))
                }
            }
            return BlockDisposable(task.cancel)
        }
    }
}
#endif
