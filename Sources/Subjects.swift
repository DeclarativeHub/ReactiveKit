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
open class Subject<Element, Error: Swift.Error>: SubjectProtocol {

  private typealias Token = Int64
  private var nextToken: Token = 0

  private var observers: [(Token, Observer<Element, Error>)] = []

  public private(set) var isTerminated = false

  public let lock = NSRecursiveLock(name: "com.reactivekit.subject")
  public let disposeBag = DisposeBag()

  public init() {}

  public func on(_ event: Event<Element, Error>) {
    lock.lock(); defer { lock.unlock() }
    guard !isTerminated else { return }
    isTerminated = event.isTerminal
    send(event)
  }

  open func send(_ event: Event<Element, Error>) {
    forEachObserver { $0(event) }
  }

  open func observe(with observer: @escaping Observer<Element, Error>) -> Disposable {
    lock.lock(); defer { lock.unlock() }
    willAdd(observer: observer)
    return add(observer: observer)
  }

  open func willAdd(observer: @escaping Observer<Element, Error>) {
  }

  private func add(observer: @escaping Observer<Element, Error>) -> Disposable {
    let token = nextToken
    nextToken = nextToken + 1

    observers.append((token, observer))

    return BlockDisposable { [weak self] in
      guard let me = self else { return }
      guard let index = me.observers.index(where: { $0.0 == token }) else { return }
      me.observers.remove(at: index)
    }
  }

  private func forEachObserver(_ execute: (Observer<Element, Error>) -> Void) {
    for (_, observer) in observers {
      execute(observer)
    }
  }
}

extension Subject: BindableProtocol {

  public func bind(signal: Signal<Element, NoError>) -> Disposable {
    return signal
      .take(until: disposeBag.deallocated)
      .observeIn(.nonRecursive())
      .observeNext { [weak self] element in
        guard let s = self else { return }
        s.on(.next(element))
    }
  }
}

/// A subject that propagates received events to the registered observes.
public final class PublishSubject<Element, Error: Swift.Error>: Subject<Element, Error> {}

/// A subject that replies accumulated sequence of events to each observer.
public final class ReplaySubject<Element, Error: Swift.Error>: Subject<Element, Error> {

  private var buffer: ArraySlice<Event<Element, Error>> = []
  public let bufferSize: Int

  public init(bufferSize: Int = Int.max) {
    if bufferSize < Int.max {
      self.bufferSize = bufferSize + 1 // plus terminal event
    } else {
      self.bufferSize = bufferSize
    }
  }

  public override func send(_ event: Event<Element, Error>) {
    buffer.append(event)
    buffer = buffer.suffix(bufferSize)
    super.send(event)
  }

  public override func willAdd(observer: @escaping Observer<Element, Error>) {
    buffer.forEach(observer)
  }
}

/// A subject that replies latest event to each observer.
public final class ReplayOneSubject<Element, Error: Swift.Error>: Subject<Element, Error> {

  private var lastEvent: Event<Element, Error>? = nil
  private var terminalEvent: Event<Element, Error>? = nil

  public override func send(_ event: Event<Element, Error>) {
    if event.isTerminal {
      terminalEvent = event
    } else {
      lastEvent = event
    }
    super.send(event)
  }

  public override func willAdd(observer: @escaping Observer<Element, Error>) {
    if let event = lastEvent {
      observer(event)
    }
    if let event = terminalEvent {
      observer(event)
    }
  }
}


@available(*, deprecated, message: "All subjects now inherit 'Subject' that can be used in place of 'AnySubject'.")
public final class AnySubject<Element, Error: Swift.Error>: SubjectProtocol {
  private let baseObserve: (@escaping Observer<Element, Error>) -> Disposable
  private let baseOn: Observer<Element, Error>

  public let disposeBag = DisposeBag()

  public init<S: SubjectProtocol>(base: S) where S.Element == Element, S.Error == Error {
    baseObserve = base.observe
    baseOn = base.on
  }

  public func on(_ event: Event<Element, Error>) {
    return baseOn(event)
  }

  public func observe(with observer: @escaping Observer<Element, Error>) -> Disposable {
    return baseObserve(observer)
  }
}
