//
//  PerformanceTests.swift
//  ReactiveKit
//
//  Created by Srdan Rasic on 23/11/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

import XCTest
@testable import ReactiveKit

class PerformanceTests: XCTestCase {

  func test1() {
    measureBlock {
      var counter: Int = 0
      let observable = Observable(0)

      observable.observe(on: nil) { counter += $0 }

      for i in 1..<10000 {
        observable.value = i
      }
    }
  }

  func test2() {
    measureBlock {
      var counter: Int = 0
      let observable = Observable(0)

      for _ in 1..<30 {
        observable.observe(on: nil) { counter += $0 }
      }

      for i in 1..<10000 {
        observable.value = i
      }
    }
  }

  func test_measure_3() {
    measureBlock {
      let observable = Observable(0)
      var counter : Int = 0

      for _ in 1..<30 {
        observable.filter{ $0 % 2 == 0 }.observe(on: nil) { counter += $0 }
      }

      for i in 1..<10000 {
        observable.value = i
      }
    }
  }
}
