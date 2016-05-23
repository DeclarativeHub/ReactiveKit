//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Srdan Rasic (@srdanrasic)
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

public protocol CollectionChangesetType {
  associatedtype Collection: CollectionType
  var collection: Collection { get }
  var inserts: [Collection.Index] { get }
  var deletes: [Collection.Index] { get }
  var updates: [Collection.Index] { get }
}

public struct CollectionChangeset<Collection: CollectionType>: CollectionChangesetType {
  public let collection: Collection
  public let inserts: [Collection.Index]
  public let deletes: [Collection.Index]
  public let updates: [Collection.Index]

  public static func initial(collection: Collection) -> CollectionChangeset<Collection> {
    return CollectionChangeset(collection: collection, inserts: [], deletes: [], updates: [])
  }

  public init(collection: Collection, inserts: [Collection.Index], deletes: [Collection.Index], updates: [Collection.Index]) {
    self.collection = collection
    self.inserts = inserts
    self.deletes = deletes
    self.updates = updates
  }
}

public extension CollectionChangeset {

  public init<E: CollectionChangesetType where E.Collection == Collection>(ObservableCollectionEvent: E) {
    collection = ObservableCollectionEvent.collection
    inserts = ObservableCollectionEvent.inserts
    deletes = ObservableCollectionEvent.deletes
    updates = ObservableCollectionEvent.updates
  }
}

public extension CollectionChangesetType where Collection.Index == Int {

  /// O(n)
  public func map<U>(transform: Collection.Generator.Element -> U) -> CollectionChangeset<[U]> {
    return CollectionChangeset(collection: collection.map(transform), inserts: inserts, deletes: deletes, updates: updates)
  }

  /// O(1)
  public func lazyMap<U>(transform: Collection.Generator.Element -> U) -> CollectionChangeset<LazyMapCollection<Collection, U>> {
    return CollectionChangeset(collection: collection.lazy.map(transform), inserts: inserts, deletes: deletes, updates: updates)
  }
}

public extension CollectionChangesetType where Collection.Index == Int {

  /// O(n)
  public func filter(include: Collection.Generator.Element -> Bool) -> CollectionChangeset<Array<Collection.Generator.Element>> {

    let filteredPairs = zip(collection.indices, collection).filter { include($0.1) }
    let includedIndices = Set(filteredPairs.map { $0.0 })

    let filteredCollection = filteredPairs.map { $0.1 }
    let filteredInserts = inserts.filter { includedIndices.contains($0) }
    let filteredDeletes = deletes.filter { includedIndices.contains($0) }
    let filteredUpdates = updates.filter { includedIndices.contains($0) }

    return CollectionChangeset(collection: filteredCollection, inserts: filteredInserts, deletes: filteredDeletes, updates: filteredUpdates)
  }
}

public extension CollectionChangesetType where Collection.Index: Hashable {

  typealias SortMap = [Collection.Index: Int]
  typealias Changeset = CollectionChangeset<Array<Collection.Generator.Element>>
  typealias CollectionElement = Collection.Generator.Element

  /// O(n*logn)
  public func sort(previousSortMap: SortMap?, isOrderedBefore: (CollectionElement, CollectionElement) -> Bool) -> (changeset: Changeset, sortMap: SortMap) {
    let sortedPairs = zip(collection.indices, collection).sort { isOrderedBefore($0.1, $1.1) }

    var sortMap: [Collection.Index: Int] = [:]
    for (index, pair) in sortedPairs.enumerate() {
      sortMap[pair.0] = index
    }

    let sortedCollection = sortedPairs.map { $0.1 }
    let newDeletes = deletes.map { previousSortMap![$0]! }
    let newInserts = inserts.map { sortMap[$0]! }
    let newUpdates = updates.map { sortMap[$0]! }
    let changeSet = CollectionChangeset(collection: sortedCollection, inserts: newInserts, deletes: newDeletes, updates: newUpdates)

    return (changeset: changeSet, sortMap: sortMap)
  }
}

public extension CollectionChangesetType where Collection.Index: Equatable {

  /// O(n^2)
  public func sort(previousSortedIndices: [Collection.Index]?, isOrderedBefore: (Collection.Generator.Element, Collection.Generator.Element) -> Bool) -> (changeset: CollectionChangeset<Array<Collection.Generator.Element>>, sortedIndices: [Collection.Index]) {
    let sortedPairs = zip(collection.indices, collection).sort { isOrderedBefore($0.1, $1.1) }
    let sortedIndices = sortedPairs.map { $0.0 }

    let sortedCollection = sortedPairs.map { $0.1 }
    let newDeletes = deletes.map { previousSortedIndices!.indexOf($0)! }
    let newInserts = inserts.map { sortedIndices.indexOf($0)! }
    let newUpdates = updates.map { sortedIndices.indexOf($0)! }
    let changeset = CollectionChangeset(collection: sortedCollection, inserts: newInserts, deletes: newDeletes, updates: newUpdates)

    return (changeset: changeset, sortedIndices: sortedIndices)
  }
}

