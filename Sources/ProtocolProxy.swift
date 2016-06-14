//
//  RKDelegate.swift
//  ReactiveKit
//
//  Created by Srdan Rasic on 14/05/16.
//  Copyright © 2016 Srdan Rasic. All rights reserved.
//

import Foundation
import ObjectiveC

public class ProtocolProxy: RKProtocolProxyBase {

  private var invokers: [Selector: ((Int, UnsafeMutablePointer<Void>) -> Void, ((UnsafeMutablePointer<Void>) -> Void)?) -> Void] = [:]
  private var handlers: [Selector: AnyObject] = [:]
  private weak var object: NSObject?
  private let setter: Selector

  public init(object: NSObject, `protocol`: Protocol, setter: Selector) {
    self.object = object
    self.setter = setter
    super.init(withProtocol: `protocol`)
  }

  public override var forwardTo: NSObject? {
    get {
      return super.forwardTo
    }
    set {
      super.forwardTo = newValue
      registerDelegate()
    }
  }

  public override func hasHandlerForSelector(selector: Selector) -> Bool {
    return invokers[selector] != nil
  }

  public override func invoke(selector: Selector, argumentExtractor: (Int, UnsafeMutablePointer<Void>) -> Void, setReturnValue: ((UnsafeMutablePointer<Void>) -> Void)?) {
    guard let invoker = invokers[selector] else { return }
    invoker(argumentExtractor, setReturnValue)
  }

  private func registerInvoker<R>(selector: Selector, block: () -> R) {
    invokers[selector] = { extractor, setReturnValue in
      var r = block()
      if let setReturnValue = setReturnValue { setReturnValue(&r) }
    }
    registerDelegate()
  }

  private func registerInvoker<T, R>(selector: Selector, block: T -> R) {
    invokers[selector] = { extractor, setReturnValue in
      let a1 = UnsafeMutablePointer<T>.alloc(1)
      extractor(2, a1)
      var r = block(a1.memory as T)
      if let setReturnValue = setReturnValue { setReturnValue(&r) }
    }
    registerDelegate()
  }

  private func registerInvoker<T, U, R>(selector: Selector, block: (T, U) -> R) {
    invokers[selector] = { extractor, setReturnValue in
      let a1 = UnsafeMutablePointer<T>.alloc(1)
      extractor(2, a1)
      let a2 = UnsafeMutablePointer<U>.alloc(1)
      extractor(3, a2)
      var r = block(a1.memory as T, a2.memory as U)
      if let setReturnValue = setReturnValue { setReturnValue(&r) }
    }
    registerDelegate()
  }

  private func registerInvoker<T, U, V, R>(selector: Selector, block: (T, U, V) -> R) {
    invokers[selector] = { extractor, setReturnValue in
      let a1 = UnsafeMutablePointer<T>.alloc(1)
      extractor(2, a1)
      let a2 = UnsafeMutablePointer<U>.alloc(1)
      extractor(3, a2)
      let a3 = UnsafeMutablePointer<V>.alloc(1)
      extractor(4, a3)
      var r = block(a1.memory as T, a2.memory as U, a3.memory as V)
      if let setReturnValue = setReturnValue { setReturnValue(&r) }
    }
    registerDelegate()
  }

  private func registerInvoker<T, U, V, W, R>(selector: Selector, block: (T, U, V, W) -> R) {
    invokers[selector] = { extractor, setReturnValue in
      let a1 = UnsafeMutablePointer<T>.alloc(1)
      extractor(2, a1)
      let a2 = UnsafeMutablePointer<U>.alloc(1)
      extractor(3, a2)
      let a3 = UnsafeMutablePointer<V>.alloc(1)
      extractor(4, a3)
      let a4 = UnsafeMutablePointer<W>.alloc(1)
      extractor(5, a4)
      var r = block(a1.memory as T, a2.memory as U, a3.memory as V, a4.memory as W)
      if let setReturnValue = setReturnValue { setReturnValue(&r) }
    }
    registerDelegate()
  }

