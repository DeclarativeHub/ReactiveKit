//
//  Bindable.swift
//  rStreams
//
//  Created by Srdan Rasic on 25/10/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

public protocol BindableType {
  typealias Event
  
  /// Returns a sink that can be used to dispatch events to the receiver.
  /// Can accept a disposable that will be disposed on receiver's deinit.
  func sink(disconnectDisposable: DisposableType?) -> (Event -> ())
}

extension ActiveStream: BindableType {
  
  /// Creates a new sink that can be used to update the receiver.
  /// Optionally accepts a disposable that will be disposed on receiver's deinit.
  public func sink(disconnectDisposable: DisposableType?) -> Event -> () {
    
    if let disconnectDisposable = disconnectDisposable {
      registerDisposable(disconnectDisposable)
    }
    
    return { [weak self] value in
      self?.next(value)
    }
  }
}

extension StreamType {
  
  /// Establishes a one-way binding between the source and the bindable's sink
  /// and returns a disposable that can cancel observing.
  public func bindTo<B: BindableType where B.Event == Event>(bindable: B, context: ExecutionContext = Queue.Main.context) -> DisposableType {
    let disposable = SerialDisposable(otherDisposable: nil)
    let sink = bindable.sink(disposable)
    disposable.otherDisposable = observe(on: context) { value in
      sink(value)
    }
    return disposable
  }
  
  /// Establishes a one-way binding between the source and the bindable's sink
  /// and returns a disposable that can cancel observing.
  public func bindTo<B: BindableType where B.Event == Event?>(bindable: B, context: ExecutionContext = Queue.Main.context) -> DisposableType {
    let disposable = SerialDisposable(otherDisposable: nil)
    let sink = bindable.sink(disposable)
    disposable.otherDisposable = observe(on: context) { value in
      sink(value)
    }
    return disposable
  }
  
  /// Establishes a one-way binding between the source and the bindable's sink
  /// and returns a disposable that can cancel observing.
  public func bindTo<S: StreamType where S: BindableType, S.Event == Event>(bindable: S, context: ExecutionContext = Queue.Main.context) -> DisposableType {
    let disposable = SerialDisposable(otherDisposable: nil)
    let sink = bindable.sink(disposable)
    disposable.otherDisposable = observe(on: context) { value in
      sink(value)
    }
    return disposable
  }
}
