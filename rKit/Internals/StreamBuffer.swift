//
//  StreamBuffer.swift
//  Streams
//
//  Created by Srdan Rasic on 18/10/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

public class StreamBuffer<Event> {
  
  public var array: [Event] = []
  public let limit: Int
  
  public init(limit: Int = Int.max) {
    self.limit = limit
  }
  
  public func next(event: Event) {
    array.append(event)
    if array.count > limit {
      array = Array(array.suffixFrom(1))
    }
  }
  
  public func replay(observer: Event -> ()) {
    for value in array {
      observer(value)
    }
  }
  
  public func last() throws -> Event {
    if array.count > 0 {
      return array.last!
    } else {
      throw StreamBufferError.NoEvent
    }
  }
}

public enum StreamBufferError: ErrorType {
  case NoEvent
}
