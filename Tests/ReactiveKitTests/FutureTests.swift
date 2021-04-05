//
//  FutureTests.swift
//  ReactiveKit
//
//  Created by Ibrahim Koteish on 05/04/2021.
//  Copyright © 2021 DeclarativeHub. All rights reserved.

import XCTest
import ReactiveKit


final class FutureTests: XCTestCase {

  func testSuccessFuture() {

    let exp = XCTestExpectation()

    let future = Future<Int, Never> { callback in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        callback(.success(42))
        exp.fulfill()
      }
    }

    let futureAcc = Subscribers.Accumulator<Int, Never>()
    future.subscribe(futureAcc)

    wait(for: [exp], timeout: 0.2)

    XCTAssertEqual(futureAcc.values, [42])
    XCTAssertTrue(futureAcc.isFinished)

  }

  func testSuccessFutureWithResult() {


    let future = Future<Int, Never> { callback in
        callback(.success(42))
    }

    let futureAcc = Subscribers.Accumulator<Int, Never>()
    future.subscribe(futureAcc)

    XCTAssertEqual(futureAcc.values, [42])
    XCTAssertTrue(futureAcc.isFinished)

    let futureAcc2 = Subscribers.Accumulator<Int, Never>()
    future.subscribe(futureAcc2)

    XCTAssertEqual(futureAcc2.values, [42])
    XCTAssertTrue(futureAcc2.isFinished)

  }

  func testdoubleCallback() {

    let exp = XCTestExpectation()

    let future = Future<Int, Never> { callback in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        callback(.success(42))
        callback(.success(24))
        exp.fulfill()
      }
    }

    wait(for: [exp], timeout: 0.2)

    let futureAcc = Subscribers.Accumulator<Int, Never>()
    future.subscribe(futureAcc)

    XCTAssertEqual(futureAcc.values, [42])
    XCTAssertTrue(futureAcc.isFinished)

    let futureAcc2 = Subscribers.Accumulator<Int, Never>()
    future.subscribe(futureAcc2)

    XCTAssertEqual(futureAcc2.values, [42])
    XCTAssertTrue(futureAcc2.isFinished)

  }

  func testFailureFuture() {

    enum FutureError: Error {
      case badFuture
    }

    let exp = XCTestExpectation()

    let future = Future<Int, FutureError> { callback in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        callback(.failure(.badFuture))
        exp.fulfill()
      }
    }

    let futureAcc = Subscribers.Accumulator<Int, FutureError>()
    future.subscribe(futureAcc)

    wait(for: [exp], timeout: 0.2)

    XCTAssertEqual(futureAcc.values, [])
    XCTAssertEqual(futureAcc.error, .badFuture)
    XCTAssertTrue(futureAcc.isFailure)

  }
}