  private func registerInvoker<T, U, V, W, X, R>(selector: Selector, block: (T, U, V, W, X) -> R) {
    invokers[selector] = { extractor, setReturnValue in
      let a1 = UnsafeMutablePointer<T>.alloc(1)
      extractor(2, a1)
      let a2 = UnsafeMutablePointer<U>.alloc(1)
      extractor(3, a2)
      let a3 = UnsafeMutablePointer<V>.alloc(1)
      extractor(4, a3)
      let a4 = UnsafeMutablePointer<W>.alloc(1)
      extractor(5, a4)
      let a5 = UnsafeMutablePointer<X>.alloc(1)
      extractor(6, a5)
      var r = block(a1.memory as T, a2.memory as U, a3.memory as V, a4.memory as W, a5.memory as X)
      if let setReturnValue = setReturnValue { setReturnValue(&r) }
    }
    registerDelegate()
  }

  /// Maps the given protocol method to a stream. Whenever the method on the target object is called,
  /// the framework will call the provided `dispatch` closure that you can use to generate a stream.
  ///
  /// - parameter selector: Selector of the method to map.
  /// - parameter dispatch: A closure that dispatches calls to the given PushStream.
  public func stream<S, R>(selector: Selector, dispatch: PushStream<S> -> R) -> Stream<S> {
    if let stream = handlers[selector] {
      return (stream as! PushStream<S>).toStream()
    } else {
      let pushStream = PushStream<S>()
      handlers[selector] = pushStream
      registerInvoker(selector) { () -> R in
        return dispatch(pushStream)
      }
      return pushStream.toStream()
    }
  }

  /// Maps the given protocol method to a stream. Whenever the method on the target object is called,
  /// the framework will call the provided `dispatch` closure that you can use to generate a stream.
  ///
  /// - parameter selector: Selector of the method to map.
  /// - parameter dispatch: A closure that dispatches calls to the given PushStream.
  ///
  /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String
  /// in place of generic parameter A and R!
  public func stream<A, S, R>(selector: Selector, dispatch: (PushStream<S>, A) -> R) -> Stream<S> {
    if let stream = handlers[selector] {
      return (stream as! PushStream<S>).toStream()
    } else {
      let pushStream = PushStream<S>()
      handlers[selector] = pushStream
      registerInvoker(selector) { (a: A) -> R in
        return dispatch(pushStream, a)
      }
      return pushStream.toStream()
    }
  }

  /// Maps the given protocol method to a stream. Whenever the method on the target object is called,
  /// the framework will call the provided `dispatch` closure that you can use to generate a stream.
  ///
  /// - parameter selector: Selector of the method to map.
  /// - parameter dispatch: A closure that dispatches calls to the given PushStream.
  ///
  /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String
  /// in place of generic parameters A, B and R!
  public func stream<A, B, S, R>(selector: Selector, dispatch: (PushStream<S>, A, B) -> R) -> Stream<S> {
    if let stream = handlers[selector] {
      return (stream as! PushStream<S>).toStream()
    } else {
      let pushStream = PushStream<S>()
      handlers[selector] = pushStream
      registerInvoker(selector) { (a: A, b: B) -> R in
        return dispatch(pushStream, a, b)
      }
      return pushStream.toStream()
    }
  }

  /// Maps the given protocol method to a stream. Whenever the method on the target object is called,
  /// the framework will call the provided `dispatch` closure that you can use to generate a stream.
  ///
  /// - parameter selector: Selector of the method to map.
  /// - parameter dispatch: A closure that dispatches calls to the given PushStream.
  ///
  /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String
  /// in place of generic parameters A, B, C and R!
  public func stream<A, B, C, S, R>(selector: Selector, dispatch: (PushStream<S>, A, B, C) -> R) -> Stream<S> {
    if let stream = handlers[selector] {
      return (stream as! PushStream<S>).toStream()
    } else {
      let pushStream = PushStream<S>()
      handlers[selector] = pushStream
      registerInvoker(selector) { (a: A, b: B, c: C) -> R in
        return dispatch(pushStream, a, b, c)
      }
      return pushStream.toStream()
    }
  }

