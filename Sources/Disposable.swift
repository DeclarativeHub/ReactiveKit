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
  public private(set) var isDisposed: Bool = false

  public func dispose() {
    isDisposed = true
  }

  public init(isDisposed: Bool = false) {
    self.isDisposed = isDisposed
  }
}

/// A disposable that executes the given block upon disposing.
public final class BlockDisposable: Disposable {

  public var isDisposed: Bool {
    return handler == nil
  }

  private var handler: (() -> ())?
  private let lock = NSRecursiveLock(name: "com.reactivekit.blockdisposable")

  public init(_ handler: @escaping () -> ()) {
    self.handler = handler
  }

  public func dispose() {
    lock.lock(); defer { lock.unlock() }
    handler?()
    handler = nil
  }
}

/// A disposable that disposes itself upon deallocation.
public final class DeinitDisposable: Disposable {

  public var otherDisposable: Disposable? = nil

  public var isDisposed: Bool {
    return otherDisposable == nil
  }

  public init(disposable: Disposable) {
    otherDisposable = disposable
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

  public private(set) var isDisposed: Bool = false
  private var disposables: [Disposable] = []
  private let lock = NSRecursiveLock(name: "com.reactivekit.compositedisposable")

  public convenience init() {
    self.init([])
  }

  public init(_ disposables: [Disposable]) {
    self.disposables = disposables
  }

  public func add(disposable: Disposable) {
    lock.lock(); defer { lock.unlock() }
    if isDisposed {
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
    isDisposed = true
    disposables.forEach { $0.dispose() }
    disposables.removeAll()
  }
}

/// A disposable that disposes other disposable upon its own disposing.
public final class SerialDisposable: Disposable {

  public private(set) var isDisposed: Bool = false
  private let lock = NSRecursiveLock(name: "com.reactivekit.serialdisposable")

  /// Will dispose other disposable immediately if self is already disposed.
  public var otherDisposable: Disposable? {
    didSet {
      lock.lock(); defer { lock.unlock() }
      if isDisposed {
        otherDisposable?.dispose()
      }
    }
  }

  public init(otherDisposable: Disposable?) {
    self.otherDisposable = otherDisposable
  }

  public func dispose() {
    lock.lock(); defer { lock.unlock() }
    if !isDisposed {
      isDisposed = true
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

  private var disposables: [Disposable] = []
  private var subject: ReplayOneSubject<Void, NoError>?
  private lazy var lock = NSRecursiveLock(name: "com.reactivekit.disposebag")

  /// `true` if bag is empty, `false` otherwise.
  public var isDisposed: Bool {
    return disposables.count == 0
  }

  public init() {
  }

  /// Add the given disposable to the bag.
  /// Disposable will be disposed when the bag is deallocated.
  public func add(disposable: Disposable) {
    disposables.append(disposable)
  }

  /// Add a disposable to a dispose bag.
  public static func += (left: DisposeBag, right: Disposable) {
    left.add(disposable: right)
  }

  /// Disposes all disposables that are currenty in the bag.
  public func dispose() {
    disposables.forEach { $0.dispose() }
    disposables.removeAll()
  }

  /// A signal that fires `completed` event when the bag gets deallocated.
  public var deallocated: SafeSignal<Void> {
    lock.lock()
    if subject == nil {
      subject = ReplayOneSubject()
    }
    lock.unlock()
    return subject!.toSignal()
  }

  deinit {
    dispose()
    subject?.completed()
  }
}

public extension Disposable {

  /// Put the disposable in the given bag. Disposable will be disposed when
  /// the bag is either deallocated or disposed.
  public func dispose(in disposeBag: DisposeBagProtocol) {
    disposeBag.add(disposable: self)
  }
}
