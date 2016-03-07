//
//  ReactiveKitTests.swift
//  ReactiveKitTests
//
//  Created by Srdan Rasic on 05/11/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

import Quick
import Nimble
@testable import ReactiveKit

class StreamSpec: QuickSpec {
  
  override func spec() {
    
    describe("a stream") {
      var stream: Stream<Int>!
      var simpleDisposable: SimpleDisposable!
      
      beforeEach {
        stream = create { observer in
          observer(1)
          observer(2)
          observer(3)
          simpleDisposable = SimpleDisposable()
          return simpleDisposable
        }
      }
      
      context("when observed") {
        var observedEvents: [Int] = []
        var disposable: DisposableType!
        
        beforeEach {
          disposable = stream.observe(on: ImmediateExecutionContext) {
            observedEvents.append($0)
          }
        }
        
        it("generates event") {
          expect(observedEvents) == [1, 2, 3]
        }
        
        describe("can be disposed") {
          beforeEach {
            disposable.dispose()
          }
          
          it("is disposed") {
            expect(simpleDisposable.isDisposed).to(beTrue())
          }
        }
      }
      
      context("when mapped") {
        var observedEvents: [Int] = []
        var disposable: DisposableType!
        
        beforeEach {
          disposable = stream.map { $0 * 2 }.observe(on: ImmediateExecutionContext) {
            observedEvents.append($0)
          }
        }
        
        it("generates mapped event") {
          expect(observedEvents) == [2, 4, 6]
        }
        
        describe("can be disposed") {
          beforeEach {
            disposable.dispose()
          }
          
          it("is disposed") {
            expect(simpleDisposable.isDisposed).to(beTrue())
          }
        }
      }
      
      context("when filtered") {
        var observedEvents: [Int] = []
        var disposable: DisposableType!
        
        beforeEach {
          disposable = stream.filter { $0 % 2 == 0 }.observe(on: ImmediateExecutionContext) {
            observedEvents.append($0)
          }
        }
        
        it("generates filtered event") {
          expect(observedEvents) == [2]
        }
        
        describe("can be disposed") {
          beforeEach {
            disposable.dispose()
          }
          
          it("is disposed") {
            expect(simpleDisposable.isDisposed).to(beTrue())
          }
        }
      }
      
      context("when switchTo another context") {
        var contextUsed = false
        var disposable: DisposableType!
        
        beforeEach {
          disposable = stream.switchTo { body in
              contextUsed = true
              body()
            }.observe(on: ImmediateExecutionContext) { _ in }
        }
        
        it("uses that context") {
          expect(contextUsed).to(beTrue())
        }
        
        describe("can be disposed") {
          beforeEach {
            disposable.dispose()
          }
          
          it("is disposed") {
            expect(simpleDisposable.isDisposed).to(beTrue())
          }
        }
      }
      
      context("when zipPrevious event") {
        var observedEvents: [(Int?, Int)] = []
        var disposable: DisposableType!
        
        beforeEach {
          disposable = stream.zipPrevious().observe(on: ImmediateExecutionContext) {
            observedEvents.append($0)
          }
        }
        
        it("generates zipped event") {
          expect(observedEvents[0].0).to(beNil())
          expect(observedEvents[0].1) == 1
          expect(observedEvents[1].0) == 1
          expect(observedEvents[1].1) == 2
          expect(observedEvents[2].0) == 2
          expect(observedEvents[2].1) == 3
        }
        
        describe("can be disposed") {
          beforeEach {
            disposable.dispose()
          }
          
          it("is disposed") {
            expect(simpleDisposable.isDisposed).to(beTrue())
          }
        }
      }
      
      context("when throttle by 0.1") {
        var observedEvents: [Int] = []
        var disposable: DisposableType!
        
        beforeEach {
          disposable = stream.throttle(0.1, on: Queue.main).observe(on: ImmediateExecutionContext) {
            observedEvents.append($0)
          }
        }
        
        it("does throttle") {
          expect(observedEvents) == []
          expect(observedEvents).toEventually(equal([3]))
        }
        
        describe("can be disposed") {
          beforeEach {
            disposable.dispose()
          }
          
          it("is disposed") {
            expect(simpleDisposable.isDisposed).to(beTrue())
          }
        }
      }
        
      context("when taking 0") {
        var observedEvents: [Int] = []
        var disposable: DisposableType!
        
        beforeEach {
          disposable = stream.take(0).observe(on: ImmediateExecutionContext) {
            observedEvents.append($0)
          }
        }
        
        it("does takes nothing") {
          expect(observedEvents) == []
        }
        
        describe("can be disposed") {
          beforeEach {
            disposable.dispose()
          }
          
          it("is disposed") {
            expect(simpleDisposable.isDisposed).to(beTrue())
          }
        }
      }
        
      context("when taking 1") {
        var observedEvents: [Int] = []
        var disposable: DisposableType!
        
        beforeEach {
          disposable = stream.take(1).observe(on: ImmediateExecutionContext) {
            observedEvents.append($0)
          }
        }
        
        it("does take only 1") {
          expect(observedEvents) == [1]
        }
        
        describe("can be disposed") {
          beforeEach {
            disposable.dispose()
          }
          
          it("is disposed") {
            expect(simpleDisposable.isDisposed).to(beTrue())
          }
        }
      }
        
      context("when taking 2") {
        var observedEvents: [Int] = []
        var disposable: DisposableType!
        
        beforeEach {
          disposable = stream.take(2).observe(on: ImmediateExecutionContext) {
            observedEvents.append($0)
          }
        }
        
        it("does takes 1 and 2") {
          expect(observedEvents) == [1,2]
        }
        
        describe("can be disposed") {
          beforeEach {
            disposable.dispose()
          }
          
          it("is disposed") {
            expect(simpleDisposable.isDisposed).to(beTrue())
          }
        }
      }
      
      context("when skip by 1") {
        var observedEvents: [Int] = []
        var disposable: DisposableType!
        
        beforeEach {
          disposable = stream.skip(1).observe(on: ImmediateExecutionContext) {
            observedEvents.append($0)
          }
        }
        
        it("does skip 1") {
          expect(observedEvents) == [2, 3]
        }
        
        describe("can be disposed") {
          beforeEach {
            disposable.dispose()
          }
          
          it("is disposed") {
            expect(simpleDisposable.isDisposed).to(beTrue())
          }
        }
      }
      
      context("when startWith 9") {
        var observedEvents: [Int] = []
        var disposable: DisposableType!
        
        beforeEach {
          disposable = stream.startWith(9).observe(on: ImmediateExecutionContext) {
            observedEvents.append($0)
          }
        }
        
        it("does startWith 9") {
          expect(observedEvents) == [9, 1, 2, 3]
        }
        
        describe("can be disposed") {
          beforeEach {
            disposable.dispose()
          }
          
          it("is disposed") {
            expect(simpleDisposable.isDisposed).to(beTrue())
          }
        }
      }
      
      context("when combineLatestWith") {
        var observedEvents: [(Int, Int)] = []
        var disposable: DisposableType!
        let otherSimpleDisposable = SimpleDisposable()
        
        beforeEach {
          let otherStream: Stream<Int> = create { observer in
            observer(10)
            observer(20)
            return otherSimpleDisposable
          }
          
          disposable = stream.combineLatestWith(otherStream).observe(on: ImmediateExecutionContext) {
            observedEvents.append($0)
          }
        }
        
        it("does combine") {
          expect(observedEvents[0].0) == 3
          expect(observedEvents[0].1) == 10
          expect(observedEvents[1].0) == 3
          expect(observedEvents[1].1) == 20
        }
        
        describe("can be disposed") {
          beforeEach {
            disposable.dispose()
          }
          
          it("is disposed") {
            expect(simpleDisposable.isDisposed).to(beTrue())
          }
          
          it("other is disposed") {
            expect(otherSimpleDisposable.isDisposed).to(beTrue())
          }
        }
      }
      
      context("when zipWith") {
        var observedEvents: [(Int, Int)] = []
        var disposable: DisposableType!
        let otherSimpleDisposable = SimpleDisposable()
        
        beforeEach {
          let otherStream: Stream<Int> = create { observer in
            observer(10)
            observer(20)
            observer(30)
            observer(40)
            return otherSimpleDisposable
          }
          
          disposable = stream.zipWith(otherStream).observe(on: ImmediateExecutionContext) {
            observedEvents.append($0)
          }
        }
        
        it("does zip") {
          expect(observedEvents[0].0) == 1
          expect(observedEvents[0].1) == 10
          expect(observedEvents[1].0) == 2
          expect(observedEvents[1].1) == 20
          expect(observedEvents[2].0) == 3
          expect(observedEvents[2].1) == 30
          expect(observedEvents.count) == 3
        }
        
        describe("can be disposed") {
          beforeEach {
            disposable.dispose()
          }
          
          it("is disposed") {
            expect(simpleDisposable.isDisposed).to(beTrue())
          }
          
          it("other is disposed") {
            expect(otherSimpleDisposable.isDisposed).to(beTrue())
          }
        }
      }
      
      context("when merge") {
        var observedEvents: [Int] = []
        var disposable: DisposableType!
        let otherSimpleDisposables = [SimpleDisposable(), SimpleDisposable(), SimpleDisposable()]
        
        beforeEach {
          disposable = stream.flatMap(.Merge) { n in
             Stream<Int> { observer in
                observer(n * 2)
                return otherSimpleDisposables[n-1]
              }
            }.observe(on: ImmediateExecutionContext) {
            observedEvents.append($0)
          }
        }
        
        it("does combine") {
          expect(observedEvents) == [2, 4, 6]
        }
        
        describe("can be disposed") {
          beforeEach {
            disposable.dispose()
          }
          
          it("is disposed") {
            expect(simpleDisposable.isDisposed).to(beTrue())
          }
          
          it("others are disposed") {
            expect(otherSimpleDisposables[0].isDisposed).to(beTrue())
            expect(otherSimpleDisposables[1].isDisposed).to(beTrue())
            expect(otherSimpleDisposables[2].isDisposed).to(beTrue())
          }
        }
      }
      
      context("when switchToLatest") {
        var observedEvents: [Int] = []
        var disposable: DisposableType!
        let otherSimpleDisposables = [SimpleDisposable(), SimpleDisposable(), SimpleDisposable()]
        
        beforeEach {
          disposable = stream.flatMap(.Latest) { n in
            Stream<Int> { observer in
              observer(n * 2)
              return otherSimpleDisposables[n-1]
            }
            }.observe(on: ImmediateExecutionContext) {
              observedEvents.append($0)
          }
        }
        
        it("does switch") {
          expect(observedEvents) == [2, 4, 6]
        }
        
        describe("can be disposed") {
          beforeEach {
            disposable.dispose()
          }
          
          it("is disposed") {
            expect(simpleDisposable.isDisposed).to(beTrue())
          }
          
          it("others are disposed") {
            expect(otherSimpleDisposables[0].isDisposed).to(beTrue())
            expect(otherSimpleDisposables[1].isDisposed).to(beTrue())
            expect(otherSimpleDisposables[2].isDisposed).to(beTrue())
          }
        }
      }
    }
  }
}


