//
//  LazyProducer.swift
//  Streams
//
//  Created by Srdan Rasic on 18/10/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

public struct Stream<Event>: StreamType {
  
  public typealias Sink = Event -> ()
  
  public let producer: Sink -> DisposableType?
  
  public init(producer: Sink -> DisposableType?) {
    self.producer = producer
  }
  
  public func observe(on context: ExecutionContext, sink: Sink) -> DisposableType {
    let serialDisposable = SerialDisposable(otherDisposable: nil)
    serialDisposable.otherDisposable = producer { event in
      if !serialDisposable.isDisposed {
        context {
          sink(event)
        }
      }
    }
    return serialDisposable
  }
}

@warn_unused_result
public func create<Event>(producer producer: (Event -> ()) -> DisposableType?) -> Stream<Event> {
  return Stream<Event>(producer: producer)
}
