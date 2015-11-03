//
//  BlockDisposable.swift
//  Streams
//
//  Created by Srdan Rasic on 18/10/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

/// A disposable that executes the given block upon disposing.
public final class BlockDisposable: DisposableType {
  
  public var isDisposed: Bool {
    return handler == nil
  }
  
  private var handler: (() -> ())?
  private let lock = RecursiveLock(name: "com.swift-bond.Bond.BlockDisposable")
  
  public init(_ handler: () -> ()) {
    self.handler = handler
  }
  
  public func dispose() {
    lock.lock()
    handler?()
    handler = nil
    lock.unlock()
  }
}


public class DeinitDisposable: DisposableType {
  
  public var otherDisposable: DisposableType? = nil
  
  public var isDisposed: Bool {
    return otherDisposable == nil
  }
  
  public init(disposable: DisposableType) {
    otherDisposable = disposable
  }
  
  public func dispose() {
    otherDisposable?.dispose()
  }
  
  deinit {
    otherDisposable?.dispose()
  }
}
