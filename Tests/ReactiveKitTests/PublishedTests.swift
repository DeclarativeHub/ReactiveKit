//
//  PublishedTests.swift
//  ReactiveKit-iOS
//
//  Created by Ibrahim Koteish on 15/12/2019.
//  Copyright © 2019 DeclarativeHub. All rights reserved.
//

import XCTest
import ReactiveKit


// Commented out for Travis build

//class PublishedTests: XCTestCase {
//
//  struct User {
//    @ReactiveKit.Published var id: String
//  }
//
//  func testPublished() {
//    let exp = expectation(description: "completed")
//
//    var user = User(id: "0")
//
//    let expectedEvents = ["0", "1", "2", "3"]
//        .map { Signal<String, Never>.Event.next($0) }
//
//    user.$id.expectAsync(events: expectedEvents, expectation: exp)
//
//
//    XCTAssertEqual(user.id, "0")
//
//    user.id = "1"
//    user.id = "2"
//    user.id = "3"
//
//
//    waitForExpectations(timeout: 1)
//
//  }
//}
