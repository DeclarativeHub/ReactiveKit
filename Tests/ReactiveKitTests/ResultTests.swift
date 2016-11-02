//
//  ResultTests.swift
//  ReactiveKit
//
//  Created by Srdan Rasic on 22/10/2016.
//  Copyright © 2016 Srdan Rasic. All rights reserved.
//

import XCTest
import ReactiveKit

class ResultTests: XCTestCase {

  func testSuccess() {
    let result = Result<Int, TestError>(5)

    XCTAssert(result.error == nil)
    XCTAssert(result.value != nil && result.value! == 5)
  }

  func testFailured() {
    let result = Result<Int, TestError>(.Error)

    XCTAssert(result.error != nil && result.error! == .Error)
    XCTAssert(result.value == nil)
  }
}
