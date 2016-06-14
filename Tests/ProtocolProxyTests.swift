//
//  ProcolProxyTests.swift
//  ReactiveKit
//
//  Created by Srdan Rasic on 06/06/16.
//  Copyright © 2016 Srdan Rasic. All rights reserved.
//

import XCTest
@testable import ReactiveKit

@objc protocol TestDelegate {
  func methodA()
  func methodB(object: TestObject)
  func methodC(object: TestObject, value: Int)
  func methodD(object: TestObject, value: Int) -> NSString
}

class TestObject: NSObject {
  weak var delegate: TestDelegate! = nil

  override init() {
    super.init()
  }

  func callMethodA() {
    delegate.methodA()
  }

  func callMethodB() {
    delegate.methodB(self)
  }

  func callMethodC(value: Int) {
    delegate.methodC(self, value: value)
  }

  func callMethodD(value: Int) -> NSString {
    return delegate.methodD(self, value: value)
  }
}

class ProtocolProxyTests: XCTestCase {

  var object: TestObject! = nil

  var delegate: ProtocolProxy {
    return object.protocolProxyFor(TestDelegate.self, setter: NSSelectorFromString("setDelegate:"))
  }

  override func setUp() {
    object = TestObject()
  }

  func testCallbackA() {
    let stream = delegate.stream(#selector(TestDelegate.methodA)) { (stream: PushStream<Int>) in
      stream.next(0)
    }

    stream.expectNext([0, 0])
    object.callMethodA()
    object.callMethodA()
  }

  func testCallbackB() {
    let stream = delegate.stream(#selector(TestDelegate.methodB(_:))) { (stream: PushStream<Int>, _: TestObject) in
      stream.next(0)
    }

    stream.expectNext([0, 0])
    object.callMethodB()
    object.callMethodB()
  }

  func testCallbackC() {
    let stream = delegate.stream(#selector(TestDelegate.methodC(_:value:))) { (stream: PushStream<Int>, _: TestObject, value: Int) in
      stream.next(value)
    }

    stream.expectNext([10, 20])
    object.callMethodC(10)
    object.callMethodC(20)
  }

  func testCallbackD() {
    let stream = delegate.stream(#selector(TestDelegate.methodD(_:value:))) { (stream: PushStream<Int>, _: TestObject, value: Int) -> NSString in
      stream.next(value)
      return "\(value)"
    }

    stream.expectNext([10, 20])
    XCTAssertEqual(object.callMethodD(10), "10")
    XCTAssertEqual(object.callMethodD(20), "20")
  }
}
