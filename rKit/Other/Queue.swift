//
//  Queue.swift
//  Streams
//
//  Created by Srdan Rasic on 20/10/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

import Dispatch
import Foundation

/// A simple wrapper around GCD queue.
public struct Queue {
  
  public typealias TimeInterval = NSTimeInterval
  
  public static let Main = Queue(queue: dispatch_get_main_queue());
  public static let Default = Queue(queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
  public static let Background = Queue(queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0))
  
  public private(set) var queue: dispatch_queue_t
  
  public init(queue: dispatch_queue_t = dispatch_queue_create("com.swift-bond.Bond.Queue", DISPATCH_QUEUE_SERIAL)) {
    self.queue = queue
  }
  
  public func after(interval: NSTimeInterval, block: () -> ()) {
    let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(interval * NSTimeInterval(NSEC_PER_SEC)))
    dispatch_after(dispatchTime, queue, block)
  }
  
  public func async(block: () -> ()) {
    dispatch_async(queue, block)
  }
  
  public func sync(block: () -> ()) {
    dispatch_sync(queue, block)
  }
}