public protocol CollectionPropertyType: CollectionType, StreamType, PropertyType, SubjectType {
  associatedtype Collection: CollectionType
  associatedtype Index = Collection.Index
  associatedtype Member = Collection.Generator.Element
  var collection: Collection { get }
  func observe(observer: StreamEvent<CollectionChangeset<Collection>> -> Void) -> Disposable
  func update(changeset: CollectionChangeset<Collection>)
}

public class CollectionProperty<C: CollectionType>: CollectionPropertyType {
  private let subject = PublishSubject<StreamEvent<CollectionChangeset<C>>>()
  private let lock = RecursiveLock(name: "ReactiveKit.CollectionProperty")
  private let disposeBag = DisposeBag()

  public var rawStream: RawStream<StreamEvent<CollectionChangeset<C>>> {
    return subject.toRawStream().startWith(.Next(CollectionChangeset.initial(collection)))
  }

  public private(set) var collection: C

  public var value: C {
    return collection
  }

  public init(_ collection: C) {
    self.collection = collection
  }

  deinit {
    subject.completed()
  }

  public func generate() -> C.Generator {
    return collection.generate()
  }

  public func underestimateCount() -> Int {
    return collection.underestimateCount()
  }

  public var startIndex: C.Index {
    return collection.startIndex
  }

  public var endIndex: C.Index {
    return collection.endIndex
  }

  public var isEmpty: Bool {
    return collection.isEmpty
  }

  public var count: C.Index.Distance {
    return collection.count
  }

  public subscript(index: C.Index) -> C.Generator.Element {
    get {
      return collection[index]
    }
  }

  public func silentUpdate(@noescape perform: CollectionProperty<C> -> Void) {
    let collection = CollectionProperty(self.collection)
    perform(collection)
    self.collection = collection.collection
  }

  public func update(changeset: CollectionChangeset<C>) {
    collection = changeset.collection
    subject.on(.Next(changeset))
  }

  public func on(event: StreamEvent<CollectionChangeset<C>>) {
    if let changeset = event.element {
      collection = changeset.collection
    }
    subject.on(event)
  }
}

public extension CollectionPropertyType {

  public func replace(newCollection: Collection) {
    let deletes = Array(collection.indices)
    let inserts = Array(newCollection.indices)
    update(CollectionChangeset(collection: newCollection, inserts: inserts, deletes: deletes, updates: []))
  }
}

public extension CollectionPropertyType where Collection.Index == Int {

  /// Each event costs O(n)
  @warn_unused_result
  public func map<U>(transform: Collection.Generator.Element -> U) -> Stream<CollectionChangeset<Array<U>>> {
    return Stream { observer in
      return self.observe { event in
        observer.observer(event.map { $0.map(transform) })
      }
    }
  }

  /// Each event costs O(1)
  @warn_unused_result
  public func lazyMap<U>(transform: Collection.Generator.Element -> U) -> Stream<CollectionChangeset<LazyMapCollection<Collection, U>>> {
    return Stream { observer in
      return self.observe { event in
        observer.observer(event.map { $0.lazyMap(transform) })
      }
    }
  }

  /// Each event costs O(n)
  @warn_unused_result
  public func filter(include: Collection.Generator.Element -> Bool) -> Stream<CollectionChangeset<Array<Collection.Generator.Element>>> {
    return Stream { observer in
      return self.observe { event in
        observer.observer(event.map { $0.filter(include) })
      }
    }
  }
}

public extension CollectionPropertyType where Collection.Index: Hashable {

  typealias CollectionElement = Collection.Generator.Element

  /// Each event costs O(n*logn)
  @warn_unused_result
  public func sort(isOrderedBefore: (CollectionElement, CollectionElement) -> Bool) -> Stream<CollectionChangeset<[CollectionElement]>> {
    return Stream { observer in
      var previousSortMap: [Collection.Index: Int]? = nil
      return self.observe { event in
        observer.observer(event.map { changeset in
          let (newChangeset, sortMap) = changeset.sort(previousSortMap, isOrderedBefore: isOrderedBefore)
          previousSortMap = sortMap
          return newChangeset
        })
      }
    }
  }
}

