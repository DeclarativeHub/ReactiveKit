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

extension ObservableCollectionType where Collection == Array<Element> {
  
  public mutating func append(x: Collection.Generator.Element) {
    var new = collection
    new.append(x)
    dispatch(ObservableCollectionEvent(collection: new, inserts: [collection.count], deletes: [], updates: []))
  }
  
  public mutating func insert(newElement: Collection.Generator.Element, atIndex: Int)  {
    var new = collection
    new.insert(newElement, atIndex: atIndex)
    dispatch(ObservableCollectionEvent(collection: new, inserts: [atIndex], deletes: [], updates: []))
  }
  
  public mutating func insertContentsOf(newElements: [Collection.Generator.Element], at index: Collection.Index) {
    var new = collection
    new.insertContentsOf(newElements, at: index)
    dispatch(ObservableCollectionEvent(collection: new, inserts: Array(index..<index+newElements.count), deletes: [], updates: []))
  }
  
  public mutating func replace(withElements: [Collection.Generator.Element]) {
    let deletes = Array(0..<collection.count)
    let inserts = Array(0..<withElements.count)
    dispatch(ObservableCollectionEvent(collection: withElements, inserts: inserts, deletes: deletes, updates: []))
  }
  
  public mutating func removeAtIndex(index: Int) -> Collection.Generator.Element {
    var new = collection
    let element = new.removeAtIndex(index)
    dispatch(ObservableCollectionEvent(collection: new, inserts: [], deletes: [index], updates: []))
    return element
  }
  
  public mutating func removeLast() -> Collection.Generator.Element {
    var new = collection
    let element = new.removeLast()
    dispatch(ObservableCollectionEvent(collection: new, inserts: [], deletes: [new.count], updates: []))
    return element
  }
  
  public mutating func removeAll() {
    let deletes = Array(0..<collection.count)
    dispatch(ObservableCollectionEvent(collection: [], inserts: [], deletes: deletes, updates: []))
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
