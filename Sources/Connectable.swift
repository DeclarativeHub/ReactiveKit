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
  private let lock = NSRecursiveLock()
  private let subject: Subject<Source.Element, Source.Error>

  public init(source: Source, subject: Subject<Source.Element, Source.Error>) {
    self.source = source
    self.subject = subject
  }

  /// Start the signal.
  public func connect() -> Disposable {
    lock.lock(); defer { lock.unlock() }
    if !subject.isTerminated {
      return source.observe(with: subject)
    } else {
      return SimpleDisposable(isDisposed: true)
    }
  }

  /// Register an observer that will receive events from the signal.
  /// Note that the events will not be generated until `connect` is called.
  public func observe(with observer: @escaping (Event<Source.Element, Source.Error>) -> Void) -> Disposable {
    return subject.observe(with: observer)
  }
}

public extension ConnectableSignalProtocol {

  /// Convert connectable signal into the ordinary signal by calling `connect`
  /// on the first observation and calling dispose when number of observers goes down to zero.
  public func refCount() -> Signal<Element, Error> {
    let lock = NSRecursiveLock()
    var count = 0
    var connectionDisposable: Disposable? = nil
    return Signal { observer in
      lock.lock(); defer { lock.unlock() }
      count = count + 1
      let disposable = self.observe(with: observer.on)
      if connectionDisposable == nil {
        connectionDisposable = self.connect()
      }
      return BlockDisposable {
        disposable.dispose()
        count = count - 1
        if count == 0 {
          connectionDisposable?.dispose()
          connectionDisposable = nil
        }
      }
    }
  }
}

extension SignalProtocol {

  /// Ensure that all observers see the same sequence of elements. Connectable.
  public func replay(limit: Int = Int.max) -> ConnectableSignal<Self> {
    if limit == 0 {
      return ConnectableSignal(source: self, subject: PublishSubject())
    } else if limit == 1 {
      return ConnectableSignal(source: self, subject: ReplayOneSubject())
    } else {
      return ConnectableSignal(source: self, subject: ReplaySubject(bufferSize: limit))
    }
  }

  /// Convert signal to a connectable signal.
  public func publish() -> ConnectableSignal<Self> {
    return ConnectableSignal(source: self, subject: PublishSubject())
  }

  /// Ensure that all observers see the same sequence of elements.
  /// Shorthand for `replay(limit).refCount()`.
  public func shareReplay(limit: Int = Int.max) -> Signal<Element, Error> {
    return replay(limit: limit).refCount()
  }
}

extension SignalProtocol where Element: LoadingStateProtocol {

  /// Ensure that all observers see the same sequence of elements. Connectable.
  public func replayValues(limit: Int = Int.max) -> ConnectableSignal<Signal<LoadingState<LoadingValue, LoadingError>, Error>> {
    if limit == 0 {
      return ConnectableSignal(source: map { $0.asLoadingState }, subject: PublishSubject())
    } else {
      return ConnectableSignal(source: map { $0.asLoadingState }, subject: ReplayLoadingValueSubject(bufferSize: limit))
    }
  }

  /// Ensure that all observers see the same sequence of elements.
  /// Shorthand for `replay(limit).refCount()`.
  public func shareReplayValues(limit: Int = Int.max) -> Signal<LoadingState<LoadingValue, LoadingError>, Error> {
    return replayValues(limit: limit).refCount()
  }
}