public extension CollectionPropertyType where Collection.Index: Equatable {

  /// Each event costs O(n^2)
  @warn_unused_result
  public func sort(isOrderedBefore: (Collection.Generator.Element, Collection.Generator.Element) -> Bool) -> Stream<CollectionChangeset<Array<Collection.Generator.Element>>> {
    return Stream { observer in
      var previousSortedIndices: [Collection.Index]? = nil
      return self.observe { event in
        observer.observer(event.map { changeset in
          let (newChangeset, sortedIndices) = changeset.sort(previousSortedIndices, isOrderedBefore: isOrderedBefore)
          previousSortedIndices = sortedIndices
          return newChangeset
        })
      }
    }
  }
}

// MARK: - Set Extensions

public protocol SetIndexType {
  associatedtype Element: Hashable
  func successor() -> SetIndex<Element>
}

extension SetIndex: SetIndexType {}

public extension CollectionPropertyType where Index: SetIndexType, Collection == Set<Index.Element> {

  public func contains(member: Index.Element) -> Bool {
    return collection.contains(member)
  }

  public func indexOf(member: Index.Element) -> SetIndex<Index.Element>? {
    return collection.indexOf(member)
  }

  public subscript (position: SetIndex<Index.Element>) -> Index.Element {
    get {
      return collection[position]
    }
  }
}

public extension CollectionPropertyType where Index: SetIndexType, Collection == Set<Index.Element> {

  public func insert(member: Index.Element) {
    var new = collection
    new.insert(member)

    if let index = collection.indexOf(member) {
      update(CollectionChangeset(collection: new, inserts: [], deletes: [], updates: [index]))
    } else {
      update(CollectionChangeset(collection: new, inserts: [new.indexOf(member)!], deletes: [], updates: []))
    }
  }

  public func remove(member: Index.Element) -> Index.Element? {
    var new = collection

    if let index = collection.indexOf(member) {
      let old = new.removeAtIndex(index)
      update(CollectionChangeset(collection: new, inserts: [], deletes: [index], updates: []))
      return old
    } else {
      return nil
    }
  }
}

// MARK: - Dictionary Extensions

public protocol DictionaryIndexType {
  associatedtype Key: Hashable
  associatedtype Value
  func successor() -> DictionaryIndex<Key, Value>
}

extension DictionaryIndex: DictionaryIndexType {}

public extension CollectionPropertyType where Index: DictionaryIndexType, Collection == Dictionary<Index.Key, Index.Value> {

  public func indexForKey(key: Index.Key) -> Collection.Index? {
    return collection.indexForKey(key)
  }


  public subscript (position: Collection.Index) -> Collection.Generator.Element {
    get {
      return collection[position]
    }
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

  public func updateValue(value: Index.Value, forKey key: Index.Key) -> Index.Value? {
    var new = collection
    if let index = new.indexForKey(key) {
      let oldValue = new.updateValue(value, forKey: key)
      update(CollectionChangeset(collection: new, inserts: [], deletes: [], updates: [index]))
      return oldValue
    } else {
      new.updateValue(value, forKey: key)
      let index = new.indexForKey(key)!
      update(CollectionChangeset(collection: new, inserts: [index], deletes: [], updates: []))
      return nil
    }
  }

  public func removeValueForKey(key: Index.Key) -> Index.Value? {
    if let index = collection.indexForKey(key) {
      var new = collection
      let oldValue = new.removeValueForKey(key)
      update(CollectionChangeset(collection: new, inserts: [], deletes: [index], updates: []))
      return oldValue
    } else {
      return nil
    }
  }
}

// MARK: Array Extensions

public extension CollectionPropertyType where Collection == Array<Member> {

  /// Append `newElement` to the array.
  public func append(newElement: Member) {
    var new = collection
    new.append(newElement)
    update(CollectionChangeset(collection: new, inserts: [collection.count], deletes: [], updates: []))
  }

  /// Insert `newElement` at index `i`.
  public func insert(newElement: Member, atIndex: Int)  {
    var new = collection
    new.insert(newElement, atIndex: atIndex)
    update(CollectionChangeset(collection: new, inserts: [atIndex], deletes: [], updates: []))
  }

  /// Insert elements `newElements` at index `i`.
  public func insertContentsOf(newElements: [Member], at index: Collection.Index) {
    var new = collection
    new.insertContentsOf(newElements, at: index)
    update(CollectionChangeset(collection: new, inserts: Array(index..<index+newElements.count), deletes: [], updates: []))
  }

