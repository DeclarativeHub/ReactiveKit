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

/// Execution context is an abstraction over a thread or a dispatch queue.
///
///     let context = ExecutionContext.main
///
///     context.execute {
///       print("Printing on main queue.")
///     }
///
public struct ExecutionContext {

    public let context: (@escaping () -> Void) -> Void
    
    /// Execution context is just a function that executes other function.
    public init(_ context: @escaping (@escaping () -> Void) -> Void) {
        self.context = context
    }
    
    /// Execute given block in the context.
    @inlinable
    public func execute(_ block: @escaping () -> Void) {
        context(block)
    }

    /// Execution context that executes immediately and synchronously on current thread or queue.
    public static var immediate: ExecutionContext {
        return ExecutionContext { block in block () }
    }
    
    /// Executes immediately and synchronously if current thread is main thread. Otherwise executes
    /// asynchronously on main dispatch queue (main thread).
    public static var immediateOnMain: ExecutionContext {
        return ExecutionContext { block in
            if Thread.isMainThread {
                block()
            } else {
                DispatchQueue.main.async(execute: block)
            }
        }
    }
    
    /// Execution context bound to main dispatch queue.
    public static var main: ExecutionContext {
        return DispatchQueue.main.context
    }
    
    /// Execution context bound to global dispatch queue.
    @available(macOS 10.10, *)
    public static func global(qos: DispatchQoS.QoSClass = .default) -> ExecutionContext {
        return DispatchQueue.global(qos: qos).context
    }
    
    /// Execution context that breaks recursive class by ingoring them.
    public static func nonRecursive() -> ExecutionContext {
        var updating: Bool = false
        return ExecutionContext { block in
            guard !updating else { return }
            updating = true
            block()
            updating = false
        }
    }
}

extension DispatchQueue {
    
    /// Creates ExecutionContext from the queue.
    public var context: ExecutionContext {
        return ExecutionContext { block in
            self.async(execute: block)
        }
    }
    
    /// Schedule given block for execution after given interval passes.
    @available(*, deprecated, message: "Please use asyncAfter(deadline:execute:)")
    public func after(when interval: Double, block: @escaping () -> Void) {
        asyncAfter(deadline: .now() + interval, execute: block)
    }
    
    /// Schedule given block for execution after given interval passes.
    /// Scheduled execution can be cancelled by disposing the returned disposable.
    public func disposableAfter(when interval: Double, block: @escaping () -> Void) -> Disposable {
        let disposable = SimpleDisposable()
        asyncAfter(deadline: .now() + interval) {
            if !disposable.isDisposed {
                block()
            }
        }
        return disposable
    }
}
