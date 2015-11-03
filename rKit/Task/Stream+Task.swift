//
//  Stream+Task.swift
//  rTasks
//
//  Created by Srdan Rasic on 01/11/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

public extension StreamType where Event: TaskType {
  
  @warn_unused_result
  public func merge() -> Task<Event.Value, Event.Error> {
    return create { sink in
      let compositeDisposable = CompositeDisposable()
      
      compositeDisposable += self.observe(on: ImmediateExecutionContext) { task in
        compositeDisposable += task.observe(on: ImmediateExecutionContext) { event in
          switch event {
          case .Next, .Failure:
            sink.sink(event)
          case .Success:
            break
          }
        }
      }
      return compositeDisposable
    }
  }
  
  @warn_unused_result
  public func switchToLatest() -> Task<Event.Value, Event.Error>  {
    return create { sink in
      let serialDisposable = SerialDisposable(otherDisposable: nil)
      let compositeDisposable = CompositeDisposable([serialDisposable])
      
      compositeDisposable += self.observe(on: ImmediateExecutionContext) { task in
        
        serialDisposable.otherDisposable?.dispose()
        serialDisposable.otherDisposable = task.observe(on: ImmediateExecutionContext) { event in
          
          switch event {
          case .Failure(let error):
            sink.failure(error)
          case .Success:
            break
          case .Next(let value):
            sink.next(value)
          }
        }
      }
      
      return compositeDisposable
    }
  }
  
  @warn_unused_result
  public func concat() -> Task<Event.Value, Event.Error>  {
    return create { sink in
      let serialDisposable = SerialDisposable(otherDisposable: nil)
      let compositeDisposable = CompositeDisposable([serialDisposable])
      
      var innerCompleted: Bool = true
      
      var taskQueue: [Event] = []
      
      var startNextTask: (() -> ())! = nil
      startNextTask = {
        innerCompleted = false
        let task = taskQueue.removeAtIndex(0)
        
        serialDisposable.otherDisposable?.dispose()
        serialDisposable.otherDisposable = task.observe(on: ImmediateExecutionContext) { event in
          switch event {
          case .Failure(let error):
            sink.failure(error)
          case .Success:
            innerCompleted = true
            if taskQueue.count > 0 {
              startNextTask()
            }
          case .Next(let value):
            sink.next(value)
          }
        }
      }
      
      let addToQueue = { (task: Event) -> () in
        taskQueue.append(task)
        if innerCompleted {
          startNextTask()
        }
      }
      
      compositeDisposable += self.observe(on: ImmediateExecutionContext) { task in
        addToQueue(task)
      }
      
      return compositeDisposable
    }
  }
}

public extension StreamType {
  
  @warn_unused_result
  public func flatMap<T: TaskType>(strategy: TaskFlatMapStrategy, transform: Event -> T) -> Task<T.Value, T.Error> {
    switch strategy {
    case .Latest:
      return map(transform).switchToLatest()
    case .Merge:
      return map(transform).merge()
    case .Concat:
      return map(transform).concat()
    }
  }
}
