//
//  TaskSink.swift
//  rTasks
//
//  Created by Srdan Rasic on 30/10/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

public struct TaskSink<Value, Error: ErrorType> {
  public let sink: TaskEvent<Value, Error> -> ()
  
  public func next(event: Value) {
    sink(.Next(event))
  }
  
  public func success() {
    sink(.Success)
  }
  
  public func failure(error: Error) {
    sink(.Failure(error))
  }
}
