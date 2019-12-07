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

/// A disposable is an object that can be used to cancel a signal observation.
///
/// Disposables are returned by `observe*` and `bind*` methods.
///
///     let disposable = signal.observe { ... }
///
/// Disposing the disposable cancels the observation. A signal is guaranteed not to
/// fire any event after is has been disposed.
///
///     disposable.dispose()
public protocol Disposable {
    
    /// Dispose the signal observation or binding.
    func dispose()
    
    /// Returns `true` is already disposed.
    var isDisposed: Bool { get }
}

/// A disposable that cannot be disposed.
public struct NonDisposable: Disposable {
    
    public static let instance = NonDisposable()
    
    private init() {}
    
    public func dispose() {}
    
    public var isDisposed: Bool {
        return false
    }
}

/// A disposable that just encapsulates disposed state.
public final class SimpleDisposable: Disposable {

    private let lock = NSRecursiveLock(name: "com.reactive_kit.simple_disposable")
    private var _isDisposed: Bool

    public var isDisposed: Bool {
        get {
            lock.lock(); defer { lock.unlock() }
            return _isDisposed
        }
        set {
            lock.lock(); defer { lock.unlock() }
            _isDisposed = newValue
        }
    }
    
    public func dispose() {
        lock.lock(); defer { lock.unlock() }
        _isDisposed = true
    }
    
    public init(isDisposed: Bool = false) {
        self._isDisposed = isDisposed
    }
}

/// A disposable that executes the given block upon disposing.
public final class BlockDisposable: Disposable {

    private let lock = NSRecursiveLock(name: "com.reactive_kit.block_disposable")
    private var handler: (() -> ())?

    public var isDisposed: Bool {
        lock.lock(); defer { lock.unlock() }
        return handler == nil
    }

    public init(_ handler: @escaping () -> ()) {
        self.handler = handler
    }
    
    public func dispose() {
        lock.lock()
        guard let handler = handler else {
            lock.unlock()
            return
        }
        self.handler = nil
        lock.unlock()
        handler()
    }
}

/// A disposable that disposes itself upon deallocation.
public final class DeinitDisposable: Disposable {

    private let lock = NSRecursiveLock(name: "com.reactive_kit.deinit_disposable")
    private var _otherDisposable: Disposable?

    public var otherDisposable: Disposable? {
        set {
            lock.lock(); defer { lock.unlock() }
            _otherDisposable = newValue
        }
        get {
            lock.lock(); defer { lock.unlock() }
            return _otherDisposable
        }
    }
    
    public var isDisposed: Bool {
        lock.lock(); defer { lock.unlock() }
        return _otherDisposable == nil
    }
    
    public init(disposable: Disposable) {
        _otherDisposable = disposable
    }
    
    public func dispose() {
        lock.lock()
        guard let otherDisposable = _otherDisposable else {
            lock.unlock()
            return
        }
        _otherDisposable = nil
        lock.unlock()
        otherDisposable.dispose()
    }
    
    deinit {
        dispose()
    }
}

/// A disposable that disposes a collection of disposables upon its own disposing.
public final class CompositeDisposable: Disposable {

    private let lock = NSRecursiveLock(name: "com.reactive_kit.composite_disposable")
    private var disposables: [Disposable]?

    public var isDisposed: Bool {
        lock.lock(); defer { lock.unlock() }
        return disposables == nil
    }

    public init() {
        self.disposables = []
    }
    
    public init(_ disposables: [Disposable]) {
        self.disposables = disposables
    }
    
    public func add(disposable: Disposable) {
        lock.lock(); defer { lock.unlock() }
        if disposables == nil {
            disposable.dispose()
        } else {
            disposables = disposables.map { $0 + [disposable] }
        }
    }
    
    public static func += (left: CompositeDisposable, right: Disposable) {
        left.add(disposable: right)
    }
    
    public func dispose() {
        lock.lock()
        guard let disposables = disposables else {
            lock.unlock()
            return
        }
        self.disposables = nil
        lock.unlock()
        disposables.forEach { $0.dispose() }
    }
}

/// A disposable that disposes other disposable upon its own disposing.
public final class SerialDisposable: Disposable {

    private let lock = NSRecursiveLock(name: "com.reactive_kit.serial_disposable")
    private var _isDisposed = false

    public var isDisposed: Bool {
        lock.lock(); defer { lock.unlock() }
        return _isDisposed
    }
    
    /// Will dispose other disposable immediately if self is already disposed.
    public var otherDisposable: Disposable? {
        didSet {
            lock.lock()
            if _isDisposed {
                let otherDisposable = self.otherDisposable
                lock.unlock()
                otherDisposable?.dispose()
            } else {
                lock.unlock()
            }
        }
    }
    
