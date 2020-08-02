//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Srdan Rasic (@srdanrasic)
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

/// Represents a signal that is started by calling `connect` on it.
public protocol ConnectableSignalProtocol: SignalProtocol {
    
    /// Start the signal.
    func connect() -> Disposable
}

/// Makes a signal connectable through the given subject.
public final class ConnectableSignal<Source: SignalProtocol>: ConnectableSignalProtocol {
    
    private let source: Source
    private let subject: Subject<Source.Element, Source.Error>
    
    public init(source: Source, subject: Subject<Source.Element, Source.Error>) {
        self.source = source
        self.subject = subject
    }
    
    /// Start the signal.
    public func connect() -> Disposable {
        if !subject.isTerminated {
            return source.observe(with: subject)
        } else {
            return SimpleDisposable(isDisposed: true)
        }
    }
    
    /// Register an observer that will receive events from the signal.
    /// Note that the events will not be generated until `connect` is called.
    public func observe(with observer: @escaping (Signal<Source.Element, Source.Error>.Event) -> Void) -> Disposable {
        return subject.observe(with: observer)
    }
}

extension ConnectableSignalProtocol {
    
    /// Convert connectable signal into the ordinary signal by calling `connect`
    /// on the first observation and calling dispose when number of observers goes down to zero.
    /// - parameter disconnectCount: Subscriptions count on which to disconnect. Defaults to `0`.
    public func refCount(disconnectCount: Int = 0) -> Signal<Element, Error> {
        let lock = NSRecursiveLock(name: "com.reactive_kit.connectable_signal.ref_count")
        var _count = 0
        var _connectionDisposable: Disposable? = nil
        return Signal { observer in
            lock.lock(); defer { lock.unlock() }
            _count = _count + 1
            let disposable = self.observe(with: observer.on)
            if _connectionDisposable == nil {
                _connectionDisposable = self.connect()
            }
            return BlockDisposable {
                lock.lock(); defer { lock.unlock() }
                disposable.dispose()
                _count = _count - 1
                if _count == disconnectCount {
                    _connectionDisposable?.dispose()
                    _connectionDisposable = nil
                }
            }
        }
    }
}

extension SignalProtocol {

    public func multicast(_ createSubject: () -> Subject<Element, Error>) -> ConnectableSignal<Self> {
        return ConnectableSignal(source: self, subject: createSubject())
    }

    public func multicast(subject: Subject<Element, Error>) -> ConnectableSignal<Self> {
        return ConnectableSignal(source: self, subject: subject)
    }
    
    /// Ensure that all observers see the same sequence of elements. Connectable.
    public func replay(limit: Int = Int.max) -> ConnectableSignal<Self> {
        if limit == 0 {
            return multicast(subject: PassthroughSubject())
        } else if limit == 1 {
            return multicast(subject: ReplayOneSubject())
        } else {
            return multicast(subject: ReplaySubject(bufferSize: limit))
        }
    }
    
    /// Convert signal to a connectable signal.
    public func publish() -> ConnectableSignal<Self> {
        return multicast(subject: PassthroughSubject())
    }
    
    /// Ensure that all observers see the same sequence of elements.
    /// Shorthand for `replay(limit).refCount()`.
    /// - parameter limit: Number of latest elements to buffer.
    /// - parameter keepAlive: Whether to keep the source signal connected even when all subscribers disconnect.
    public func share(limit: Int = Int.max, keepAlive: Bool = false) -> Signal<Element, Error> {
        return replay(limit: limit).refCount(disconnectCount: keepAlive ? Int.min : 0)
    }
}

extension SignalProtocol where Element: LoadingStateProtocol {
    
    /// Ensure that all observers see the same sequence of elements. Connectable.
    public func replayValues(limit: Int = Int.max) -> ConnectableSignal<Signal<LoadingState<Element.LoadingValue, Element.LoadingError>, Error>> {
        if limit == 0 {
            return ConnectableSignal(source: map { $0.asLoadingState }, subject: PassthroughSubject())
        } else {
            return ConnectableSignal(source: map { $0.asLoadingState }, subject: ReplayLoadingValueSubject(bufferSize: limit))
        }
    }
    
    /// Ensure that all observers see the same sequence of elements.
    /// Shorthand for `replay(limit).refCount()`.
    public func shareReplayValues(limit: Int = Int.max) -> Signal<LoadingState<Element.LoadingValue, Element.LoadingError>, Error> {
        return replayValues(limit: limit).refCount()
    }
}
