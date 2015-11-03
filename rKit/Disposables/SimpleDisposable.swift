//
//  SimpleDisposable.swift
//  Streams
//
//  Created by Srdan Rasic on 18/10/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

/// A disposable that just encapsulates disposed state.
public final class SimpleDisposable: DisposableType {
  public private(set) var isDisposed: Bool = false
  
  public func dispose() {
    isDisposed = true
  }
  
  public init() {}
}
