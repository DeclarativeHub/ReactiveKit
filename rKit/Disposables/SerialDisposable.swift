//
//  SerialDisposable.swift
//  Streams
//
//  Created by Srdan Rasic on 18/10/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

/// A disposable that disposes other disposable.
public final class SerialDisposable: DisposableType {
  
  public private(set) var isDisposed: Bool = false
  private let lock = RecursiveLock(name: "com.swift-bond.Bond.SerialDisposable")
  
  /// Will dispose other disposable immediately if self is already disposed.
  public var otherDisposable: DisposableType? {
    didSet {
      lock.lock()
      if isDisposed {
        otherDisposable?.dispose()
      }
      lock.unlock()
    }
  }
  
  public init(otherDisposable: DisposableType?) {
    self.otherDisposable = otherDisposable
  }
  
  public func dispose() {
    lock.lock()
    if !isDisposed {
      isDisposed = true
      otherDisposable?.dispose()
    }
    lock.unlock()
  }
}
