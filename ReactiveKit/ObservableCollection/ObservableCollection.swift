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

public protocol ObservableCollectionType: CollectionType, StreamType {
  typealias Collection: CollectionType
  typealias Index = Collection.Index
  typealias Element = Collection.Generator.Element
  
  var collection: Collection { get }
  func next(event: ObservableCollectionEvent<Collection>)
  
  func observe(on context: ExecutionContext?, observer: ObservableCollectionEvent<Collection> -> ()) -> DisposableType
}

public final class ObservableCollection<Collection: CollectionType>: ActiveStream<ObservableCollectionEvent<Collection>>, ObservableCollectionType {

  private var _collection: Collection! = nil

  public var collection: Collection {
    return _collection
  }

  public init(_ collection: Collection) {
    _collection = collection
    super.init()
  }
  
  public override init(@noescape producer: (ObservableCollectionEvent<Collection> -> ()) -> DisposableType?) {
    super.init(producer: producer)
  }

  public override func next(event: ObservableCollectionEvent<Collection>) {
    _collection = event.collection
    super.next(event)
  }

  public override func observe(on context: ExecutionContext? = ImmediateOnMainExecutionContext, observer: Observer) -> DisposableType {
    let disposable = super.observe(on: context, observer: observer)
    observer(ObservableCollectionEvent.initial(collection))
    return disposable
  }

  /** 
   Allows updating the observable collection without generation of the events.

   ```
   array.silentUpdate { array in
     array.append(5)
   }
   ```
  */
  public func silentUpdate(@noescape perform: ObservableCollection<Collection> -> Void) {
    let collection = ObservableCollection(self.collection)
    perform(collection)
    _collection = collection.collection
  }

  // MARK: CollectionType conformance
  
  public func generate() -> Collection.Generator {
    return collection.generate()
  }
  
  public func underestimateCount() -> Int {
    return collection.underestimateCount()
  }
  
  public var startIndex: Collection.Index {
    return collection.startIndex
  }
  
  public var endIndex: Collection.Index {
    return collection.endIndex
  }
  
  public var isEmpty: Bool {
    return collection.isEmpty
  }
  
  public var count: Collection.Index.Distance {
    return collection.count
  }
  
  public subscript(index: Collection.Index) -> Collection.Generator.Element {
    get {
      return collection[index]
    }
  }
}

@warn_unused_result
public func create<C: CollectionType>(producer: (ObservableCollectionEvent<C> -> ()) -> DisposableType?) -> ObservableCollection<C> {
  return ObservableCollection(producer: producer)
}

public extension ObservableCollectionType {
  
  public func replace(newCollection: Collection) {
    let deletes = Array(collection.indices)
    let inserts = Array(newCollection.indices)
    next(ObservableCollectionEvent(collection: newCollection, inserts: inserts, deletes: deletes, updates: []))
  }
}

public extension ObservableCollectionType where Collection.Index == Int {
  
  /// Each event costs O(n)
  @warn_unused_result
  public func map<U>(transform: Collection.Generator.Element -> U) -> ObservableCollection<Array<U>> {
    return create { observer in
      return self.observe(on: nil) { event in
        observer(event.map(transform))
      }
    }
  }
  
  /// Each event costs O(1)
  @warn_unused_result
  public func lazyMap<U>(transform: Collection.Generator.Element -> U) -> ObservableCollection<LazyMapCollection<Collection, U>> {
    return create { observer in
      return self.observe(on: nil) { event in
        observer(event.lazyMap(transform))
      }
    }
  }
}

public extension ObservableCollectionType where Collection.Index == Int {
  
  /// Each event costs O(n)
  @warn_unused_result
  public func filter(include: Collection.Generator.Element -> Bool) -> ObservableCollection<Array<Collection.Generator.Element>> {
    return create { observer in
      return self.observe(on: nil) { event in
        observer(event.filter(include))
      }
    }
  }
}

public extension ObservableCollectionType where Collection.Index: Hashable {
  
  /// Each event costs O(n*logn)
  @warn_unused_result
  public func sort(isOrderedBefore: (Collection.Generator.Element, Collection.Generator.Element) -> Bool) -> ObservableCollection<Array<Collection.Generator.Element>> {
    return create { observer in
      return self.observe(on: nil) { event in
        observer(event.sort(isOrderedBefore))
      }
    }
  }
}

public extension ObservableCollectionType where Collection.Index: Equatable {
  
  /// Each event costs O(n^2)
  @warn_unused_result
  public func sort(isOrderedBefore: (Collection.Generator.Element, Collection.Generator.Element) -> Bool) -> ObservableCollection<Array<Collection.Generator.Element>> {
    return create { observer in
      return self.observe(on: nil) { event in
        observer(event.sort(isOrderedBefore))
      }
    }
  }
}
