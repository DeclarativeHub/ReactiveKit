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

    private var _isDisposed = false
    public var isDisposed: Bool {
        lock.lock(); defer { lock.unlock() }
        return _isDisposed
    }
    
    public func dispose() {
        lock.lock(); defer { lock.unlock() }
        _isDisposed = true
    }
    
    public init(isDisposed: Bool = false) {
        _isDisposed = isDisposed
    }
}

/// A disposable that executes the given block upon disposing.
public final class BlockDisposable: Disposable {

    private let lock = NSRecursiveLock(name: "com.reactive_kit.block_disposable")

    public var isDisposed: Bool {
        lock.lock(); defer { lock.unlock() }
        return _handler == nil
    }
    
    private var _handler: (() -> ())?
    
    public init(_ handler: @escaping () -> ()) {
        _handler = handler
    }
    
    public func dispose() {
        lock.lock(); defer { lock.unlock() }
        if let handler = _handler {
            _handler = nil
            handler()
        }
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
        return otherDisposable == nil
    }
    
    public init(disposable: Disposable) {
        _otherDisposable = disposable
    }
    
    public func dispose() {
        otherDisposable?.dispose()
    }
    
    deinit {
        dispose()
    }
}

/// A disposable that disposes a collection of disposables upon its own disposing.
public final class CompositeDisposable: Disposable {
    
    private let lock = NSRecursiveLock(name: "com.reactive_kit.composite_disposable")
    
    private var _isDisposed = false
    public var isDisposed: Bool {
        lock.lock(); defer { lock.unlock() }
        return _isDisposed
    }
    
    private var disposables: [Disposable] = []
    
    public convenience init() {
        self.init([])
    }
    
    public init(_ disposables: [Disposable]) {
        self.disposables = disposables
    }
    
    public func add(disposable: Disposable) {
        lock.lock(); defer { lock.unlock() }
        if _isDisposed {
            disposable.dispose()
        } else {
            disposables.append(disposable)
            self.disposables = disposables.filter { $0.isDisposed == false }
        }
    }
    
    public static func += (left: CompositeDisposable, right: Disposable) {
        left.add(disposable: right)
    }
    
    public func dispose() {
        lock.lock(); defer { lock.unlock() }
        _isDisposed = true
        disposables.forEach { $0.dispose() }
        disposables.removeAll()
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
            lock.lock(); defer { lock.unlock() }
            if _isDisposed {
                otherDisposable?.dispose()
            }
        }
    }
    
    public init(otherDisposable: Disposable?) {
        self.otherDisposable = otherDisposable
    }
    
    public func dispose() {
        lock.lock(); defer { lock.unlock() }
        if !_isDisposed {
            _isDisposed = true
            otherDisposable?.dispose()
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

    private let disposablesLock = NSRecursiveLock(name: "com.reactive_kit.dispose_bag.disposables")
    private let subjectLock = NSRecursiveLock(name: "com.reactive_kit.dispose_bag.subject")

    private var _disposables: [Disposable] = []

    private var _subject: ReplayOneSubject<Void, Never>?
    private var subject: ReplayOneSubject<Void, Never>? {
        subjectLock.lock(); defer { subjectLock.unlock() }
        return _subject
    }

    /// `true` if bag is empty, `false` otherwise.
    public var isDisposed: Bool {
        disposablesLock.lock(); defer { disposablesLock.unlock() }
        return _disposables.count == 0
    }
    
    public init() {
    }
    
    /// Add the given disposable to the bag.
    /// Disposable will be disposed when the bag is deallocated.
    public func add(disposable: Disposable) {
        disposablesLock.lock(); defer { disposablesLock.unlock() }
        _disposables.append(disposable)
    }
    
    /// Add the given disposables to the bag.
    /// Disposables will be disposed when the bag is deallocated.
    public func add(disposables: [Disposable]) {
        disposablesLock.lock(); defer { disposablesLock.unlock() }
        _disposables.forEach(add)
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
        disposablesLock.lock(); defer { disposablesLock.unlock() }
        _disposables.forEach { $0.dispose() }
        _disposables.removeAll()
    }
    
    /// A signal that fires `completed` event when the bag gets deallocated.
    public var deallocated: SafeSignal<Void> {
        subjectLock.lock(); defer { subjectLock.unlock() }
        if _subject == nil {
            _subject = ReplayOneSubject()
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

    public var isDisposed: Bool {
        lock.lock(); defer { lock.unlock() }
        return _handler == nil
    }

    private var _handler: (() -> ())?

    public init(_ handler: @escaping () -> ()) {
        _handler = handler
    }

    deinit {
        dispose()
    }

    public func dispose() {
        lock.lock(); defer { lock.unlock() }
        if let handler = _handler {
            _handler = nil
            handler()
        }
    }

    public func cancel() {
        dispose()
    }
}

extension Disposable {
    
    /// Put the disposable in the given bag. Disposable will be disposed when
    /// the bag is either deallocated or disposed.
    public func dispose(in disposeBag: DisposeBagProtocol) {
        disposeBag.add(disposable: self)
    }
}