  /// Maps the given protocol method to a stream. Whenever the method on the target object is called,
  /// the framework will call the provided `dispatch` closure that you can use to generate a stream.
  ///
  /// - parameter selector: Selector of the method to map.
  /// - parameter dispatch: A closure that dispatches calls to the given PushStream.
  ///
  /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String
  /// in place of generic parameters A, B, C, D and R!
  public func stream<A, B, C, D, S, R>(selector: Selector, dispatch: (PushStream<S>, A, B, C, D) -> R) -> Stream<S> {
    if let stream = handlers[selector] {
      return (stream as! PushStream<S>).toStream()
    } else {
      let pushStream = PushStream<S>()
      handlers[selector] = pushStream
      registerInvoker(selector) { (a: A, b: B, c: C, d: D) -> R in
        return dispatch(pushStream, a, b, c, d)
      }
      return pushStream.toStream()
    }
  }

  /// Maps the given protocol method to a stream. Whenever the method on the target object is called,
  /// the framework will call the provided `dispatch` closure that you can use to generate a stream.
  ///
  /// - parameter selector: Selector of the method to map.
  /// - parameter dispatch: A closure that dispatches calls to the given PushStream.
  ///
  /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String
  /// in place of generic parameters A, B, C, D, E and R!
  public func stream<A, B, C, D, E, S, R>(selector: Selector, dispatch: (PushStream<S>, A, B, C, D, E) -> R) -> Stream<S> {
    if let stream = handlers[selector] {
      return (stream as! PushStream<S>).toStream()
    } else {
      let pushStream = PushStream<S>()
      handlers[selector] = pushStream
      registerInvoker(selector) { (a: A, b: B, c: C, d: D, e: E) -> R in
        return dispatch(pushStream, a, b, c, d, e)
      }
      return pushStream.toStream()
    }
  }

  public override func conformsToProtocol(`protocol`: Protocol) -> Bool {
    if protocol_isEqual(`protocol`, self.`protocol`) {
      return true
    } else {
      return super.conformsToProtocol(`protocol`)
    }
  }

  public override func respondsToSelector(selector: Selector) -> Bool {
    if handlers[selector] != nil {
      return true
    } else if forwardTo?.respondsToSelector(selector) ?? false {
      return true
    } else {
      return super.respondsToSelector(selector)
    }
  }

  private func registerDelegate() {
    object?.performSelector(setter, withObject: nil)
    object?.performSelector(setter, withObject: self)
  }

  deinit {
    object?.performSelector(setter, withObject: nil)
  }
}

extension NSObject {

  private struct AssociatedKeys {
    static var ProtocolProxies = "ProtocolProxies"
  }

