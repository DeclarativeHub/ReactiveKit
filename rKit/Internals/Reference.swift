//
//  Reference.swift
//  Streams
//
//  Created by Srdan Rasic on 20/10/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

/// A simple wrapper around an optional that can retain or release given optional at will.
internal final class Reference<T: AnyObject> {
  
  /// Encapsulated optional object.
  internal weak var object: T?
  
  /// Used to strongly reference (retain) encapsulated object.
  private var strongReference: T?
  
  /// Creates the wrapper and strongly references the given object.
  internal init(_ object: T) {
    self.object = object
    self.strongReference = object
  }
  
  /// Relinquishes strong reference to the object, but keeps weak one.
  /// If object it not strongly referenced by anyone else, it will be deallocated.
  internal func release() {
    strongReference = nil
  }
  
  /// Re-establishes a strong reference to the object if it's still alive,
  /// otherwise it doesn't do anything useful.
  internal func retain() {
    strongReference = object
  }
}
