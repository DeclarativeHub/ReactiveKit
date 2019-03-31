//
//  The MIT License (MIT)
//
//  Copyright (c) 2018 Srdan Rasic (@srdanrasic)
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

/// Represents loading state of a value. Element of LoadingSignal.
public protocol LoadingStateProtocol {
    
    associatedtype LoadingValue
    associatedtype LoadingError: Error
    
    var asLoadingState: LoadingState<LoadingValue, LoadingError> { get }
}

extension LoadingStateProtocol {
    
    /// True if self is `.loading`.
    public var isLoading: Bool {
        if case .loading = asLoadingState {
            return true
        } else {
            return false
        }
    }
    
    /// Value if self is `.loaded`.
    public var value: LoadingValue? {
        if case .loaded(let value) = asLoadingState {
            return value
        } else {
            return nil
        }
    }
    
    /// Error if self is `.failed`.
    public var error: LoadingError? {
        if case .failed(let error) = asLoadingState {
            return error
        } else {
            return nil
        }
    }
}

/// Represents loading state of an asynchronous action. Element of LoadingSignal.
public enum LoadingState<LoadingValue, LoadingError: Error>: LoadingStateProtocol {
    
    /// Value is loading.
    case loading
    
    /// Value is loaded.
    case loaded(LoadingValue)
    
    /// Value loading failed with the given error.
    case failed(LoadingError)
    
    public var asLoadingState: LoadingState<LoadingValue, LoadingError> {
        return self
    }
}

/// Loading state as observed by the observer. Just like LoadingState, but with `.reloading` case.
/// To get observed loading state from a loading signal, apply `deriveObservedLoadingState()` operator.
public protocol ObservedLoadingStateProtocol: LoadingStateProtocol {
    var asObservedLoadingState: ObservedLoadingState<LoadingValue, LoadingError> { get }
}

extension ObservedLoadingStateProtocol {
    
    /// True if self is `.reloading`.
    public var isReloading: Bool {
        if case .reloading = asObservedLoadingState {
            return true
        } else {
            return false
        }
    }
}

/// Loading state as observed by the observer. Just like LoadingState, but with `.reloading` case.
/// To get observed loading state from a loading signal, apply `deriveObservedLoadingState()` operator.
public enum ObservedLoadingState<LoadingValue, LoadingError: Error>: ObservedLoadingStateProtocol {
    
    /// Value is loading.
    case loading
    
    /// Value is reloading.
    case reloading
    
    /// Value is loaded.
    case loaded(LoadingValue)
    
    /// Value loading failed with the given error.
    case failed(LoadingError)
    
    public var asLoadingState: LoadingState<LoadingValue, LoadingError> {
        switch self {
        case .loading, .reloading:
            return .loading
        case .loaded(let value):
            return .loaded(value)
        case .failed(let error):
            return .failed(error)
        }
    }
    
    public var asObservedLoadingState: ObservedLoadingState<LoadingValue, LoadingError> {
        switch self {
        case .loading:
            return .loading
        case .reloading:
            return .reloading
        case .loaded(let value):
            return .loaded(value)
        case .failed(let error):
            return .failed(error)
        }
    }
}

extension LoadingState {
    
    /// True if `other` is the same state as the receiver; Does not compare underlying value or error!
    public func isSameStateAs<V, E>(_ other: LoadingState<V, E>) -> Bool {
        switch (self, other) {
        case (.loading, .loading):
            return true
        case (.loaded, .loaded):
            return true
        case (.failed, .failed):
            return true
        default:
            return false
        }
    }
}

/// A signal with elements of LoadingState type. Used to represent loading state of a value.
public typealias LoadingSignal<LoadingValue, LoadingError: Error> = SafeSignal<LoadingState<LoadingValue, LoadingError>>

extension SignalProtocol where Element: LoadingStateProtocol, Error == Never {
    
    public typealias LoadingValue = Element.LoadingValue
    public typealias LoadingError = Element.LoadingError
    
    /// Create LoadingSignal that just emits `.loading` state.
    public static func loading() -> LoadingSignal<LoadingValue, LoadingError> {
        return Signal(just: .loading)
    }
    
    /// Create LoadingSignal that just emits the given value in `.loaded` state.
    public static func loaded(_ value: LoadingValue) -> LoadingSignal<LoadingValue, LoadingError> {
        return Signal(just: .loaded(value))
    }
    
    /// Create LoadingSignal that just emits the given error in `.failed` state.
    public static func failed(_ error: LoadingError) -> LoadingSignal<LoadingValue, LoadingError> {
        return Signal(just: .failed(error))
    }
    
    /// Convert receiver into a SafeSignal by passing values from `.loaded` events and ignoring `.loading` or `.failed` states.
    public func value() -> SafeSignal<LoadingValue> {
        return compactMap { $0.value }
    }
    
    /// Map loading value.
    public func mapValue<NewValue>(_ transform: @escaping (LoadingValue) -> NewValue) -> LoadingSignal<NewValue, LoadingError> {
        return map { (element: Element) -> LoadingState<NewValue, LoadingError> in
            switch element.asLoadingState {
            case .loading:
                return .loading
            case .loaded(let value):
                return .loaded(transform(value))
            case .failed(let error):
                return .failed(error)
            }
        }
    }
    
