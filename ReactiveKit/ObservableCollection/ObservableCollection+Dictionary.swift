//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Srdan Rasic (@srdanrasic)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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

  public func updateValue(value: Index.Value, forKey key: Index.Key) -> Index.Value? {
    var new = collection
    if let index = new.indexForKey(key) {
      let oldValue = new.updateValue(value, forKey: key)
      next(ObservableCollectionEvent(collection: new, inserts: [], deletes: [], updates: [index]))
      return oldValue
    } else {
      new.updateValue(value, forKey: key)
      let index = new.indexForKey(key)!
      next(ObservableCollectionEvent(collection: new, inserts: [index], deletes: [], updates: []))
      return nil
    }
  }

  public func removeValueForKey(key: Index.Key) -> Index.Value? {
    if let index = collection.indexForKey(key) {
      var new = collection
      let oldValue = new.removeValueForKey(key)
      next(ObservableCollectionEvent(collection: new, inserts: [], deletes: [index], updates: []))
      return oldValue
    } else {
      return nil
    }
  }
}

