//
//  CompositeDisposable.swift
//  Streams
//
//  Created by Srdan Rasic on 18/10/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

/// A disposable that disposes a collection of disposables upon disposing.
public final class CompositeDisposable: DisposableType {
  
  public private(set) var isDisposed: Bool = false
  private var disposables: [DisposableType] = []
  private let lock = RecursiveLock(name: "com.swift-bond.Bond.CompositeDisposable")
  
  public convenience init() {
    self.init([])
  }
  
  public init(_ disposables: [DisposableType]) {
    self.disposables = disposables
  }
  
  public func addDisposable(disposable: DisposableType) {
    lock.lock()
    if isDisposed {
      disposable.dispose()
    } else {
      disposables.append(disposable)
      self.disposables = disposables.filter { $0.isDisposed == false }
    }
    lock.unlock()
  }
  
  public func dispose() {
    lock.lock()
    isDisposed = true
    for disposable in disposables {
      disposable.dispose()
    }
    disposables = []
    lock.unlock()
  }
}

public func += (left: CompositeDisposable, right: DisposableType) {
  left.addDisposable(right)
}
