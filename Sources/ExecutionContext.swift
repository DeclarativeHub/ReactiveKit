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
import Dispatch

/// Represents a context that can execute given block.
public typealias ExecutionContext = (@escaping () -> Void) -> Void

/// Execute block on current thread or queue.
public let ImmediateExecutionContext: ExecutionContext = { block in
  block()
}

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

  /// Context that executes blocks on this queue.
  public func context(_ block: @escaping () -> Void) {
    self.async(execute: block)
  }

  /// Schedule given block for execution after given interval passes.
  public func after(when interval: Double, block: @escaping () -> Void) {
    asyncAfter(deadline: .now() + interval, execute: block)
  }

  /// Schedule given block for execution after given interval passes.
  /// Scheduled execution can be cancelled by disposing the returned disposable.
  public func disposableAfter(when interval: Double, block: @escaping () -> Void) -> Disposable {
    let disposable = SimpleDisposable()
    after(when: interval) {
      if !disposable.isDisposed {
        block()
      }
    }
    return disposable
  }
}
