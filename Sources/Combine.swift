//
//  The MIT License (MIT)
//
//  Copyright (c) 2020 Srdan Rasic (@srdanrasic)
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

#if canImport(Combine)
import Combine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Combine.Publisher {

    /// Convert `Combine.Publisher` into `ReactiveKit.Signal`
    public func toSignal() -> Signal<Output, Failure> {
        return Signal { observer in
            let sink = Combine.Subscribers.Sink<Output, Failure>(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        observer.receive(completion: .finished)
                    case .failure(let error):
                        observer.receive(completion: .failure(error))
                    }
                },
                receiveValue: observer.receive(_:))
            self.subscribe(sink)
            return BlockDisposable(sink.cancel)
        }
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Signal {

    public struct CombinePublisher: Combine.Publisher {

        private class DisposableSubscription: Combine.Subscription {

            let disposable: Disposable

            init(disposable: Disposable) {
                self.disposable = disposable
            }

            func request(_ demand: Combine.Subscribers.Demand) {
            }

            func cancel() {
                disposable.dispose()
            }
        }

        public typealias Output = Element
        public typealias Failure = Error

        let signal: Signal<Element, Error>

        public func receive<S>(subscriber: S) where S: Combine.Subscriber, Failure == S.Failure, Output == S.Input {
            let disposable = CompositeDisposable()
            let subscription = DisposableSubscription(disposable: disposable)
            subscriber.receive(subscription: subscription)
            disposable += signal.observe { event in
                switch event {
                case .next(let element):
                    _ = subscriber.receive(element)
                case .failed(let error):
                    subscriber.receive(completion: .failure(error))
                case .completed:
                    subscriber.receive(completion: .finished)
                }
            }
        }
    }

    /// Convert `ReactiveKit.Signal` in `Combine.Publisher`
    public func toPublisher() -> Signal<Element, Error>.CombinePublisher {
        return .init(signal: self)
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension SignalProtocol {

    /// Convert `ReactiveKit.Signal` in `Combine.Publisher`
    public func toPublisher() -> Signal<Element, Error>.CombinePublisher {
        return .init(signal: toSignal())
    }
}

#endif
