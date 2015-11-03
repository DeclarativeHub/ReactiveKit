//
//  DisposeBag.swift
//  Streams
//
//  Created by Srdan Rasic on 18/10/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

/// A disposable container that will dispose a collection of disposables upon deinit.
public final class DisposeBag: DisposableType {
  private var disposables: [DisposableType] = []
  
  /// This will return true whenever the bag is empty.
  public var isDisposed: Bool {
    return disposables.count == 0
  }
  
  public init() {
  }
  
  /// Adds the given disposable to the bag.
  /// DisposableType will be disposed when the bag is deinitialized.
  public func addDisposable(disposable: DisposableType) {
    disposables.append(disposable)
  }
  
  /// Disposes all disposables that are currenty in the bag.
  public func dispose() {
    for disposable in disposables {
      disposable.dispose()
    }
    disposables = []
  }
  
  deinit {
    dispose()
  }
}

public extension DisposableType {
  public func disposeIn(disposeBag: DisposeBag) {
    disposeBag.addDisposable(self)
  }
}
