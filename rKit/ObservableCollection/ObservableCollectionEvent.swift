//
//  ObservableCollectionEvent.swift
//  Collections
//
//  Created by Srdan Rasic on 20/10/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

public protocol ObservableCollectionEventType {
  typealias Collection: CollectionType
  
  var collection: Collection { get }
  
  var inserts: [Collection.Index] { get }
  var deletes: [Collection.Index] { get }
  var updates: [Collection.Index] { get }
}

public struct ObservableCollectionEvent<Collection: CollectionType>: ObservableCollectionEventType {
  public let collection: Collection

  public let inserts: [Collection.Index]
  public let deletes: [Collection.Index]
  public let updates: [Collection.Index]
  
  public static func initial(collection: Collection) -> ObservableCollectionEvent<Collection> {
    return ObservableCollectionEvent(collection: collection, inserts: [], deletes: [], updates: [])
  }
}

public extension ObservableCollectionEvent {
  public init<CE: ObservableCollectionEventType where CE.Collection == Collection>(ObservableCollectionEvent: CE) {
    collection = ObservableCollectionEvent.collection
    inserts = ObservableCollectionEvent.inserts
    deletes = ObservableCollectionEvent.deletes
    updates = ObservableCollectionEvent.updates
  }
}

public extension ObservableCollectionEventType where Collection.Index == Int {
  
  /// O(n)
  public func map<U>(transform: Collection.Generator.Element -> U) -> ObservableCollectionEvent<Array<U>> {
    return ObservableCollectionEvent(collection: collection.map(transform), inserts: inserts, deletes: deletes, updates: updates)
  }
}

public extension ObservableCollectionEventType where Collection.Index == Int {
  
  /// O(n)
  public func filter(include: Collection.Generator.Element -> Bool) -> ObservableCollectionEvent<Array<Collection.Generator.Element>> {
    
    let filteredPairs = zip(collection.indices, collection).filter { include($0.1) }
    let includedIndices = Set(filteredPairs.map { $0.0 })
    
    let filteredCollection = filteredPairs.map { $0.1 }
    let filteredInserts = inserts.filter { includedIndices.contains($0) }
    let filteredDeletes = deletes.filter { includedIndices.contains($0) }
    let filteredUpdates = updates.filter { includedIndices.contains($0) }
    
    return ObservableCollectionEvent(collection: filteredCollection, inserts: filteredInserts, deletes: filteredDeletes, updates: filteredUpdates)
  }
}

public extension ObservableCollectionEventType where Collection.Index: Hashable {
  
  /// O(n*logn)
  public func sort(isOrderedBefore: (Collection.Generator.Element, Collection.Generator.Element) -> Bool) -> ObservableCollectionEvent<Array<Collection.Generator.Element>> {
    let sortedPairs = zip(collection.indices, collection).sort { isOrderedBefore($0.1, $1.1) }
    
    var sortMap: [Collection.Index: Int] = [:]
    for (index, pair) in sortedPairs.enumerate() {
      sortMap[pair.0] = index
    }
    
    let sortedCollection = sortedPairs.map { $0.1 }
    let newInserts = inserts.map { sortMap[$0]! }
    let newDeletes = deletes.map { sortMap[$0]! }
    let newUpdates = updates.map { sortMap[$0]! }
    
    return ObservableCollectionEvent(collection: sortedCollection, inserts: newInserts, deletes: newDeletes, updates: newUpdates)
  }
}

public extension ObservableCollectionEventType where Collection.Index: Equatable {
  
  /// O(n^2)
  public func sort(isOrderedBefore: (Collection.Generator.Element, Collection.Generator.Element) -> Bool) -> ObservableCollectionEvent<Array<Collection.Generator.Element>> {
    let sortedPairs = zip(collection.indices, collection).sort { isOrderedBefore($0.1, $1.1) }
    let sortedIndices = sortedPairs.map { $0.0 }
    
    let newInserts = inserts.map { sortedIndices.indexOf($0)! }
    let newDeletes = deletes.map { sortedIndices.indexOf($0)! }
    let newUpdates = updates.map { sortedIndices.indexOf($0)! }
    
    let sortedCollection = sortedPairs.map { $0.1 }
    
    return ObservableCollectionEvent(collection: sortedCollection, inserts: newInserts, deletes: newDeletes, updates: newUpdates)
  }
}
