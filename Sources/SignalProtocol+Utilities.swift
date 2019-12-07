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

    /// Raises a debugger signal when a provided closure needs to stop the process in the debugger.
    ///
    /// When any of the provided closures returns `true`, this signal raises the `SIGTRAP` signal to stop the process in the debugger.
    /// Otherwise, this signal passes through values and completions as-is.
    ///
    /// - Parameters:
    ///   - receiveSubscription: A closure that executes when when the signal receives a subscription. Return `true` from this closure to raise `SIGTRAP`, or false to continue.
    ///   - receiveOutput: A closure that executes when when the signal receives a value. Return `true` from this closure to raise `SIGTRAP`, or false to continue.
    ///   - receiveCompletion: A closure that executes when when the signal receives a completion. Return `true` from this closure to raise `SIGTRAP`, or false to continue.
    /// - Returns: A signal that raises a debugger signal when one of the provided closures returns `true`.
    @inlinable
    public func breakpoint(receiveSubscription: (() -> Bool)? = nil, receiveOutput: ((Element) -> Bool)? = nil, receiveCompletion: ((Subscribers.Completion<Error>) -> Bool)? = nil) -> Signal<Element, Error> {
        return handleEvents(
        receiveSubscription: {
                if receiveSubscription?() ?? false {
                    raise(SIGTRAP)
                }
        }, receiveOutput: { (element) in
            if receiveOutput?(element) ?? false {
                raise(SIGTRAP)
            }
        }, receiveCompletion: { (completion) in
            if receiveCompletion?(completion) ?? false {
                raise(SIGTRAP)
            }
        })
    }

    /// Raises a debugger signal upon receiving a failure.
    ///
    /// When the upstream signal fails with an error, this signal raises the `SIGTRAP` signal, which stops the process in the debugger.
    /// Otherwise, this signal passes through values and completions as-is.
    /// - Returns: A signal that raises a debugger signal upon receiving a failure.
    @inlinable
    public func breakpointOnError() -> Signal<Element, Error> {
        return breakpoint(receiveOutput: { _ in false }, receiveCompletion: { (completion) -> Bool in
            switch completion {
            case .failure:
                return true
            case .finished:
                return false
            }
        })
    }

    /// Log various signal events. If title is not provided, source file and function names are printed instead.
    public func debug(_ title: String? = nil, file: String = #file, function: String = #function, line: Int = #line) -> Signal<Element, Error> {
        let prefix: String
        if let title = title {
            prefix = "[\(title)]"
        } else {
            let filename = file.components(separatedBy: "/").last ?? file
            prefix = "[\(filename):\(function):\(line)]"
        }
        return handleEvents(
           receiveSubscription: {
                print("\(prefix) started")
        }, receiveOutput: { (element) in
            print("\(prefix) next(\(element))")
        }, receiveCompletion: { (completion) in
            switch completion {
            case .failure(let error):
                print("\(prefix) failed: \(error)")
            case .finished:
                print("\(prefix) finished")
            }
        }, receiveCancel: {
            print("\(prefix) disposed")
        })
    }
    
    /// Delay signal elements for `interval` time.
    ///
    /// Check out interactive example at [https://rxmarbles.com/#delay](https://rxmarbles.com/#delay)
    public func delay(interval: Double, on queue: DispatchQueue = DispatchQueue(label: "reactive_kit.delay")) -> Signal<Element, Error> {
        return Signal { observer in
            return self.observe { event in
                queue.asyncAfter(deadline: .now() + interval) {
                    observer.on(event)
                }
            }
        }
    }

    /// Repeat the receiver signal whenever the signal returned from the given closure emits an element.
    public func `repeat`<S: SignalProtocol>(when other: @escaping (Element) -> S) -> Signal<Element, Error> where S.Error == Never {
        return Signal { observer in
            let lock = NSRecursiveLock(name: "com.reactive_kit.signal.repeat")
            var _attempt: (() -> Void)?
            let outerDisposable = SerialDisposable(otherDisposable: nil)
            let innerDisposable = SerialDisposable(otherDisposable: nil)
            var _completions: (me: Bool, other: Bool) = (false, false)
            func _completeIfPossible() {
                if _completions.me && _completions.other {
                    observer.receive(completion: .finished)
                    _attempt = nil
                }
            }
            _attempt = {
                outerDisposable.otherDisposable?.dispose()
                outerDisposable.otherDisposable = self.observe { event in
                    lock.lock(); defer { lock.unlock() }
                    switch event {
                    case .next(let element):
                        observer.receive(element)
                        _completions.other = false
                        innerDisposable.otherDisposable?.dispose()
                        innerDisposable.otherDisposable = other(element).observe { otherEvent in
                            lock.lock(); defer { lock.unlock() }
                            switch otherEvent {
                            case .next:
                                _completions.me = false
                                _attempt?()
                            case .completed:
                                _completions.other = true
                                _completeIfPossible()
                            }
                        }
                    case .completed:
                        _completions.me = true
                        _completeIfPossible()
                    case .failed(let error):
                        observer.receive(completion: .failure(error))
                    }
                }
            }
            lock.lock(); defer { lock.unlock() }
            _attempt?()
            return CompositeDisposable([outerDisposable, innerDisposable])
        }
    }

    /// Performs the specified closures when signal events occur.
    ///
    /// - Parameters:
    ///   - receiveSubscription: A closure that executes when the signal receives the subscription. Defaults to `nil`.
    ///   - receiveOutput: A closure that executes when the signal receives a value from the upstream signal. Defaults to `nil`.
    ///   - receiveCompletion: A closure that executes when the signal receives the completion from the upstream signal. Defaults to `nil`.
    ///   - receiveCancel: A closure that executes when the downstream receiver is cancelled (disposed). Defaults to `nil`.
    /// - Returns: A publisher that performs the specified closures when publisher events occur.
    @inlinable
    public func handleEvents(receiveSubscription: (() -> Void)? = nil, receiveOutput: ((Element) -> Void)? = nil, receiveCompletion: ((Subscribers.Completion<Error>) -> Void)? = nil, receiveCancel: (() -> Void)? = nil) -> Signal<Element, Error> {
        return Signal { observer in
            receiveSubscription?()
            let disposable = self.observe { event in
                switch event {
                case .next(let value):
                    receiveOutput?(value)
                case .failed(let error):
                    receiveCompletion?(.failure(error))
                case .completed:
                    receiveCompletion?(.finished)
                }
                observer.on(event)
            }
            return BlockDisposable {
                disposable.dispose()
                receiveCancel?()
            }
        }
    }

    /// Update the given subject with `true` when the receiver starts and with `false` when the receiver terminates.
    public func feedActivity<S: SubjectProtocol>(into listener: S) -> Signal<Element, Error> where S.Element == Bool {
        return handleEvents(receiveSubscription: { listener.send(true) }, receiveCancel: { listener.send(false) })
    }

    /// Update the given subject with `.next` elements.
    public func feedNext<S: SubjectProtocol>(into listener: S) -> Signal<Element, Error> where S.Element == Element {
        return handleEvents(receiveOutput: { e in listener.send(e) })
    }

    /// Update the given subject with mapped `.next` element whenever the element satisfies the given constraint.
    public func feedNext<S: SubjectProtocol>(into listener: S, when: @escaping (Element) -> Bool = { _ in true }, map: @escaping (Element) -> S.Element) -> Signal<Element, Error> {
        return handleEvents(receiveOutput: { e in if when(e) { listener.send(map(e)) } })
    }

    /// Updates the given subject with error from .failed event is such occurs.
    public func feedError<S: SubjectProtocol>(into listener: S) -> Signal<Element, Error> where S.Element == Error {
        return handleEvents(receiveCompletion: { completion in
            switch completion {
            case .failure(let error):
                listener.send(error)
            case .finished:
                break
            }
        })
    }

    /// Blocks the current thread until the signal completes and then returns all events sent by the signal collected in an array.
    ///
    /// This operator is useful for testing purposes.
    public func waitAndCollectEvents() -> [Signal<Element, Error>.Event] {
        let semaphore = DispatchSemaphore(value: 0)
        var collectedEvents: [Signal<Element, Error>.Event] = []
        _ = materialize().collect().observeNext { events in
            collectedEvents.append(contentsOf: events)
            semaphore.signal()
        }
        semaphore.wait()
        return collectedEvents
    }

    /// Blocks the current thread until the signal completes and then returns all elements sent by the signal collected in an array.
    ///
    /// This operator is useful for testing purposes.
    public func waitAndCollectElements() -> [Element] {
        return waitAndCollectEvents().compactMap { event in
            switch event {
            case .next(let element):
                return element
            default:
                return nil
            }
        }
    }
}