  /// Move the element at index `i` to index `toIndex`.
  public func moveItemAtIndex(fromIndex: Int, toIndex: Int) {
    let item = collection[fromIndex]
    var new = collection
    new.removeAtIndex(fromIndex)
    new.insert(item, atIndex: toIndex)
    let updates = Array(min(fromIndex, toIndex)...max(fromIndex, toIndex))
    update(CollectionChangeset(collection: new, inserts: [], deletes: [], updates: updates))
  }

  /// Remove and return the element at index i.
  public func removeAtIndex(index: Int) -> Member {
    var new = collection
    let element = new.removeAtIndex(index)
    update(CollectionChangeset(collection: new, inserts: [], deletes: [index], updates: []))
    return element
  }

  /// Remove an element from the end of the array in O(1).
  public func removeLast() -> Member {
    var new = collection
    let element = new.removeLast()
    update(CollectionChangeset(collection: new, inserts: [], deletes: [new.count], updates: []))
    return element
  }

  /// Remove all elements from the array.
  public func removeAll() {
    let deletes = Array(0..<collection.count)
    update(CollectionChangeset(collection: [], inserts: [], deletes: deletes, updates: []))
  }

  public subscript(index: Collection.Index) -> Member {
    get {
      return collection[index]
    }
    set {
      var new = collection
      new[index] = newValue
      update(CollectionChangeset(collection: new, inserts: [], deletes: [], updates: [index]))
    }
  }
}

extension CollectionPropertyType where Collection == Array<Member>, Member: Equatable {

  /**
   Replace current array with the new array and send change events.

   - parameter newCollection: The array to replace current array with.

   - parameter performDiff: When `true`, difference between the current
   array and the new array will be calculated and the sent event will 
   contain exact description of which elements were inserted and which 
   deleted. When `false`, the sent event contains current array indices 
   as `deletes` indices and new array indices as  `insertes` indices.

   - complexity: O(1) if `performDiff == false`. Otherwise O(`collection.count * newCollection.count`).
   */
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

      update(CollectionChangeset(collection: newCollection, inserts: inserts, deletes: deletes, updates: []))
    } else {
      replace(newCollection)
    }
  }
}

enum DiffStep<T> {
  case Insert(element: T, index: Int)
  case Delete(element: T, index: Int)
}

extension Array where Element: Equatable {

  // Created by Dapeng Gao on 20/10/15.
  // The central idea of this algorithm is taken from https://github.com/jflinter/Dwifft

  static func diff(x: [Element], _ y: [Element]) -> [DiffStep<Element>] {

    if x.count == 0 {
      return zip(y, y.indices).map(DiffStep<Element>.Insert)
    }

    if y.count == 0 {
      return zip(x, x.indices).map(DiffStep<Element>.Delete)
    }

    // Use dynamic programming to generate a table such that `table[i][j]` represents
    // the length of the longest common substring (LCS) between `x[0..<i]` and `y[0..<j]`
    let xLen = x.count, yLen = y.count
    var table = [[Int]](count: xLen + 1, repeatedValue: [Int](count: yLen + 1, repeatedValue: 0))
    for i in 1...xLen {
      for j in 1...yLen {
        if x[i - 1] == y[j - 1] {
          table[i][j] = table[i - 1][j - 1] + 1
        } else {
          table[i][j] = max(table[i - 1][j], table[i][j - 1])
        }
      }
    }

    // Backtrack to find out the diff
    var backtrack: [DiffStep<Element>] = []
    var i = xLen
    var j = yLen
    while i > 0 || j > 0 {
      if i == 0 {
        j -= 1
        backtrack.append(.Insert(element: y[j], index: j))
      } else if j == 0 {
        i -= 1
        backtrack.append(.Delete(element: x[i], index: i))
      } else if table[i][j] == table[i][j - 1] {
        j -= 1
        backtrack.append(.Insert(element: y[j], index: j))
      } else if table[i][j] == table[i - 1][j] {
        i -= 1
        backtrack.append(.Delete(element: x[i], index: i))
      } else {
        i -= 1
        j -= 1
      }
    }

    // Reverse the result
    return backtrack.reverse()
  }
}

extension CollectionProperty: BindableType {

  /// Returns an observer that can be used to dispatch events to the receiver.
  /// Can accept a disposable that will be disposed on receiver's deinit.
  public func observer(disconnectDisposable: Disposable) -> StreamEvent<CollectionChangeset<C>> -> () {
    disposeBag.addDisposable(disconnectDisposable)
    return { [weak self] event in
      if let changeset = event.element {
        self?.update(changeset)
      }
    }
  }
}
