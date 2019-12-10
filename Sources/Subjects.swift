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

extension SubjectProtocol {

    /// Convenience method to send `.next` event.
    public func send(_ element: Element) {
        on(.next(element))
    }

    /// Convenience method to send `.failed` or `.completed` event.
    public func send(completion: Subscribers.Completion<Error>) {
        switch completion {
        case .finished:
            on(.completed)
        case .failure(let error):
            on(.failed(error))
        }
    }

    /// Convenience method to send `.next` event followed by a `.completed` event.
    public func send(lastElement element: Element) {
        send(element)
        send(completion: .finished)
    }
}

extension SubjectProtocol where Element == Void {

    /// Convenience method to send `.next` event.
    public func send() {
        send(())
    }
}

/// A type that is both a signal and an observer.
/// Subject is a base subject class, please use one of the subclassesin your code.
open class Subject<Element, Error: Swift.Error>: SubjectProtocol {
    
    internal let lock = NSRecursiveLock(name: "com.reactive_kit.subject.lock")

    private typealias Token = Int64
    private var nextToken: Token = 0
    
    private var observers: [(Token, Observer<Element, Error>)] = []
    private var deletedObservers = Atomic(Set<Token>())
    
    public private(set) var isTerminated: Bool = false
    
    public let disposeBag = DisposeBag()
    
    fileprivate init() {}

    public func on(_ event: Signal<Element, Error>.Event) {
        guard !isTerminated else { return }

        isTerminated = event.isTerminal

        let deletedObservers = self.deletedObservers.value
        observers.removeAll(where: { (token, _) in
            deletedObservers.contains(token)
        })
        self.deletedObservers.mutate {
            $0.subtracting(deletedObservers)
        }

        for (_, observer) in observers {
            observer(event)
        }
    }
    
    open func observe(with observer: @escaping Observer<Element, Error>) -> Disposable {
        let token = nextToken
        nextToken += 1

        observers.append((token, observer))

        return BlockDisposable { [weak self] in
            self?.deletedObservers.mutate {
                $0.union([token])
            }
        }
    }
}

extension Subject: BindableProtocol {
    
    public func bind(signal: Signal<Element, Never>) -> Disposable {
        return signal
            .prefix(untilOutputFrom: disposeBag.deallocated)
            .receive(on: ExecutionContext.nonRecursive())
            .observeNext { [weak self] element in
                guard let s = self else { return }
                s.on(.next(element))
            }
    }
}

/// A subject that propagates received events to the registered observes.
public final class PassthroughSubject<Element, Error: Swift.Error>: Subject<Element, Error> {

    public override init() {
        super.init()
    }

    public override func on(_ event: Signal<Element, Error>.Event) {
        lock.lock(); defer { lock.unlock() }
        super.on(event)
    }

    public override func observe(with observer: @escaping (Signal<Element, Error>.Event) -> Void) -> Disposable {
        lock.lock(); defer { lock.unlock() }
        return super.observe(with: observer)
    }
}

/// A subject that replies accumulated sequence of events to each observer.
public final class ReplaySubject<Element, Error: Swift.Error>: Subject<Element, Error> {

    private var _buffer: ArraySlice<Signal<Element, Error>.Event> = []

    public let bufferSize: Int
    
    public init(bufferSize: Int = Int.max) {
        if bufferSize < Int.max {
            self.bufferSize = bufferSize + 1 // plus terminal event
        } else {
            self.bufferSize = bufferSize
        }
    }
    
    public override func on(_ event: Signal<Element, Error>.Event) {
        lock.lock(); defer { lock.unlock() }
        guard !isTerminated else { return }
        _buffer.append(event)
        _buffer = _buffer.suffix(bufferSize)
        super.on(event)
    }

    public override func observe(with observer: @escaping (Signal<Element, Error>.Event) -> Void) -> Disposable {
        lock.lock(); defer { lock.unlock() }
        let buffer = _buffer
        buffer.forEach(observer)
        return super.observe(with: observer)
    }
}

/// A ReplaySubject compile-time guaranteed never to emit an error.
public typealias SafeReplaySubject<Element> = ReplaySubject<Element, Never>

/// A subject that replies latest event to each observer.
public final class ReplayOneSubject<Element, Error: Swift.Error>: Subject<Element, Error> {

    private var _lastEvent: Signal<Element, Error>.Event?
    private var _terminalEvent: Signal<Element, Error>.Event?

    public override init() {
        super.init()
    }

    public override func on(_ event: Signal<Element, Error>.Event) {
        lock.lock(); defer { lock.unlock() }
        guard !isTerminated else { return }
        if event.isTerminal {
            _terminalEvent = event
        } else {
            _lastEvent = event
        }
        super.on(event)
    }

    public override func observe(with observer: @escaping (Signal<Element, Error>.Event) -> Void) -> Disposable {
        lock.lock(); defer { lock.unlock() }
        let (lastEvent, terminalEvent) = (_lastEvent, _terminalEvent)
        if let event = lastEvent {
            observer(event)
        }
        if let event = terminalEvent {
            observer(event)
        }
        return super.observe(with: observer)
    }
}

/// A ReplayOneSubject compile-time guaranteed never to emit an error.
public typealias SafeReplayOneSubject<Element> = ReplayOneSubject<Element, Never>

/// A subject that replies accumulated sequence of loading values to each observer.
public final class ReplayLoadingValueSubject<Val, LoadingError: Swift.Error, Error: Swift.Error>: Subject<LoadingState<Val, LoadingError>, Error> {
    
    private enum State {
        case notStarted
        case loading
        case loadedOrFailedAtLeastOnce
    }

    private var _state: State = .notStarted
    private var _buffer: ArraySlice<LoadingState<Val, LoadingError>> = []
    private var _terminalEvent: Signal<LoadingState<Val, LoadingError>, Error>.Event?

    public let bufferSize: Int
    
    public init(bufferSize: Int = Int.max) {
        self.bufferSize = bufferSize
    }
    
    public override func on(_ event: Signal<LoadingState<Val, LoadingError>, Error>.Event) {
        lock.lock(); defer { lock.unlock() }
        guard !isTerminated else { return }
        switch event {
        case .next(let loadingState):
            switch loadingState {
            case .loading:
                if _state == .notStarted {
                    _state = .loading
                }
            case .loaded:
                _state = .loadedOrFailedAtLeastOnce
                _buffer.append(loadingState)
                _buffer = _buffer.suffix(bufferSize)
            case .failed:
                _state = .loadedOrFailedAtLeastOnce
                _buffer = [loadingState]
            }
        case .failed, .completed:
            _terminalEvent = event
        }
        super.on(event)
    }

    public override func observe(with observer: @escaping (Signal<LoadingState<Val, LoadingError>, Error>.Event) -> Void) -> Disposable {
        lock.lock(); defer { lock.unlock() }
        switch _state {
        case .notStarted:
            break
        case .loading:
            observer(.next(.loading))
        case .loadedOrFailedAtLeastOnce:
            _buffer.forEach { observer(.next($0)) }
        }
        if let event = _terminalEvent {
            observer(event)
        }
        return super.observe(with: observer)
    }
}
