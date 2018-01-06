//
//  PropertyTests.swift
//  ReactiveKit
//
//  Created by Srdan Rasic on 17/10/2016.
//  Copyright © 2016 Srdan Rasic. All rights reserved.
//

import XCTest
import ReactiveKit

class PropertyTests: XCTestCase {

  var property: Property<Int>!

  override func setUp() {
    property = Property(0)
  }

  func testValue() {
    XCTAssert(property.value == 0)
    property.value = 1
    XCTAssert(property.value == 1)
  }

  func testEvents() {
    property.expectAsync(events: 
      [
      .next(0),
      .next(5),
      .next(10),
      .next(20),
      .next(30),
      .next(40),
      .completed],
      expectation: expectation(description: "Property did not fire expected events")
    )

    property.value = 5
    property.value = 10
    SafeSignal.sequence([20, 30]).bind(to: property)
    property.value = 40

    weak var weakProperty = property
    property = nil
    XCTAssert(weakProperty == nil)

    waitForExpectations(timeout: 1, handler: nil)
  }

  func testReadOnlyView() {
    var readOnlyView: AnyProperty<Int>! = property.readOnlyView
    XCTAssert(readOnlyView.value == 0)

    readOnlyView.expectAsync(events: 
      [
        .next(0),
        .next(5),
        .next(10),
        .next(20),
        .next(30),
        .next(40),
        .completed],
      expectation: expectation(description: "Property did not fire expected events")
    )

    property.value = 5
    property.value = 10
    SafeSignal.sequence([20, 30]).bind(to: property)
    property.value = 40

    XCTAssert(readOnlyView.value == 40)

    weak var weakProperty = property
    weak var weakReadOnlyView = readOnlyView
    property = nil
    readOnlyView = nil
    XCTAssert(weakProperty == nil)
    XCTAssert(weakReadOnlyView == nil)

    waitForExpectations(timeout: 1, handler: nil)
  }

  func testBidirectionalBind() {
    let target = Property(100)

    target.ignoreTerminal().expectAsync(events: [.next(100), .next(0), .next(50), .next(60)], expectation: expectation(description: "nexts"))
    property.ignoreTerminal().expectAsync(events: [.next(0), .next(0), .next(50), .next(60)], expectation: expectation(description: "nexts"))

    property.bidirectionalBind(to: target)
    property.value = 50
    target.value = 60
    
    waitForExpectations(timeout: 2, handler: nil)
  }
}

extension PropertyTests {

  static var allTests : [(String, (PropertyTests) -> () -> Void)] {
    return [
      ("testValue", testValue),
      ("testEvents", testEvents),
      ("testReadOnlyView", testReadOnlyView),
      ("testBidirectionalBind", testBidirectionalBind)
    ]
  }
}
