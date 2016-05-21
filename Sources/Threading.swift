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

import Dispatch
import Foundation

/// Represents a context that can execute given block.
public typealias ExecutionContext = (() -> Void) -> Void

/// Execute block on current thread or queue.
public let ImmediateExecutionContext: ExecutionContext = { block in
  block()
}

/// If current thread is main thread, just execute block. Otherwise, do
/// async dispatch of the block to the main queue (thread).
public let ImmediateOnMainExecutionContext: ExecutionContext = { block in
  if NSThread.isMainThread() {
    block()
  } else {
    Queue.main.async(block)
  }
}

/// A simple wrapper over GCD queue.
public struct Queue {

  public static let main = Queue(queue: dispatch_get_main_queue());
  public static let global = Queue(queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
  public static let background = Queue(queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0))
  
  public private(set) var queue: dispatch_queue_t
  
  public init(queue: dispatch_queue_t = dispatch_queue_create("ReactiveKit.Queue", DISPATCH_QUEUE_SERIAL)) {
    self.queue = queue
  }
  
  public init(name: String) {
    self.queue = dispatch_queue_create(name, DISPATCH_QUEUE_SERIAL)
  }
  
  public func after(interval: TimeValue, block: () -> ()) {
    let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(interval * NSTimeInterval(NSEC_PER_SEC)))
    dispatch_after(dispatchTime, queue, block)
  }

  public func after(interval: TimeValue) -> (() -> Void) -> Void {
    return { block in
      let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(interval * NSTimeInterval(NSEC_PER_SEC)))
      dispatch_after(dispatchTime, self.queue, block)
    }
  }

  public func disposableAfter(interval: TimeValue, block: () -> ()) -> Disposable {
    let disposable = SimpleDisposable()
    let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(interval * NSTimeInterval(NSEC_PER_SEC)))
    dispatch_after(dispatchTime, queue) {
      if !disposable.isDisposed {
        block()
      }
    }
    return disposable
  }

  public func async(block: () -> ()) {
    dispatch_async(queue, block)
  }
  
  public func sync(block: () -> ()) {
    dispatch_sync(queue, block)
  }
  
  public func sync<T>(block: () -> T) -> T {
    var res: T! = nil
    sync {
      res = block()
    }
    return res
  }
}

public extension Queue {

  /// Returns context that executes blocks on this queue.
  public var context: ExecutionContext {
    return self.async
  }
}

internal protocol Lock {
  func lock()
  func unlock()
  func atomic<T>(@noescape body: () -> T) -> T
}

internal extension Lock {
  func atomic<T>(@noescape body: () -> T) -> T {
    lock(); defer { unlock() }
    return body()
  }
}

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

/// Recursive Lock
internal final class RecursiveLock: NSRecursiveLock, Lock {

  internal init(name: String) {
    super.init()
    self.name = name
  }
}
