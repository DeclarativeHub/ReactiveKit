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

/// A property that lazily loads its value using the given signal producer closure.
/// The value will be loaded when the property is observed for the first time.
public class LoadingProperty<LoadingValue, LoadingError: Swift.Error>: PropertyProtocol, SignalProtocol, DisposeBagProvider {

  private let signalProducer: () -> LoadingSignal<LoadingValue, LoadingError>
  private let subject = PublishSubject<LoadingState<LoadingValue, LoadingError>, NoError>()
  private var loadingDisposable: Disposable? = nil

  public var bag: DisposeBag {
    return subject.disposeBag
  }

  /// Current state of the property. In `.loading` state until the value is loaded.
  /// When the property is observed for the first time, the value will be loaded and
  /// the state will be updated to either `.loaded` or `.failed` state.
  public private(set) var loadingState: LoadingState<LoadingValue, LoadingError> = .loading {
    didSet {
      subject.next(loadingState)
    }
  }

  /// Underlying value. `nil` if not yet loaded or if the property is in error state.
  public var value: LoadingValue? {
    get {
      return loadingState.value
    }
    set {
      loadingState = value.flatMap { .loaded($0) } ?? .loading
    }
  }

  /// Create a loading property with the given signal producer closure.
  /// The closure will be executed when the propery is observed for the first time.
  public init(_ signalProducer: @escaping () -> LoadingSignal<LoadingValue, LoadingError>) {
    self.signalProducer = signalProducer
  }

  /// Create a signal that when observed reloads the property.
  /// - parameter silently: When `true` (default), do not transition property to loading or failed states during reload.
  public func reload(silently: Bool = true) -> LoadingSignal<LoadingValue, LoadingError> {
    return load(silently: silently)
  }

  private func load(silently: Bool) -> LoadingSignal<LoadingValue, LoadingError> {
    return LoadingSignal { observer in
      if !silently {
        self.loadingState = .loading
      }
      observer.next(.loading)
      self.loadingDisposable = self.signalProducer().observe { event in
        switch event {
        case .next(let anyLoadingState):
          let loadingSate = anyLoadingState.asLoadingState
          switch loadingSate {
          case .loading:
            break
          case .loaded:
            self.loadingState = loadingSate
          case .failed:
            if !silently {
              self.loadingState = loadingSate
            }
          }
          observer.next(loadingSate)
        case .completed:
          observer.completed()
        case .failed:
          break // NoError
        }
      }

      return BlockDisposable {
        self.loadingDisposable?.dispose()
        self.loadingDisposable = nil
      }
    }
  }

  public func observe(with observer: @escaping (Event<LoadingState<LoadingValue, LoadingError>, NoError>) -> Void) -> Disposable {
    if case .loading = loadingState, loadingDisposable == nil {
      loadingDisposable = load(silently: false).observeCompleted { [weak self] in
        self?.loadingDisposable = nil
      }
    }
    return subject.start(with: loadingState).observe(with: observer)
  }
}

extension SignalProtocol {

  /// Pauses the propagation of the receiver's elements until the given property is reloaded.
  public func reloading<LoadingValue>(_ property: LoadingProperty<LoadingValue, Error>) -> Signal<Element, Error> {
    return flatMapLatest { (element: Element) -> Signal<Element, Error> in
      return property.reload().dematerializeLoadingState().map { _ in element }
    }
  }
}

extension SignalProtocol where Element: LoadingStateProtocol, Error == NoError {

  /// Pauses the propagation of the receiver's loading values until the given property is reloaded.
  public func reloading<V>(_ property: LoadingProperty<V, LoadingError>, strategy: FlattenStrategy = .latest) -> LoadingSignal<LoadingValue, LoadingError> {
    return flatMapValue { (value: LoadingValue) -> LoadingSignal<LoadingValue, LoadingError> in
      return property.reload().mapValue { _ in value }
    }
  }
}
