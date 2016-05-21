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

/// Objects conforming to this protocol dispose (cancel) streams and operations.
public protocol Disposable {

  /// Dispose the stream or operation.
  func dispose()

  /// Returns `true` is already disposed.
  var isDisposed: Bool { get }
}

/// A disposable that cannot be disposed.
private struct _NotDisposable: Disposable {

  private init() {}

  private func dispose() {
  }

  private var isDisposed: Bool {
    return false
  }
}

public let NotDisposable: Disposable = _NotDisposable()

/// A disposable that just encapsulates disposed state.
public final class SimpleDisposable: Disposable {
  public private(set) var isDisposed: Bool = false

  public func dispose() {
    isDisposed = true
  }

  public init() {}
}

/// A disposable that executes the given block upon disposing.
public final class BlockDisposable: Disposable {

  public var isDisposed: Bool {
    return handler == nil
  }

  private var handler: (() -> ())?
  private let lock = RecursiveLock(name: "ReactiveKit.BlockDisposable")

  public init(_ handler: () -> ()) {
    self.handler = handler
  }

  public func dispose() {
    lock.atomic {
      handler?()
      handler = nil
    }
  }
}

/// A disposable that disposes itself upon deallocation.
public class DeinitDisposable: Disposable {

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
    otherDisposable?.dispose()
  }
}

/// A disposable that disposes a collection of disposables upon disposing.
public final class CompositeDisposable: Disposable {

  public private(set) var isDisposed: Bool = false
  private var disposables: [Disposable] = []
  private let lock = RecursiveLock(name: "ReactiveKit.CompositeDisposable")

  public convenience init() {
    self.init([])
  }

  public init(_ disposables: [Disposable]) {
    self.disposables = disposables
  }

  public func addDisposable(disposable: Disposable) {
    lock.atomic {
      if isDisposed {
        disposable.dispose()
      } else {
        disposables.append(disposable)
        self.disposables = disposables.filter { $0.isDisposed == false }
      }
    }
  }

  public func dispose() {
    lock.atomic {
      isDisposed = true
      disposables.forEach { $0.dispose() }
      disposables.removeAll()
    }
  }
}

public func += (left: CompositeDisposable, right: Disposable) {
  left.addDisposable(right)
}

/// A disposable container that will dispose a collection of disposables upon deinit.
public final class DisposeBag: Disposable {
  private var disposables: [Disposable] = []

  /// This will return true whenever the bag is empty.
  public var isDisposed: Bool {
    return disposables.count == 0
  }

  public init() {
  }

  /// Adds the given disposable to the bag.
  /// Disposable will be disposed when the bag is deinitialized.
  public func addDisposable(disposable: Disposable) {
    disposables.append(disposable)
  }

  /// Disposes all disposables that are currenty in the bag.
  public func dispose() {
    disposables.forEach { $0.dispose() }
    disposables.removeAll()
  }

  deinit {
    dispose()
  }
}

public extension Disposable {
  public func disposeIn(disposeBag: DisposeBag) {
    disposeBag.addDisposable(self)
  }
}

/// A disposable that disposes other disposable.
public final class SerialDisposable: Disposable {

  public private(set) var isDisposed: Bool = false
  private let lock = RecursiveLock(name: "ReactiveKit.SerialDisposable")

  /// Will dispose other disposable immediately if self is already disposed.
  public var otherDisposable: Disposable? {
    didSet {
      lock.atomic {
        if isDisposed {
          otherDisposable?.dispose()
        }
      }
    }
  }

  public init(otherDisposable: Disposable?) {
    self.otherDisposable = otherDisposable
  }

  public func dispose() {
    lock.atomic {
      if !isDisposed {
        isDisposed = true
        otherDisposable?.dispose()
      }
    }
  }
}

/// A type that provides dispose bag.
public protocol DisposeBagProvider: class {
  var disposeBag: DisposeBag { get }
}
