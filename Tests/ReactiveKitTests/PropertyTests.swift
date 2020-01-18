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
        let subscriber = Subscribers.Accumulator<Int, Never>()
        property.subscribe(subscriber)

        property.value = 5
        property.value = 10
        SafeSignal(sequence: [20, 30]).bind(to: property)
        property.value = 40

        weak var weakProperty = property
        property = nil
        XCTAssert(weakProperty == nil)

        XCTAssertEqual(subscriber.values, [0, 5, 10, 20, 30, 40])
        XCTAssertTrue(subscriber.isFinished)
    }

    func testReadOnlyView() {
        var readOnlyView: AnyProperty<Int>! = property.readOnlyView
        XCTAssert(readOnlyView.value == 0)

        let subscriber = Subscribers.Accumulator<Int, Never>()
        readOnlyView.subscribe(subscriber)

        property.value = 5
        property.value = 10
        SafeSignal(sequence: [20, 30]).bind(to: property)
        property.value = 40

        XCTAssert(readOnlyView.value == 40)

        weak var weakProperty = property
        weak var weakReadOnlyView = readOnlyView
        property = nil
        readOnlyView = nil
        XCTAssert(weakProperty == nil)
        XCTAssert(weakReadOnlyView == nil)

        XCTAssertEqual(subscriber.values, [0, 5, 10, 20, 30, 40])
        XCTAssertTrue(subscriber.isFinished)
    }
    
    func testBidirectionalBind() {
        let target = Property(100)
        let s1 = Subscribers.Accumulator<Int, Never>()
        let s2 = Subscribers.Accumulator<Int, Never>()

        target.ignoreTerminal().subscribe(s1)
        property.ignoreTerminal().subscribe(s2)
        
        property.bidirectionalBind(to: target)
        property.value = 50
        target.value = 60
        
        XCTAssertEqual(s1.values, [100, 0, 50, 60])
        XCTAssertEqual(s2.values, [0, 0, 50, 60])
    }
    
    func testPropertyForThreadSafety_oneEventDispatchedOnALotOfProperties() {
        let exp = expectation(description: "race_condition?")
        exp.expectedFulfillmentCount = 10000
        
        for _ in 0..<exp.expectedFulfillmentCount {
            let disposeBag = DisposeBag()
            let property = Property(0)
            
            property.stress(with: [{ property.value = $0 }],
                            eventsCount: 1,
                            expectation: exp)
                .dispose(in: disposeBag)
            
            DispatchQueue.main.async {
                disposeBag.dispose()
            }
        }
        
        waitForExpectations(timeout: 3)
    }

    func testPropertyForThreadSafety_lotsOfEventsDispatchedOnOneProperty() {
        let exp = expectation(description: "race_condition?")
        
        let disposeBag = DisposeBag()
        let property = Property(0)

        property.stress(with: [{ property.value = $0 }],
                        queuesCount: 10,
                        eventsCount: 3000,
                        expectation: exp)
            .dispose(in: disposeBag)
        
        waitForExpectations(timeout: 3)
    }
    
    func testPropertyForThreadSafety_someEventsDispatchedOnSomeProperties() {
        let exp = expectation(description: "race_condition?")
        exp.expectedFulfillmentCount = 100
        
        for _ in 0..<exp.expectedFulfillmentCount {
            let disposeBag = DisposeBag()
            let property = Property(0)
            
            property.stress(with: [{ property.value = $0 }],
                            expectation: exp)
                .dispose(in: disposeBag)
            
            DispatchQueue.main.async {
                disposeBag.dispose()
            }
        }
        
        waitForExpectations(timeout: 3)
    }
}

extension PropertyTests {
    
    static var allTests : [(String, (PropertyTests) -> () -> Void)] {
        return [
            ("testValue", testValue),
            ("testEvents", testEvents),
            ("testReadOnlyView", testReadOnlyView),
            ("testBidirectionalBind", testBidirectionalBind),
            ("testPropertyForThreadSafety_oneEventDispatchedOnALotOfProperties", testPropertyForThreadSafety_oneEventDispatchedOnALotOfProperties),
            ("testPropertyForThreadSafety_lotsOfEventsDispatchedOnOneProperty", testPropertyForThreadSafety_lotsOfEventsDispatchedOnOneProperty),
            ("testPropertyForThreadSafety_someEventsDispatchedOnSomeProperties", testPropertyForThreadSafety_someEventsDispatchedOnSomeProperties),
        ]
    }
}