  private var protocolProxies: [String: ProtocolProxy] {
    get {
      if let proxies = objc_getAssociatedObject(self, &AssociatedKeys.ProtocolProxies) as? [String: ProtocolProxy] {
        return proxies
      } else {
        let proxies = [String: ProtocolProxy]()
        objc_setAssociatedObject(self, &AssociatedKeys.ProtocolProxies, proxies as NSDictionary, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return proxies
      }
    }
    set {
      objc_setAssociatedObject(self, &AssociatedKeys.ProtocolProxies, newValue as NSDictionary, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }

  /// Registers and returns an object that will act as a delegate (or data source) for given protocol and setter method.
  ///
  /// For example, to register a table view delegate do: `tableView.protocolProxyFor(UITableViewDelegate.self, setter: NSSelectorFromString("setDelegate:"))`.
  ///
  /// Note that if the protocol has any required methods, you have to handle them by providing a stream, a feed or implement them in a class
  /// whose instance you'll set to `forwardTo` property.
  public func protocolProxyFor(`protocol`: Protocol, setter: Selector) -> ProtocolProxy {
    let key = String.fromCString(protocol_getName(`protocol`))!
    if let proxy = protocolProxies[key] {
      return proxy
    } else {
      let proxy = ProtocolProxy(object: self, protocol: `protocol`, setter: setter)
      protocolProxies[key] = proxy
      return proxy
    }
  }
}

// MARK: - Deprecated 

extension ProtocolProxy {

  /// Maps the given protocol method to a stream.
  ///
  /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String!
  @available(*, deprecated=2.1, message="Please use method stream(selector:dispatch:)")
  public func streamFor<T, Z>(selector: Selector, map: T -> Z) -> Stream<Z> {
    return stream(selector) { (pushStream: PushStream<Z>, a1: T) in
      pushStream.next(map(a1))
    }
  }

  /// Provides a feed for specified protocol method.
  ///
  /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String!
  public func feed<A, T, R>(property: Property<A>, to selector: Selector, map: (A, T) -> R) {
    let _ = stream(selector) { (_: PushStream<Void>, a1: T) -> R in
      return map(property.value, a1)
    }
  }

  /// Maps the given protocol method to a stream.
  ///
  /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String!
  @available(*, deprecated=2.1, message="Please use method stream(selector:dispatch:)")
  public func streamFor<T, U, Z>(selector: Selector, map: (T, U) -> Z) -> Stream<Z> {
    return stream(selector) { (pushStream: PushStream<Z>, a1: T, a2: U) in
      pushStream.next(map(a1, a2))
    }
  }

  /// Provides a feed for specified protocol method.
  ///
  /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String!
  public func feed<A, T, U, R>(property: Property<A>, to selector: Selector, map: (A, T, U) -> R) {
    let _ = stream(selector) { (_: PushStream<Void>, a1: T, a2: U) -> R in
      return map(property.value, a1, a2)
    }
  }

  /// Maps the given protocol method to a stream.
  ///
  /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String!
  @available(*, deprecated=2.1, message="Please use method stream(selector:dispatch:)")
  public func streamFor<T, U, V, Z>(selector: Selector, map: (T, U, V) -> Z) -> Stream<Z> {
    return stream(selector) { (pushStream: PushStream<Z>, a1: T, a2: U, a3: V) in
      pushStream.next(map(a1, a2, a3))
    }
  }

  /// Provides a feed for specified protocol method.
  ///
  /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String!
  public func feed<A, T, U, V, R>(property: Property<A>, to selector: Selector, map: (A, T, U, V) -> R) {
    let _ = stream(selector) { (_: PushStream<Void>, a1: T, a2: U, a3: V) -> R in
      return map(property.value, a1, a2, a3)
    }
  }

  /// Maps the given protocol method to a stream.
  ///
  /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String!
  @available(*, deprecated=2.1, message="Please use method stream(selector:dispatch:)")
  public func streamFor<T, U, V, W, Z>(selector: Selector, map: (T, U, V, W) -> Z) -> Stream<Z> {
    return stream(selector) { (pushStream: PushStream<Z>, a1: T, a2: U, a3: V, a4: W) in
      pushStream.next(map(a1, a2, a3, a4))
    }
  }

  /// Provides a feed for specified protocol method.
  ///
  /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String!
  public func feed<A, T, U, V, W, R>(property: Property<A>, to selector: Selector, map: (A, T, U, V, W) -> R) {
    let _ = stream(selector) { (_: PushStream<Void>, a1: T, a2: U, a3: V, a4: W) -> R in
      return map(property.value, a1, a2, a3, a4)
    }
  }

  /// Maps the given protocol method to a stream.
  ///
  /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String!
  @available(*, deprecated=2.1, message="Please use method stream(selector:dispatch:)")
  public func streamFor<T, U, V, W, X, Z>(selector: Selector, map: (T, U, V, W, X) -> Z) -> Stream<Z> {
    return stream(selector) { (pushStream: PushStream<Z>, a1: T, a2: U, a3: V, a4: W, a5: X) in
      pushStream.next(map(a1, a2, a3, a4, a5))
    }
  }

  /// Provides a feed for specified protocol method.
  ///
  /// - important: This is ObjC API so you have to use ObjC types like NSString instead of String!
  public func feed<A, T, U, V, W, X, R>(property: Property<A>, to selector: Selector, map: (A, T, U, V, W, X) -> R) {
    let _ = stream(selector) { (_: PushStream<Void>, a1: T, a2: U, a3: V, a4: W, a5: X) -> R in
      return map(property.value, a1, a2, a3, a4, a5)
    }
  }
}
