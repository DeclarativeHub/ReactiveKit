//
//  ExecutionContext.swift
//  Streams
//
//  Created by Srdan Rasic on 25/10/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

public typealias ExecutionContext = (() -> Void) -> Void

public let ImmediateExecutionContext: ExecutionContext = { task in
  task()
}

public extension Queue {
  public var context: ExecutionContext {
    return self.async
  }
}