    /// Map loading error.
    public func mapLoadingError<NewError>(_ transform: @escaping (LoadingError) -> NewError) -> LoadingSignal<LoadingValue, NewError> {
        return map { (element: Element) -> LoadingState<LoadingValue, NewError> in
            switch element.asLoadingState {
            case .loading:
                return .loading
            case .loaded(let value):
                return .loaded(value)
            case .failed(let error):
                return .failed(transform(error))
            }
        }
    }
    
    /// Convert LoadingSignal into a regular Signal by propagating loaded values as signal elements and loading error as signal error.
    /// The signal will terminate and dispose itself if it receives a loading error!
    public func dematerializeLoadingState() -> Signal<LoadingValue, LoadingError> {
        return Signal { observer in
            return self.observe { event in
                switch event {
                case .next(let anyLoadingState):
                    switch anyLoadingState.asLoadingState {
                    case .loaded(let value):
                        observer.next(value)
                    case .failed(let error):
                        observer.failed(error)
                    case .loading:
                        break
                    }
                case .completed:
                    observer.completed()
                case .failed:
                    break // Never
                }
            }
        }
    }
    
    /// Lift loading signal values into a regular signal, apply the given transform to that singal and convert the result
    /// back into the loading signal. Enables you to use regular Signal operators on LoadingSignal. For example:
    ///
    ///     aLoadingSignal.liftValue {
    ///         $0.skip(first: 5).delay(interval: 1)
    ///     }
    ///
    public func liftValue<T>(_ transfrom: @escaping (Signal<LoadingValue, LoadingError>) -> Signal<T, LoadingError>) -> LoadingSignal<T, LoadingError> {
        return liftValue { transfrom($0).toLoadingSignal() }
    }
    
    /// Lift loading signal values into a regular signal, apply the given transform to that singal and convert the result
    /// back into the loading signal. Enables you to use regular Signal operators on LoadingSignal. For example:
    ///
    ///     aLoadingSignal.liftValue {
    ///         $0.skip(first: 1).flatMapLatest(fetch)
    ///     }
    ///
    public func liftValue<T>(_ transfrom: @escaping (Signal<LoadingValue, LoadingError>) -> LoadingSignal<T, LoadingError>) -> LoadingSignal<T, LoadingError> {
        return Signal { observer in
            let subject = PublishSubject<LoadingValue, LoadingError>()
            let d1 = transfrom(subject.toSignal()).observe(with: observer.on)
            let d2 = self.observe { event in
                switch event {
                case .next(let anyLoadingState):
                    switch anyLoadingState.asLoadingState {
                    case .loaded(let value):
                        subject.next(value)
                    case .failed(let error):
                        observer.next(.failed(error))
                    case .loading:
                        observer.next(.loading)
                    }
                case .completed:
                    subject.completed()
                case .failed:
                    break // Never
                }
            }
            return CompositeDisposable([d1, d2])
        }
    }
    
    /// Map value into a loading signal and flatten that signal.
    public func flatMapValue<NewValue>(_ strategy: FlattenStrategy = .latest, transfrom: @escaping (LoadingValue) -> LoadingSignal<NewValue, LoadingError>) -> LoadingSignal<NewValue, LoadingError> {
        
        let apply = { (anyLoadingSate: Element) -> LoadingSignal<NewValue, LoadingError> in
            switch anyLoadingSate.asLoadingState {
            case .loading:
                return .loading()
            case .loaded(let value):
                return transfrom(value)
            case .failed(let error):
                return .failed(error)
            }
        }
        
        return flatMap(strategy, apply)
    }
    
    /// Map value into a signal and flatten that signal into a loading signal.
    public func flatMapValue<NewValue>(_ strategy: FlattenStrategy = .latest, transfrom: @escaping (LoadingValue) -> Signal<NewValue, LoadingError>) -> LoadingSignal<NewValue, LoadingError> {
        return flatMapValue(strategy) { (value: LoadingValue) -> LoadingSignal<NewValue, LoadingError> in
            return transfrom(value).toLoadingSignal()
        }
    }
    
    /// Convert LoadingState into ObservedLoadingState by mapping subsequent loads into reloads.
    ///
    /// - parameter loadsAgainOnFailure: `.loading` state that follows a `.failed` state will be kept as `.loading` if `true` is passed. Otherwise it will be mapped into `.reloading`. Default is true.
    ///
    public func deriveObservedLoadingState(loadsAgainOnFailure: Bool = true) -> Signal<ObservedLoadingState<LoadingValue, LoadingError>, Never> {
        var previousLoadingState: LoadingState<LoadingValue, LoadingError>? = nil
        var hasProducedNonLoadingState = false
        return Signal { observer in
            return self.observe { event in
                switch event {
                case .next(let anyLoadingState):
                    let loadingState = anyLoadingState.asLoadingState
                    switch loadingState {
                    case .loading:
                        guard !(previousLoadingState?.isSameStateAs(loadingState) ?? false) else { break }
                        if hasProducedNonLoadingState {
                            observer.next(.reloading)
                        } else {
                            observer.next(.loading)
                        }
                    case .loaded(let value):
                        hasProducedNonLoadingState = true
                        observer.next(.loaded(value))
                    case .failed(let error):
                        hasProducedNonLoadingState = !loadsAgainOnFailure
                        observer.next(.failed(error))
                    }
                    previousLoadingState = loadingState
                case .completed:
                    observer.completed()
                case .failed:
                    break // Never
                }
            }
        }
    }
}

