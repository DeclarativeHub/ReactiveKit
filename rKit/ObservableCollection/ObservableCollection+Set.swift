//
//  ObservableSet.swift
//  Collections
//
//  Created by Srdan Rasic on 20/10/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

extension ObservableCollectionType where Generator.Element: Hashable, Collection == Set<Generator.Element> {
  
  public func contains(member: Collection.Generator.Element) -> Bool {
    return collection.contains(member)
  }
  
  public func indexOf(member: Collection.Generator.Element) -> SetIndex<Collection.Generator.Element>? {
    return collection.indexOf(member)
  }
  
  public subscript (position: SetIndex<Collection.Generator.Element>) -> Collection.Generator.Element {
    get {
      return collection[position]
    }
  }
  
  public mutating func insert(member: Collection.Generator.Element) {
    var new  = collection
    new.insert(member)
    
    if let index = collection.indexOf(member) {
      dispatch(ObservableCollectionEvent(collection: new, inserts: [], deletes: [], updates: [index]))
    } else {
      dispatch(ObservableCollectionEvent(collection: new, inserts: [new.indexOf(member)!], deletes: [], updates: []))
    }
  }
  
  public mutating func remove(member: Collection.Generator.Element) -> Collection.Generator.Element? {
    var new = collection
    
    if let index = collection.indexOf(member) {
      let old = new.removeAtIndex(index)
      dispatch(ObservableCollectionEvent(collection: new, inserts: [], deletes: [index], updates: []))
      return old
    } else {
      return nil
    }
  }
}
