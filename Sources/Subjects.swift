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
open class Subject<Element, Error: Swift.Error>: SubjectProtocol {
    
    private let deletedObserversDispatchQueue = DispatchQueue(label: "com.reactive_kit.subject.deleted_observers")
    private let lock = NSRecursiveLock(name: "com.reactive_kit.subject.lock")

    private typealias Token = Int64
    private var _nextToken: Token = 0
    
    private var _observers: [(Token, Observer<Element, Error>)] = []

    private var _deletedObservers = Set<Token>()
    
    private var _isTerminated: Bool = false
    public var isTerminated: Bool {
        lock.lock(); defer { lock.unlock() }
        return _isTerminated
    }
    
    public let disposeBag = DisposeBag()
    
    public init() {}
    
    public func on(_ event: Event<Element, Error>) {
        lock.lock(); defer { lock.unlock() }
        guard !_isTerminated else { return }
        _isTerminated = event.isTerminal
        receive(event: event)
    }

    open func receive(event: Event<Element, Error>) {
        
        let deletedObservers = deletedObserversDispatchQueue.sync { _deletedObservers }
        
        lock.lock()
        var filteredObservers = [(Token, Observer<Element, Error>)]()
        for (token, observer) in _observers {
            if deletedObservers.contains(token) == false {
                filteredObservers.append((token, observer))
                observer(event)
            }
        }
        self._observers = filteredObservers
        lock.unlock()
        
        deletedObserversDispatchQueue.async(flags: .barrier) {
            self._deletedObservers = self._deletedObservers.subtracting(deletedObservers)
        }
    }
    
    open func observe(with observer: @escaping Observer<Element, Error>) -> Disposable {
        lock.lock(); defer { lock.unlock() }
        willAdd(observer: observer)
        return _add(observer: observer)
    }
    
    open func willAdd(observer: @escaping Observer<Element, Error>) {
    }
    
    private func _add(observer: @escaping Observer<Element, Error>) -> Disposable {
        let token = _nextToken
        _nextToken = _nextToken + 1
        
        _observers.append((token, observer))
        
        return BlockDisposable { [weak self] in
            guard let self = self else { return }
            self.deletedObserversDispatchQueue.async(flags: .barrier) {
                self._deletedObservers.insert(token)
            }
        }
    }
}

extension Subject: BindableProtocol {
    
    public func bind(signal: Signal<Element, Never>) -> Disposable {
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
public final class PassthroughSubject<Element, Error: Swift.Error>: Subject<Element, Error> {}

/// A subject that replies accumulated sequence of events to each observer.
public final class ReplaySubject<Element, Error: Swift.Error>: Subject<Element, Error> {
    
    private let dispatchQueue = DispatchQueue(label: "com.reactive_kit.replay_subject")
    
    private var _buffer: ArraySlice<Event<Element, Error>> = []
    public let bufferSize: Int
    
    public init(bufferSize: Int = Int.max) {
        if bufferSize < Int.max {
            self.bufferSize = bufferSize + 1 // plus terminal event
        } else {
            self.bufferSize = bufferSize
        }
    }
    
    public override func receive(event: Event<Element, Error>) {
        dispatchQueue.async(flags: .barrier) {
            self._buffer.append(event)
            self._buffer = self._buffer.suffix(self.bufferSize)
        }
        super.receive(event: event)
    }
    
    public override func willAdd(observer: @escaping Observer<Element, Error>) {
        dispatchQueue.sync { self._buffer }.forEach(observer)
    }
}

/// A ReplaySubject compile-time guaranteed never to emit an error.
public typealias SafeReplaySubject<Element> = ReplaySubject<Element, Never>

/// A subject that replies latest event to each observer.
public final class ReplayOneSubject<Element, Error: Swift.Error>: Subject<Element, Error> {

    private let dispatchQueue = DispatchQueue(label: "com.reactive_kit.replay_one_subject")
    
    private var _lastEvent: Event<Element, Error>?
    private var _terminalEvent: Event<Element, Error>?
    
    public override func receive(event: Event<Element, Error>) {
        dispatchQueue.async {
            if event.isTerminal {
                self._terminalEvent = event
            } else {
                self._lastEvent = event
            }
        }
        super.receive(event: event)
    }
    
    public override func willAdd(observer: @escaping Observer<Element, Error>) {
        let (lastEvent, terminalEvent) = dispatchQueue.sync {
            (_lastEvent, _terminalEvent)
        }

        if let event = lastEvent {
            observer(event)
        }
        if let event = terminalEvent {
            observer(event)
        }
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
    
    private let lock = NSRecursiveLock(name: "com.reactive_kit.safe_replay_one_subject")
    
    private var _state: State = .notStarted
    private var _buffer: ArraySlice<LoadingState<Val, LoadingError>> = []
    private var _terminalEvent: Event<LoadingState<Val, LoadingError>, Error>?
    
    public let bufferSize: Int
    
    public init(bufferSize: Int = Int.max) {
        self.bufferSize = bufferSize
    }
    
    public override func receive(event: Event<LoadingState<Val, LoadingError>, Error>) {
        lock.lock(); defer { lock.unlock() }
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
        super.receive(event: event)
    }
    
    public override func willAdd(observer: @escaping Observer<LoadingState<Val, LoadingError>, Error>) {
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
    }
}
