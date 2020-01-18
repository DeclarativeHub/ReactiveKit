//
//  PublishedTests.swift
//  ReactiveKit-iOS
//
//  Created by Ibrahim Koteish on 15/12/2019.
//  Copyright © 2019 DeclarativeHub. All rights reserved.
//

import XCTest
import ReactiveKit

#if compiler(>=5.1)

class PublishedTests: XCTestCase {
    
    class User: ReactiveKit.ObservableObject {
        @ReactiveKit.Published var id: Int
        init(id: Int) { self.id = id }
    }
    
    func testPublished() {
        
        let user = User(id: 0)
        
        let objectSubscriber = Subscribers.Accumulator<Void, Never>()
        let propertySubscriber = Subscribers.Accumulator<Int, Never>()
        
        user.objectWillChange.subscribe(objectSubscriber)
        user.$id.subscribe(propertySubscriber)
        
        XCTAssertEqual(user.id, 0)
        
        user.id = 1
        user.id = 2
        user.id = 3
        
        XCTAssertEqual(propertySubscriber.values, [0, 1, 2, 3])
        XCTAssertFalse(propertySubscriber.isFinished)
        
        XCTAssertEqual(objectSubscriber.values.count, 3)
        XCTAssertFalse(objectSubscriber.isFinished)
    }
}

#endif
