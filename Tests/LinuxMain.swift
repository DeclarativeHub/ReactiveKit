import XCTest
@testable import ReactiveKitTests

XCTMain([
  testCase(SignalTests.allTests),
  testCase(PropertyTests.allTests),
  testCase(ResultTests.allTests),
])
