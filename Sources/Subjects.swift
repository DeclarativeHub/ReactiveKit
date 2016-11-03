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

/// A type that is both a signal and an observer.
public protocol SubjectProtocol: SignalProtocol, ObserverProtocol {
}

/// A type that is both a signal and an observer.
public final class PublishSubject<Element, Error: Swift.Error>: ObserverRegister<(Event<Element, Error>) -> Void>, SubjectProtocol {

  private let lock = NSRecursiveLock(name: "com.reactivekit.publishsubject")
  private var terminated = false

  public let disposeBag = DisposeBag()

  public override init() {
  }

  public func on(_ event: Event<Element, Error>) {
    lock.lock(); defer { lock.unlock() }
    guard !terminated else { return }
    terminated = event.isTerminal
    forEachObserver { $0(event) }
  }

  public func observe(with observer: @escaping (Event<Element, Error>) -> Void) -> Disposable {
    return add(observer: observer)
  }
}

extension PublishSubject: BindableProtocol {
  
  public func bind(signal: Signal<Element, NoError>) -> Disposable {
    return signal
      .take(until: disposeBag.deallocated)
      .observeNext { [weak self] element in
        guard let s = self else { return }
        s.on(.next(element))
      }
  }
}

public typealias PublishSubject1<Element> = PublishSubject<Element, NoError>

public final class ReplaySubject<Element, Error: Swift.Error>: ObserverRegister<(Event<Element, Error>) -> Void>, SubjectProtocol {

  private var buffer: ArraySlice<Event<Element, Error>> = []
  private let lock = NSRecursiveLock(name: "com.reactivekit.replaysubject")

  public let bufferSize: Int
  public let disposeBag = DisposeBag()

  public init(bufferSize: Int = Int.max) {
    if bufferSize < Int.max {
      self.bufferSize = bufferSize + 1 // plus terminal event
    } else {
      self.bufferSize = bufferSize
    }
  }

  public func on(_ event: Event<Element, Error>) {
    lock.lock(); defer { lock.unlock() }
    guard !terminated else { return }
    buffer.append(event)
    buffer = buffer.suffix(bufferSize)
    forEachObserver { $0(event) }
  }

  public func observe(with observer: @escaping (Event<Element, Error>) -> Void) -> Disposable {
    lock.lock(); defer { lock.unlock() }
    buffer.forEach(observer)
    return add(observer: observer)
  }

  private var terminated: Bool {
    if let lastEvent = buffer.last {
      return lastEvent.isTerminal
    } else {
      return false
    }
  }
}

internal class _ReplayOneSubject<Element, Error: Swift.Error>: ObserverRegister<(Event<Element, Error>) -> Void>, SubjectProtocol {

  private var lastEvent: Event<Element, Error>? = nil
  private var terminalEvent: Event<Element, Error>? = nil
  private let lock = NSRecursiveLock(name: "com.reactivekit.replayonesubject")

  public override init() {
  }

  public func on(_ event: Event<Element, Error>) {
    lock.lock(); defer { lock.unlock() }
    guard terminalEvent == nil else { return }
    if event.isTerminal {
      terminalEvent = event
    } else {
      lastEvent = event
    }
    forEachObserver { $0(event) }
  }

  public func observe(with observer: @escaping (Event<Element, Error>) -> Void) -> Disposable {
    lock.lock(); defer { lock.unlock() }
    if let event = lastEvent {
      observer(event)
    }
    if let event = terminalEvent {
      observer(event)
    }
    return add(observer: observer)
  }
}

public final class ReplayOneSubject<Element, Error: Swift.Error>: _ReplayOneSubject<Element, Error> {
  public let disposeBag = DisposeBag()
}

public final class AnySubject<Element, Error: Swift.Error>: SubjectProtocol {
  private let baseObserve: (@escaping (Event<Element, Error>) -> Void) -> Disposable
  private let baseOn: (Event<Element, Error>) -> Void

  public let disposeBag = DisposeBag()

  public init<S: SubjectProtocol>(base: S) where S.Element == Element, S.Error == Error {
    baseObserve = base.observe
    baseOn = base.on
  }

  public func on(_ event: Event<Element, Error>) {
    return baseOn(event)
  }

  public func observe(with observer: @escaping (Event<Element, Error>) -> Void) -> Disposable {
    return baseObserve(observer)
  }
}

// MARK: ObserverRegister

private class ObserverRegister<Observer> {
  private typealias Token = Int64
  private var nextToken: Token = 0

  private var observers: [Token: Observer] = [:]
  private let tokenLock = NSRecursiveLock(name: "com.reactivekit.observerregister")

  public init() {}

  public func add(observer: Observer) -> Disposable {
    tokenLock.lock()
    let token = nextToken
    nextToken = nextToken + 1
    tokenLock.unlock()

    observers[token] = observer

    return BlockDisposable { [weak self] in
      let _ = self?.observers.removeValue(forKey: token)
    }
  }

  public func forEachObserver(_ execute: (Observer) -> Void) {
    for (_, observer) in observers {
      execute(observer)
    }
  }
}
