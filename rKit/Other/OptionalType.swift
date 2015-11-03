//
//  Optional.swift
//  rStreams
//
//  Created by Srdan Rasic on 30/10/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

public protocol OptionalType {
  typealias Wrapped
  var _unbox: Optional<Wrapped> { get }
  init(_ some: Wrapped)
  init()
}

extension Optional: OptionalType {
  
  public var _unbox: Optional<Wrapped> {
    return self
  }
}