    public init(otherDisposable: Disposable?) {
        self.otherDisposable = otherDisposable
    }
    
    public func dispose() {
        lock.lock()
        if !_isDisposed {
            _isDisposed = true
            let otherDisposable = self.otherDisposable
            lock.unlock()
            otherDisposable?.dispose()
        } else {
            lock.unlock()
        }
    }
}

/// A container of disposables that will dispose the disposables upon deinit.
/// A bag is a prefered way to handle disposables:
///
///     let bag = DisposeBag()
///
///     signal
///       .observe { ... }
///       .dispose(in: bag)
///
/// When bag gets deallocated, it will dispose all disposables it contains.
public protocol DisposeBagProtocol: Disposable {
    func add(disposable: Disposable)
}

/// A container of disposables that will dispose the disposables upon deinit.
/// A bag is a prefered way to handle disposables:
///
///     let bag = DisposeBag()
///
///     signal
///       .observe { ... }
///       .dispose(in: bag)
///
/// When bag gets deallocated, it will dispose all disposables it contains.
public final class DisposeBag: DisposeBagProtocol {

    private let lockDisposables = NSRecursiveLock(name: "com.reactive_kit.dispose_bag.lock_disposables")
    private let lockSubject = NSRecursiveLock(name: "com.reactive_kit.dispose_bag.lock_subject")

    private var disposables: [Disposable] = []
    private var subject: ReplayOneSubject<Void, Never>? = nil

    /// `true` if bag is empty, `false` otherwise.
    public var isDisposed: Bool {
        lockDisposables.lock(); defer { lockDisposables.unlock() }
        return disposables.count == 0
    }
    
    public init() {
    }
    
    /// Add the given disposable to the bag.
    /// Disposable will be disposed when the bag is deallocated.
    public func add(disposable: Disposable) {
        lockDisposables.lock(); defer { lockDisposables.unlock() }
        disposables.append(disposable)
    }
    
    /// Add the given disposables to the bag.
    /// Disposables will be disposed when the bag is deallocated.
    public func add(disposables: [Disposable]) {
        lockDisposables.lock(); defer { lockDisposables.unlock() }
        self.disposables.append(contentsOf: disposables)
    }
    
    /// Add a disposable to a dispose bag.
    public static func += (left: DisposeBag, right: Disposable) {
        left.add(disposable: right)
    }
    
    /// Add multiple disposables to a dispose bag.
    public static func += (left: DisposeBag, right: [Disposable]) {
        left.add(disposables: right)
    }
    
    /// Disposes all disposables that are currenty in the bag.
    public func dispose() {
        lockDisposables.lock()
        let disposables = self.disposables
        self.disposables.removeAll()
        lockDisposables.unlock()
        disposables.forEach { $0.dispose() }
    }
    
    /// A signal that fires `completed` event when the bag gets deallocated.
    public var deallocated: SafeSignal<Void> {
        lockSubject.lock(); defer { lockSubject.unlock() }
        if subject == nil {
            subject = ReplayOneSubject()
        }
        return subject!.toSignal()
    }
    
    deinit {
        dispose()
        subject?.send(completion: .finished)
    }
}

/// A type-erasing cancellable object that executes a provided closure when canceled (disposed).
/// The closure will be executed upon deinit if it has not been executed already.
public final class AnyCancellable: Disposable {

    private let lock = NSRecursiveLock(name: "com.reactive_kit.any_cancellable")
    private var handler: (() -> ())?

    public var isDisposed: Bool {
        lock.lock(); defer { lock.unlock() }
        return handler == nil
    }


    public init(_ handler: @escaping () -> ()) {
        self.handler = handler
    }

    deinit {
        dispose()
    }

    public func dispose() {
        lock.lock()
        guard let handler = handler else {
            lock.unlock()
            return
        }
        self.handler = nil
        lock.unlock()
        handler()
    }

    public func cancel() {
        dispose()
    }
}

extension AnyCancellable: Hashable {
  public static func == (lhs: AnyCancellable, rhs: AnyCancellable) -> Bool {
    return lhs === rhs
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
  }
}

extension AnyCancellable {

    public convenience init(_ disposable: Disposable) {
        self.init(disposable.dispose)
    }

    final public func store<C>(in collection: inout C) where C: RangeReplaceableCollection, C.Element == AnyCancellable {
        collection.append(self)
    }

    final public func store(in set: inout Set<AnyCancellable>) {
        set.insert(self)
    }
}

extension Disposable {
    
    /// Put the disposable in the given bag. Disposable will be disposed when
    /// the bag is either deallocated or disposed.
    public func dispose(in disposeBag: DisposeBagProtocol) {
        disposeBag.add(disposable: self)
    }
}
