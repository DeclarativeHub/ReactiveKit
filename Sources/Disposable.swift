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

    private var _isDisposed = Atomic(false)

    public var isDisposed: Bool {
        return _isDisposed.value
    }
    
    public func dispose() {
        _isDisposed.value = true
    }
    
    public init(isDisposed: Bool = false) {
        _isDisposed.value = isDisposed
    }
}

/// A disposable that executes the given block upon disposing.
public final class BlockDisposable: Disposable {

    public var isDisposed: Bool {
        return _handler.value == nil
    }
    
    private var _handler: Atomic<(() -> ())?>
    
    public init(_ handler: @escaping () -> ()) {
        _handler = Atomic(handler)
    }
    
    public func dispose() {
        _handler.readAndMutate { _ in nil }?()
    }
}

/// A disposable that disposes itself upon deallocation.
public final class DeinitDisposable: Disposable {

    private var _otherDisposable: Atomic<Disposable?>

    public var otherDisposable: Disposable? {
        set {
            _otherDisposable.value = newValue
        }
        get {
            return _otherDisposable.value
        }
    }
    
    public var isDisposed: Bool {
        return _otherDisposable.value == nil
    }
    
    public init(disposable: Disposable) {
        _otherDisposable = Atomic(disposable)
    }
    
    public func dispose() {
        _otherDisposable.value?.dispose()
    }
    
    deinit {
        dispose()
    }
}

/// A disposable that disposes a collection of disposables upon its own disposing.
public final class CompositeDisposable: Disposable {

    public var isDisposed: Bool {
        return disposables.value == nil
    }
    
    private var disposables: Atomic<[Disposable]?>
    
    public init() {
        self.disposables = Atomic([])
    }
    
    public init(_ disposables: [Disposable]) {
        self.disposables = Atomic(disposables)
    }
    
    public func add(disposable: Disposable) {
        if isDisposed {
            disposable.dispose()
        } else {
            disposables.mutate {
                ($0.map { $0 + [disposable] })?.filter { $0.isDisposed == false }
            }
        }
    }
    
    public static func += (left: CompositeDisposable, right: Disposable) {
        left.add(disposable: right)
    }
    
    public func dispose() {
        disposables.readAndMutate { _ in [] }?.forEach { $0.dispose() }
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

    private var _disposables: Atomic<[Disposable]> = Atomic([])
    private var _subject = Atomic<ReplayOneSubject<Void, Never>?>(nil)

    /// `true` if bag is empty, `false` otherwise.
    public var isDisposed: Bool {
        return _disposables.value.count == 0
    }
    
    public init() {
    }
    
    /// Add the given disposable to the bag.
    /// Disposable will be disposed when the bag is deallocated.
    public func add(disposable: Disposable) {
        _disposables.mutate { $0 + [disposable] }
    }
    
    /// Add the given disposables to the bag.
    /// Disposables will be disposed when the bag is deallocated.
    public func add(disposables: [Disposable]) {
        _disposables.mutate { $0 + disposables }
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
        _disposables.readAndMutate { _ in [] }.forEach {
            $0.dispose()
        }
    }
    
    /// A signal that fires `completed` event when the bag gets deallocated.
    public var deallocated: SafeSignal<Void> {
        return _subject.mutateAndRead { $0 ?? ReplayOneSubject() }!.toSignal()
    }
    
    deinit {
        dispose()
        _subject.value?.send(completion: .finished)
    }
}

/// A type-erasing cancellable object that executes a provided closure when canceled (disposed).
/// The closure will be executed upon deinit if it has not been executed already.
public final class AnyCancellable: Disposable {

    public var isDisposed: Bool {
        return _handler.value == nil
    }

    private var _handler: Atomic<(() -> ())?>

    public init(_ handler: @escaping () -> ()) {
        _handler = Atomic(handler)
    }

    deinit {
        dispose()
    }

    public func dispose() {
        _handler.readAndMutate { _ in nil }?()
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
