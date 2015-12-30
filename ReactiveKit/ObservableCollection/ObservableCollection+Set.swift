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

extension ObservableCollectionType where Element: Hashable, Collection == Set<Element> {
  
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
  
  public func insert(member: Collection.Generator.Element) {
    var new  = collection
    new.insert(member)
    
    if let index = collection.indexOf(member) {
      next(ObservableCollectionEvent(collection: new, inserts: [], deletes: [], updates: [index]))
    } else {
      next(ObservableCollectionEvent(collection: new, inserts: [new.indexOf(member)!], deletes: [], updates: []))
    }
  }
  
  public func remove(member: Collection.Generator.Element) -> Collection.Generator.Element? {
    var new = collection
    
    if let index = collection.indexOf(member) {
      let old = new.removeAtIndex(index)
      next(ObservableCollectionEvent(collection: new, inserts: [], deletes: [index], updates: []))
      return old
    } else {
      return nil
    }
  }
}
