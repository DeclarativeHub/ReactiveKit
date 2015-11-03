//
//  ObservableArray.swift
//  Collections
//
//  Created by Srdan Rasic on 20/10/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

public extension ObservableCollectionType where Collection == Array<Generator.Element> {
  
  public mutating func append(x: Collection.Generator.Element) {
    var new = collection
    new.append(x)
    dispatch(ObservableCollectionEvent(collection: new, inserts: [collection.count], deletes: [], updates: []))
  }
  
  public mutating func insertContentsOf(newElements: [Collection.Generator.Element], at index: Collection.Index) {
    var new = collection
    new.insertContentsOf(newElements, at: index)
    dispatch(ObservableCollectionEvent(collection: new, inserts: Array(index..<index+newElements.count), deletes: [], updates: []))
  }
  
  public subscript(index: Collection.Index) -> Collection.Generator.Element {
    get {
      return self[index]
    }
    set {
      var new = collection
      new[index] = newValue
      dispatch(ObservableCollectionEvent(collection: new, inserts: [], deletes: [], updates: [index]))
    }
  }
}
