//
//  ObservableCollectionSpec.swift
//  ReactiveKit
//
//  Created by Srdan Rasic on 22/11/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

import Quick
import Nimble
@testable import ReactiveKit

class ObservableCollectionSpec: QuickSpec {

  override func spec() {

    // MARK: - Array

    describe("ObservableCollection<Array<T>>") {
      var observableCollection: ObservableCollection<[Int]>!

      beforeEach {
        observableCollection = ObservableCollection([1, 2, 3])
      }

      context("when observed") {
        var observedEvents: [ObservableCollectionEvent<[Int]>] = []

        beforeEach {
          observedEvents = []
          observableCollection.observe(on: ImmediateExecutionContext) {
            observedEvents.append($0)
          }
        }

        it("generates initial event") {
          expect(observedEvents[0]).to(equal(ObservableCollectionEvent(collection: [1, 2, 3], inserts: [], deletes: [], updates: [])))
        }

        describe("append") {
          beforeEach {
            observableCollection.append(4)
          }

          it("appends") {
            expect(observedEvents[1]).to(equal(ObservableCollectionEvent(collection: [1, 2, 3, 4], inserts: [3], deletes: [], updates: [])))
          }
        }

        describe("insert") {
          beforeEach {
            observableCollection.insert(0, atIndex: 0)
          }

          it("inserts") {
            expect(observedEvents[1]).to(equal(ObservableCollectionEvent(collection: [0, 1, 2, 3], inserts: [0], deletes: [], updates: [])))
          }
        }

        describe("insertContentsOf") {
          beforeEach {
            observableCollection.insertContentsOf([10, 11], at: 1)
          }

          it("insertContentsOf") {
            expect(observedEvents[1]).to(equal(ObservableCollectionEvent(collection: [1, 10, 11, 2, 3], inserts: [1, 2], deletes: [], updates: [])))
          }
        }

        describe("removeAtIndex") {
          beforeEach {
            observableCollection.removeAtIndex(1)
          }

          it("removeAtIndex") {
            expect(observedEvents[1]).to(equal(ObservableCollectionEvent(collection: [1, 3], inserts: [], deletes: [1], updates: [])))
          }
        }

        describe("removeLast") {
          beforeEach {
            observableCollection.removeLast()
          }

          it("removeLast") {
            expect(observedEvents[1]).to(equal(ObservableCollectionEvent(collection: [1, 2], inserts: [], deletes: [2], updates: [])))
          }
        }

        describe("removeAll") {
          beforeEach {
            observableCollection.removeAll()
          }

          it("removeAll") {
            expect(observedEvents[1]).to(equal(ObservableCollectionEvent(collection: [], inserts: [], deletes: [0, 1, 2], updates: [])))
          }
        }

        describe("subscript") {
          beforeEach {
            observableCollection[1] = 20
          }

          it("subscript") {
            expect(observableCollection[1]) == 20
            expect(observedEvents[1]).to(equal(ObservableCollectionEvent(collection: [1, 20, 3], inserts: [], deletes: [], updates: [1])))
          }
        }

        describe("replace-diff") {
          beforeEach {
            observableCollection.replace([0, 1, 3, 4], performDiff: true)
          }

          it("sends right events") {
            expect(observedEvents[1]).to(equal(ObservableCollectionEvent(collection: [0, 1, 3, 4], inserts: [0, 3], deletes: [1], updates: [])))
          }
        }
      }
    }

    // MARK: - Set

    describe("ObservableCollection<Set<T>>") {
      var observableCollection: ObservableCollection<Set<Int>>!

      beforeEach {
        observableCollection = ObservableCollection([1, 2, 3])
      }

      context("when observed") {
        var observedEvents: [ObservableCollectionEvent<Set<Int>>] = []

        beforeEach {
          observedEvents = []
          observableCollection.observe(on: ImmediateExecutionContext) {
            observedEvents.append($0)
          }
        }

        it("generates initial event") {
          expect(observedEvents[0]).to(equal(ObservableCollectionEvent(collection: [1, 2, 3], inserts: [], deletes: [], updates: [])))
        }

        describe("contains") {
          it("contains") {
            expect(observableCollection.contains(1)) == true
            expect(observableCollection.contains(5)) == false
          }
        }

        describe("insert") {
          beforeEach {
            observableCollection.insert(0)
          }

          it("inserts") {
            expect(observedEvents[1].collection).to(contain(0))
          }
        }

        describe("remove") {
          beforeEach {
            observableCollection.remove(1)
          }

          it("remove") {
            expect(observedEvents[1].collection).toNot(contain(0))
          }
        }
      }
    }
  }
}

// MARK: - Helpers

public func equal<C: CollectionType where C.Generator.Element: Equatable>(expectedValue: ObservableCollectionEvent<C>) -> MatcherFunc<ObservableCollectionEvent<C>> {
  return MatcherFunc { actualExpression, failureMessage in
    failureMessage.postfixMessage = "equal <\(expectedValue)>"
    return try! actualExpression.evaluate()! == expectedValue
  }
}


func == <C: CollectionType where C.Generator.Element: Equatable, C.Index: Equatable>(left: ObservableCollectionEvent<C>, right: ObservableCollectionEvent<C>) -> Bool {
  return left.collection == right.collection && left.inserts == right.inserts && left.updates == right.updates && left.deletes == right.deletes
}

func == <C: CollectionType where C.Generator.Element: Equatable>(left: C, right: C) -> Bool {
  guard left.count == right.count else { return false }
  for (l, r) in zip(left, right) {
    if l != r {
      return false
    }
  }
  return true
}

