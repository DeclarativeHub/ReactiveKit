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

public struct MutableObservableCollection<Collection: CollectionType>: ObservableCollectionType {
  
  private var observableCollection: ObservableCollection<Collection>
  
  public var collection: Collection {
    get {
      return observableCollection.collection
    }
  }
  
  public init(_ collection: Collection) {
    observableCollection = ObservableCollection(collection)
  }
  
  public func next(event: ObservableCollectionEvent<Collection>) {
    observableCollection.next(event)
  }
  
  public func observe(on context: ExecutionContext? = ImmediateOnMainExecutionContext, observer: ObservableCollectionEvent<Collection> -> ()) -> DisposableType {
    return observableCollection.observe(on: context, observer: observer)
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
