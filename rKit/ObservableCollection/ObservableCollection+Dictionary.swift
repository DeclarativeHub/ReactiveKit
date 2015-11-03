//
//  ObservableDictionary.swift
//  Collections
//
//  Created by Srdan Rasic on 20/10/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

public protocol DictionaryIndexType {
  typealias Key: Hashable
  typealias Value
  func successor() -> DictionaryIndex<Key, Value>
}

extension DictionaryIndex: DictionaryIndexType {}

extension ObservableCollectionType where Index: DictionaryIndexType, Collection == Dictionary<Index.Key, Index.Value> {
  
  public func indexForKey(key: Index.Key) -> Collection.Index? {
    return collection.indexForKey(key)
  }
  
  public subscript (key: Index.Key) -> Index.Value? {
    get {
      return collection[key]
    }
    set {
      if let value = newValue {
        updateValue(value, forKey: key)
      } else {
        removeValueForKey(key)
      }
    }
  }

  public subscript (position: Collection.Index) -> Collection.Generator.Element {
    get {
      return collection[position]
    }
  }

  public mutating func updateValue(value: Index.Value, forKey key: Index.Key) -> Index.Value? {
    var new = collection
    if let index = new.indexForKey(key) {
      let oldValue = new.updateValue(value, forKey: key)
      dispatch(ObservableCollectionEvent(collection: new, inserts: [], deletes: [], updates: [index]))
      return oldValue
    } else {
      new.updateValue(value, forKey: key)
      let index = new.indexForKey(key)!
      dispatch(ObservableCollectionEvent(collection: new, inserts: [index], deletes: [], updates: []))
      return nil
    }
  }

  public mutating func removeValueForKey(key: Index.Key) -> Index.Value? {
    if let index = collection.indexForKey(key) {
      var new = collection
      let oldValue = new.removeValueForKey(key)
      dispatch(ObservableCollectionEvent(collection: new, inserts: [], deletes: [index], updates: []))
      return oldValue
    } else {
      return nil
    }
  }
}

