//
//  CollectionPropertyTests.swift
//  ReactiveKit
//
//  Created by Srdan Rasic on 05/06/16.
//  Copyright © 2016 Srdan Rasic. All rights reserved.
//

import XCTest
@testable import ReactiveKit

class CollectionPropertyTests: XCTestCase {

  var collection: CollectionProperty<[Int]>!

  override func setUp() {
    collection = CollectionProperty([1, 2, 3])
  }

  func testFiresInitial() {
    collection.expectNext([CollectionChangeset(collection: [1, 2, 3], inserts: [], deletes: [], updates: [])])
  }

  func testArrayAppend() {
    collection.skip(1).expectNext([CollectionChangeset(collection: [1, 2, 3, 4], inserts: [3], deletes: [], updates: [])])
    collection.append(4)
  }

  func testArrayInsert() {
    collection.skip(1).expectNext([CollectionChangeset(collection: [0, 1, 2, 3], inserts: [0], deletes: [], updates: [])])
    collection.insert(0, atIndex: 0)
  }

  func testArrayRemoveLast() {
    collection.skip(1).expectNext([CollectionChangeset(collection: [1, 2], inserts: [], deletes: [2], updates: [])])
    collection.removeLast()
  }

  func testArrayRemoveAtIndex() {
    collection.skip(1).expectNext([CollectionChangeset(collection: [2, 3], inserts: [], deletes: [0], updates: [])])
    collection.removeAtIndex(0)
  }

  func testArrayUpdate() {
    collection.skip(1).expectNext([CollectionChangeset(collection: [10, 2, 3], inserts: [], deletes: [], updates: [0])])
    collection[0] = 10
  }


  func testArrayMapAppend() {
    collection.map { $0 * 2 }.skip(1).expectNext([CollectionChangeset(collection: [2, 4, 6, 8], inserts: [3], deletes: [], updates: [])])
    collection.append(4)
  }

  func testArrayMapInsert() {
    collection.map { $0 * 2 }.skip(1).expectNext([CollectionChangeset(collection: [20, 2, 4, 6], inserts: [0], deletes: [], updates: [])])
    collection.insert(10, atIndex: 0)
  }

  func testArrayMapRemoveLast() {
    collection.map { $0 * 2 }.skip(1).expectNext([CollectionChangeset(collection: [2, 4], inserts: [], deletes: [2], updates: [])])
    collection.removeLast()
  }

  func testArrayMapRemoveAtindex() {
    collection.map { $0 * 2 }.skip(1).expectNext([CollectionChangeset(collection: [2, 6], inserts: [], deletes: [1], updates: [])])
    collection.removeAtIndex(1)
  }

  func testArrayMapUpdate() {
    collection.map { $0 * 2 }.skip(1).expectNext([CollectionChangeset(collection: [2, 40, 6], inserts: [], deletes: [], updates: [1])])
    collection[1] = 20
  }


  func testArraySortAppendHighest() {
    collection.sort(>).skip(1).expectNext([CollectionChangeset(collection: [4, 3, 2, 1], inserts: [0], deletes: [], updates: [])])
    collection.append(4)
  }

  func testArraySortAppendLowest() {
    collection.sort(>).skip(1).expectNext([CollectionChangeset(collection: [3, 2, 1, 0], inserts: [3], deletes: [], updates: [])])
    collection.append(0)
  }

  func testArraySortInsertHighest() {
    collection.sort(>).skip(1).expectNext([CollectionChangeset(collection: [4, 3, 2, 1], inserts: [0], deletes: [], updates: [])])
    collection.insert(4, atIndex: 1)
  }

  func testArraySortInsertLowest() {
    collection.sort(>).skip(1).expectNext([CollectionChangeset(collection: [3, 2, 1, 0], inserts: [3], deletes: [], updates: [])])
    collection.insert(0, atIndex: 1)
  }

  func testArraySortRemoveHighest() {
    collection.sort(>).skip(1).expectNext([CollectionChangeset(collection: [2, 1], inserts: [], deletes: [0], updates: [])])
    collection.removeLast()
  }

  func testArraySortRemoveLowest() {
    collection.sort(>).skip(1).expectNext([CollectionChangeset(collection: [3, 2], inserts: [], deletes: [2], updates: [])])
    collection.removeAtIndex(0)
  }

  func testArraySortUpdateDoesNotChangePosition() {
    collection.sort(>).skip(1).expectNext([CollectionChangeset(collection: [3, 2, 0], inserts: [], deletes: [], updates: [2])])
    collection[0] = 0
  }

  func testArraySortUpdateDoesNotChangePosition2() {
    collection.sort(>).skip(1).expectNext([CollectionChangeset(collection: [4, 2, 1], inserts: [], deletes: [], updates: [0])])
    collection[2] = 4
  }

  func testArraySortUpdateMovesToFront() {
    collection.sort(>).skip(1).expectNext([CollectionChangeset(collection: [4, 3, 1], inserts: [0], deletes: [1], updates: [])])
    collection[1] = 4
  }

