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
#if os(Linux)
  import Glibc
#else
  import Dispatch
#endif

/// Represents a context that can execute given block.
public typealias ExecutionContext = (@escaping () -> Void) -> Void

/// Execute block on current thread or queue.
public let ImmediateExecutionContext: ExecutionContext = { block in
  block()
}

#if os(Linux)

  /// If current thread is main thread, just execute block. Otherwise, do
  /// async dispatch of the block to the main queue (thread).
  public let ImmediateOnMainExecutionContext: ExecutionContext = { block in
    block() // TODO
  }

  public struct Queue {

    public init() {
    }

    public init(name: String) {
    }

    public func after(_ interval: TimeValue, block: () -> ()) {
      block()
    }

    public func after(_ interval: TimeValue) -> (() -> Void) -> Void {
      return { block in
        block()
      }
    }

    public func disposableAfter(_ interval: TimeValue, block: () -> ()) -> Disposable {
      block()
      return NotDisposable
    }

    public func async(_ block: () -> ()) {
      block()
    }

    public func sync(_ block: () -> ()) {
      block()
    }

    public func sync<T>(_ block: () -> T) -> T {
      return block()
    }
  }

#else

  /// If current thread is main thread, just execute block. Otherwise, do
  /// async dispatch of the block to the main queue (thread).
  public let ImmediateOnMainExecutionContext: ExecutionContext = { block in
    if Thread.isMainThread {
      block()
    } else {
      DispatchQueue.main.async(execute: block)
    }
  }

  public extension DispatchQueue {

    public func after(when interval: TimeValue, block: @escaping () -> ()) {
      asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(Int(interval)), execute: block)
    }

    public func disposableAfter(when interval: TimeValue, block: @escaping () -> ()) -> Disposable {
      let disposable = SimpleDisposable()
      after(when: interval) {
        if !disposable.isDisposed {
          block()
        }
      }
      return disposable
    }
  }

  /// A simple wrapper over GCD queue.
//  public struct Queue {
//
//    public static let main = Queue(queue: DispatchQueue.main)
//    public static let global = Queue(queue: DispatchQueue.global())
//    public static let background = Queue(queue: DispatchQueue.global(attributes: DispatchQueue.GlobalAttributes.qosBackground))
//
//    public private(set) var queue: DispatchQueue
//
//    public init(queue: DispatchQueue = dispatch_queue_create("ReactiveKit.Queue", DISPATCH_QUEUE_SERIAL)) {
//      self.queue = queue
//    }
//
//    public init(name: String) {
//      self.queue = dispatch_queue_create(name, DISPATCH_QUEUE_SERIAL)
//    }
//
//    public func after(_ interval: TimeValue, block: () -> ()) {
//      let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(interval * NSTimeInterval(NSEC_PER_SEC)))
//      dispatch_after(dispatchTime, queue, block)
//    }
//
//    public func after(_ interval: TimeValue) -> (() -> Void) -> Void {
//      return { block in
//        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(interval * NSTimeInterval(NSEC_PER_SEC)))
//        dispatch_after(dispatchTime, self.queue, block)
//      }
//    }
//
//    public func disposableAfter(_ interval: TimeValue, block: () -> ()) -> Disposable {
//      let disposable = SimpleDisposable()
//      let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(interval * NSTimeInterval(NSEC_PER_SEC)))
//      dispatch_after(dispatchTime, queue) {
//        if !disposable.isDisposed {
//          block()
//        }
//      }
//      return disposable
//    }
//
//    public func async(_ block: () -> ()) {
//      dispatch_async(queue, block)
//    }
//
//    public func sync(_ block: () -> ()) {
//      dispatch_sync(queue, block)
//    }
//
//    public func sync<T>(_ block: () -> T) -> T {
//      var res: T! = nil
//      sync {
//        res = block()
//      }
//      return res
//    }
//  }

#endif

public extension DispatchQueue {

  /// Returns context that executes blocks on this queue.
  public var context: ExecutionContext {
    return { block in // TODO: remove redundant closure
      self.async(execute: block)
    }
  }
}

internal protocol Lock {
  func lock()
  func unlock()
  func atomic<T>(body: () -> T) -> T
}

internal extension Lock {
  func atomic<T>(body: () -> T) -> T {
    lock(); defer { unlock() }
    return body()
  }
}

/// Recursive Lock
extension NSRecursiveLock: Lock {

  internal convenience init(name: String) {
    self.init()
    self.name = name
  }
}

#if os(Linux)

  /// Spin Lock
  internal final class SpinLock: NSRecursiveLock, Lock {
    // TODO
  }

#else

  /// Spin Lock
  internal final class SpinLock: Lock {
    private var spinLock = OS_SPINLOCK_INIT
    
    internal func lock() {
      OSSpinLockLock(&spinLock)
    }
    
    internal func unlock() {
      OSSpinLockUnlock(&spinLock)
    }
  }
  
#endif
