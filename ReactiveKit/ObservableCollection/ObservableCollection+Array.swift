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

  /// Append `newElement` to the array.
  public func append(newElement: Collection.Generator.Element) {
    var new = collection
    new.append(newElement)
    next(ObservableCollectionEvent(collection: new, inserts: [collection.count], deletes: [], updates: []))
  }

  /// Insert `newElement` at index `i`.
  public func insert(newElement: Collection.Generator.Element, atIndex: Int)  {
    var new = collection
    new.insert(newElement, atIndex: atIndex)
    next(ObservableCollectionEvent(collection: new, inserts: [atIndex], deletes: [], updates: []))
  }

  /// Insert elements `newElements` at index `i`.
  public func insertContentsOf(newElements: [Collection.Generator.Element], at index: Collection.Index) {
    var new = collection
    new.insertContentsOf(newElements, at: index)
    next(ObservableCollectionEvent(collection: new, inserts: Array(index..<index+newElements.count), deletes: [], updates: []))
  }
  
  /// Move the element at index `i` to index `toIndex`.
  public mutating func moveItemAtIndex(fromIndex: Int, toIndex: Int) {
    let item = collection[fromIndex]
    var new = collection
    new.removeAtIndex(fromIndex)
    new.insert(item, atIndex: toIndex)
    let updates = Array(min(fromIndex, toIndex)...max(fromIndex, toIndex))
    next(ObservableCollectionEvent(collection: new, inserts: [], deletes: [], updates: updates))
  }

  /// Remove and return the element at index i.
  public func removeAtIndex(index: Int) -> Collection.Generator.Element {
    var new = collection
    let element = new.removeAtIndex(index)
    next(ObservableCollectionEvent(collection: new, inserts: [], deletes: [index], updates: []))
    return element
  }

  /// Remove an element from the end of the array in O(1).
  public func removeLast() -> Collection.Generator.Element {
    var new = collection
    let element = new.removeLast()
    next(ObservableCollectionEvent(collection: new, inserts: [], deletes: [new.count], updates: []))
    return element
  }

  /// Remove all elements from the array.
  public func removeAll() {
    let deletes = Array(0..<collection.count)
    next(ObservableCollectionEvent(collection: [], inserts: [], deletes: deletes, updates: []))
  }

  public subscript(index: Collection.Index) -> Collection.Generator.Element {
    get {
      return collection[index]
    }
    set {
      var new = collection
      new[index] = newValue
      next(ObservableCollectionEvent(collection: new, inserts: [], deletes: [], updates: [index]))
    }
  }
}

extension ObservableCollectionType where Collection == Array<Element>, Element: Equatable, Index == Int {

  /// Replace current array with the new array and send change events.
  /// 
  /// - Parameters: 
  ///     - newCollection: The array to replace current array with.
  ///     - performDiff: When `true`, difference between the current array and the new array will be calculated
  ///         and the sent event will contain exact description of which elements were inserted and which deleted.\n
  ///         When `false`, the sent event contains current array indices as `deletes` indices and new array indices as
  ///         `insertes` indices.
  ///
  /// - Complexity: O(1) if `performDiff == false`. Otherwise O(`collection.count * newCollection.count`).
  public func replace(newCollection: Collection, performDiff: Bool) {
    if performDiff {
      var inserts: [Int] = []
      var deletes: [Int] = []

      inserts.reserveCapacity(collection.count)
      deletes.reserveCapacity(collection.count)

      let diff = Collection.diff(collection, newCollection)

      for diffStep in diff {
        switch diffStep {
        case .Insert(_, let index): inserts.append(index)
        case .Delete(_, let index): deletes.append(index)
        }
      }

      next(ObservableCollectionEvent(collection: newCollection, inserts: inserts, deletes: deletes, updates: []))
    } else {
      replace(newCollection)
    }
  }
}