extension SignalProtocol {
    
    /// Convert signal into a loading signal. The signal will automatically start with `.loading` state, each element will
    /// be mapped into a `.loaded` state and the error will be mapped into a `.failed` state.
    public func toLoadingSignal() -> LoadingSignal<Element, Error> {
        return map { LoadingState.loaded($0) }.flatMapError { LoadingSignal.failed($0) }.start(with: .loading)
    }
}

/// A consumer of ObservedLoadingState. For example, a view what updates its appearance based on loading state.
public protocol LoadingStateListener: class {
    
    /// Consume observed loading state.
    func setLoadingState<LoadingValue, LoadingError>(_ state: ObservedLoadingState<LoadingValue, LoadingError>)
    
    var loadingStateListenerNeedsWeakReference: Bool { get }
}

extension LoadingStateListener {
    
    public var loadingStateListenerNeedsWeakReference: Bool {
        return true
    }
}

extension SignalProtocol where Element: ObservedLoadingStateProtocol, Error == Never {
    
    /// Update loading state of the listener on each `.next` (loading state) event.
    public func updateLoadingState(of listener: (LoadingStateListener & BindingExecutionContextProvider)) -> Signal<ObservedLoadingState<LoadingValue, LoadingError>, Never> {
        return updateLoadingState(of: listener, context: listener.bindingExecutionContext)
    }
    
    /// Update loading state of the listener on each `.next` (loading state) event.
    public func updateLoadingState(of listener: LoadingStateListener, context: ExecutionContext) -> Signal<ObservedLoadingState<LoadingValue, LoadingError>, Never> {
        
        let _observe = { (listener: LoadingStateListener?, event: Event<Element, Error>, observer: AtomicObserver<ObservedLoadingState<LoadingValue, LoadingError>, Never>) in
            switch event {
            case .next(let anyObservedLoadingState):
                let observedLoadingState = anyObservedLoadingState.asObservedLoadingState
                if let listener = listener {
                    context.execute {
                        listener.setLoadingState(observedLoadingState)
                    }
                }
                observer.next(observedLoadingState)
            case .completed:
                observer.completed()
            }
        }
        
        if listener.loadingStateListenerNeedsWeakReference {
            return Signal { [weak listener] observer in
                return self.observe { [weak listener] event in
                    _observe(listener, event, observer)
                }
            }
        } else {
            return Signal { observer in
                return self.observe { event in
                    _observe(listener, event, observer)
                }
            }
        }
    }
    
    /// Consume loading state by the listener and return SafeSignal of loaded values.
    public func consumeLoadingState(by listener: (LoadingStateListener & BindingExecutionContextProvider)) -> SafeSignal<LoadingValue> {
        return updateLoadingState(of: listener, context: listener.bindingExecutionContext).value()
    }
    
    /// Consume loading state by the listener and return SafeSignal of loaded values.
    public func consumeLoadingState(by listener: LoadingStateListener, context: ExecutionContext) -> SafeSignal<LoadingValue> {
        return updateLoadingState(of: listener, context: context).value()
    }
}

extension SignalProtocol where Element: LoadingStateProtocol, Error == Never {
    
    /// Update loading state of the listener on each `.next` (loading state) event.
    public func updateLoadingState(of listener: (LoadingStateListener & BindingExecutionContextProvider)) -> LoadingSignal<LoadingValue, LoadingError> {
        return deriveObservedLoadingState().updateLoadingState(of: listener).map { $0.asLoadingState }
    }
    
    /// Update loading state of the listener on each `.next` (loading state) event.
    public func updateLoadingState(of listener: LoadingStateListener, context: ExecutionContext) -> LoadingSignal<LoadingValue, LoadingError> {
        return deriveObservedLoadingState().updateLoadingState(of: listener, context: context).map { $0.asLoadingState }
    }
    
    /// Consume loading state by the listener and return SafeSignal of loaded values.
    public func consumeLoadingState(by listener: (LoadingStateListener & BindingExecutionContextProvider)) -> SafeSignal<LoadingValue> {
        return deriveObservedLoadingState().consumeLoadingState(by: listener)
    }
    
    /// Consume loading state by the listener and return SafeSignal of loaded values.
    public func consumeLoadingState(by listener: LoadingStateListener, context: ExecutionContext) -> SafeSignal<LoadingValue> {
        return deriveObservedLoadingState().consumeLoadingState(by: listener, context: context)
    }
}
