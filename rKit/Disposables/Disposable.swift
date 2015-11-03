//
//  Disposable.swift
//  Streams
//
//  Created by Srdan Rasic on 18/10/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

/// Objects conforming to this protocol can dispose or cancel connection or task.
public protocol DisposableType {
  
  /// Disposes or cancels a connection or a task.
  func dispose()
  
  /// Returns `true` is already disposed.
  var isDisposed: Bool { get }
}
