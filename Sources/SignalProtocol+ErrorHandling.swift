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
    /// Transform error by applying `transform` on it.
    public func mapError<F>(_ transform: @escaping (Error) -> F) -> Signal<Element, F> {
        return Signal { observer in
            self.observe { event in
                switch event {
                case let .next(element):
                    observer.receive(element)
                case let .failed(error):
                    observer.receive(completion: .failure(transform(error)))
                case .completed:
                    observer.receive(completion: .finished)
                }
            }
        }
    }

    /// Branch out error into another signal.
    public func branchOutError() -> (Signal<Element, Never>, Signal<Error, Never>) {
        let shared = share()
        return (shared.suppressError(logging: false), shared.toErrorSignal())
    }

    /// Branch out mapped error into another signal.
    public func branchOutError<F>(_ mapError: @escaping (Error) -> F) -> (Signal<Element, Never>, Signal<F, Never>) {
        let shared = share()
        return (shared.suppressError(logging: false), shared.toErrorSignal().map(mapError))
    }

    /// Convert signal into a non-failable signal by suppressing the error.
    public func suppressError(logging: Bool, file: String = #file, line: Int = #line) -> Signal<Element, Never> {
        return Signal { observer in
            self.observe { event in
                switch event {
                case let .next(element):
                    observer.receive(element)
                case let .failed(error):
                    observer.receive(completion: .finished)
                    if logging {
                        print("Signal at \(file):\(line) encountered an error: \(error)")
                    }
                case .completed:
                    observer.receive(completion: .finished)
                }
            }
        }
    }

    /// Convert signal into a non-failable signal by feeding suppressed error into a subject.
    public func suppressAndFeedError<S: SubjectProtocol>(into listener: S, logging: Bool = true, file: String = #file, line: Int = #line) -> Signal<Element, Never> where S.Element == Error {
        return feedError(into: listener).suppressError(logging: logging, file: file, line: line)
    }

    /// Recover the signal by propagating default element if an error happens.
    public func replaceError(with element: Element) -> Signal<Element, Never> {
        return Signal { observer in
            self.observe { event in
                switch event {
                case let .next(element):
                    observer.receive(element)
                case .failed:
                    observer.receive(element)
                    observer.receive(completion: .finished)
                case .completed:
                    observer.receive(completion: .finished)
                }
            }
        }
    }

    /// Retry the signal in case of failure at most `times` number of times.
    public func retry(_ times: Int) -> Signal<Element, Error> {
        guard times > 0 else { return toSignal() }
        return Signal { observer in
            let lock = NSRecursiveLock(name: "com.reactive_kit.signal.retry")
            var _remainingAttempts = times
            let serialDisposable = SerialDisposable(otherDisposable: nil)
            var _attempt: (() -> Void)?
            _attempt = {
                serialDisposable.otherDisposable?.dispose()
                serialDisposable.otherDisposable = self.observe { event in
                    switch event {
                    case let .next(element):
                        observer.receive(element)
                    case let .failed(error):
                        lock.lock(); defer { lock.unlock() }
                        if _remainingAttempts > 0 {
                            _remainingAttempts -= 1
                            _attempt?()
                        } else {
                            _attempt = nil
                            observer.receive(completion: .failure(error))
                        }
                    case .completed:
                        lock.lock(); defer { lock.unlock() }
                        _attempt = nil
                        observer.receive(completion: .finished)
                    }
                }
            }
            lock.lock(); defer { lock.unlock() }
            _attempt?()
            return BlockDisposable {
                serialDisposable.dispose()
                lock.lock(); defer { lock.unlock() }
                _attempt = nil
            }
        }
    }

    /// Retry the failed signal when other signal produces an element.
    /// - parameter other: Signal that triggers a retry attempt.
    /// - parameter shouldRetry: Retries only if this returns true for a given error. Defaults to always returning true.
    public func retry<S: SignalProtocol>(when other: S, if shouldRetry: @escaping (Error) -> Bool = { _ in true }) -> Signal<Element, Error> where S.Error == Never {
        return Signal { observer in
            let lock = NSRecursiveLock(name: "com.reactive_kit.signal.retry")
            let serialDisposable = SerialDisposable(otherDisposable: nil)
            var _attempt: (() -> Void)?
            _attempt = {
                serialDisposable.otherDisposable?.dispose()
                let compositeDisposable = CompositeDisposable()
                serialDisposable.otherDisposable = compositeDisposable
                compositeDisposable += self.observe { event in
                    switch event {
                    case let .next(element):
                        observer.receive(element)
                    case .completed:
                        lock.lock(); defer { lock.unlock() }
                        _attempt = nil
                        serialDisposable.otherDisposable?.dispose()
                        observer.receive(completion: .finished)
                    case let .failed(error):
                        if shouldRetry(error) {
                            compositeDisposable += other.first().observe { otherEvent in
                                lock.lock(); defer { lock.unlock() }
                                switch otherEvent {
                                case .next:
                                    _attempt?()
                                default:
                                    break
                                }
                            }
                        } else {
                            lock.lock(); defer { lock.unlock() }
                            _attempt = nil
                            serialDisposable.otherDisposable?.dispose()
                            observer.receive(completion: .failure(error))
                        }
                    }
                }
            }

            lock.lock(); defer { lock.unlock() }
            _attempt?()

            return BlockDisposable {
                lock.lock(); defer { lock.unlock() }
                _attempt = nil
                serialDisposable.dispose()
            }
        }
    }

    /// Error out if the `interval` time passes with no emitted elements.
    public func timeout(after interval: Double, with error: Error, on queue: DispatchQueue = DispatchQueue(label: "com.reactive_kit.signal.timeout")) -> Signal<Element, Error> {
        return Signal { observer in
            let lock = NSRecursiveLock(name: "com.reactive_kit.signal.timeout")
            var _completed = false
            let timeoutWhenPossible: () -> Disposable = {
                queue.disposableAfter(when: interval) {
                    lock.lock(); defer { lock.unlock() }
                    if !_completed {
                        _completed = true
                        observer.receive(completion: .failure(error))
                    }
                }
            }
            var _lastSubscription = timeoutWhenPossible()
            return self.observe { event in
                lock.lock(); defer { lock.unlock() }
                _lastSubscription.dispose()
                observer.on(event)
                _completed = event.isTerminal
                _lastSubscription = timeoutWhenPossible()
            }
        }
    }

    /// Map failable signal into a non-failable signal of errors. Ignores `.next` events.
    public func toErrorSignal() -> Signal<Error, Never> {
        return Signal { observer in
            self.observe { taskEvent in
                switch taskEvent {
                case .next:
                    break
                case .completed:
                    observer.receive(completion: .finished)
                case let .failed(error):
                    observer.receive(error)
                    observer.receive(completion: .finished)
                }
            }
        }
    }
}

extension SignalProtocol where Error == Never {
    /// Safe error casting from Never to some Error type.
    public func castError<E>() -> Signal<Element, E> {
        return Signal { observer in
            self.observe { event in
                switch event {
                case let .next(element):
                    observer.receive(element)
                case .completed:
                    observer.receive(completion: .finished)
                }
            }
        }
    }
}