  func testArraySortUpdateMovesToBack() {
    collection.sort(>).skip(1).expectNext([CollectionChangeset(collection: [3, 1, 0], inserts: [2], deletes: [1], updates: [])])
    collection[1] = 0
  }


  func testArrayFilterAppendNonPassing() {
    collection.filter { $0 % 2 != 0 }.skip(1).expectNext([])
    collection.append(4)
  }

  func testArrayFilterAppendPassing() {
    collection.filter { $0 % 2 != 0 }.skip(1).expectNext([CollectionChangeset(collection: [1, 3, 5], inserts: [2], deletes: [], updates: [])])
    collection.append(5)
  }

  func testArrayFilterInsertNonPassing() {
    collection.filter { $0 % 2 != 0 }.skip(1).expectNext([])
    collection.insert(4, atIndex: 1)
  }

  func testArrayFilterInsertPassing() {
    collection.filter { $0 % 2 != 0 }.skip(1).expectNext([CollectionChangeset(collection: [1, 5, 3], inserts: [1], deletes: [], updates: [])])
    collection.insert(5, atIndex: 1)
  }

  func testArrayFilterRemovePassing() {
    collection.filter { $0 % 2 != 0 }.skip(1).expectNext([CollectionChangeset(collection: [1], inserts: [], deletes: [1], updates: [])])
    collection.removeLast()
  }

  func testArrayFilterRemoveNonPassing() {
    collection.filter { $0 % 2 != 0 }.skip(1).expectNext([])
    collection.removeAtIndex(1)
  }

  func testArrayFilterUpdateNonPassingToNonPassing() {
    collection.filter { $0 % 2 != 0 }.skip(1).expectNext([])
    collection[1] = 4
  }

  func testArrayFilterUpdateNonPassingToPassing() {
    collection.filter { $0 % 2 != 0 }.skip(1).expectNext([CollectionChangeset(collection: [1, 5, 3], inserts: [1], deletes: [], updates: [])])
    collection[1] = 5
  }

  func testArrayFilterUpdatePassingToPassing() {
    collection.filter { $0 % 2 != 0 }.skip(1).expectNext([CollectionChangeset(collection: [1, 5], inserts: [], deletes: [], updates: [1])])
    collection[2] = 5
  }

  func testArrayFilterUpdatePassingToNonPassing() {
    collection.filter { $0 % 2 != 0 }.skip(1).expectNext([CollectionChangeset(collection: [1], inserts: [], deletes: [1], updates: [])])
    collection[2] = 4
  }
}

class DictionaryCollectionPropertyTests: XCTestCase {

  var collection: CollectionProperty<[String: Int]>!

  override func setUp() {
    collection = CollectionProperty(["A": 1, "B": 2, "C": 3])
  }

  func testArraySortInsertHighest() {
    collection.sort { $0.1 < $1.1 }.skip(1).expectNext([CollectionChangeset(collection: [("A", 1), ("B", 2), ("C", 3), ("X", 4)], inserts: [3], deletes: [], updates: [])])
    collection["X"] = 4
  }

  func testArraySortInsertLowest() {
    collection.sort { $0.1 < $1.1 }.skip(1).expectNext([CollectionChangeset(collection: [("X", 0), ("A", 1), ("B", 2), ("C", 3)], inserts: [0], deletes: [], updates: [])])
    collection["X"] = 0
  }

  func testArraySortRemoveHighest() {
    collection.sort { $0.1 < $1.1 }.skip(1).expectNext([CollectionChangeset(collection: [("A", 1), ("B", 2)], inserts: [], deletes: [2], updates: [])])
    collection["C"] = nil
  }

  func testArraySortRemoveLowest() {
    collection.sort { $0.1 < $1.1 }.skip(1).expectNext([CollectionChangeset(collection: [("B", 2), ("C", 3)], inserts: [], deletes: [0], updates: [])])
    collection["A"] = nil
  }

  func testArraySortUpdateDoesNotChangePosition() {
    collection.sort { $0.1 < $1.1 }.skip(1).expectNext([CollectionChangeset(collection: [("A", 0), ("B", 2), ("C", 3)], inserts: [], deletes: [], updates: [0])])
    collection["A"] = 0
  }

  func testArraySortUpdateDoesNotChangePosition2() {
    collection.sort { $0.1 < $1.1 }.skip(1).expectNext([CollectionChangeset(collection: [("A", 1), ("B", 2), ("C", 4)], inserts: [], deletes: [], updates: [2])])
    collection["C"] = 4
  }

  func testArraySortUpdateMovesToFront() {
    collection.sort { $0.1 < $1.1 }.skip(1).expectNext([CollectionChangeset(collection: [("B", 0), ("A", 1), ("C", 3)], inserts: [0], deletes: [1], updates: [])])
    collection["B"] = 0
  }

  func testArraySortUpdateMovesToBack() {
    collection.sort { $0.1 < $1.1 }.skip(1).expectNext([CollectionChangeset(collection: [("A", 1), ("C", 3), ("B", 4)], inserts: [2], deletes: [1], updates: [])])
    collection["B"] = 4
  }
}
