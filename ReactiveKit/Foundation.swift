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

import Foundation

extension NotificationCenter {

  /// Observe notifications using a stream.
  public func rNotification(name: Notification.Name, object: AnyObject?) -> Stream<NSNotification> {
    return Stream { observer in
      let subscription = NotificationCenter.default.addObserver(forName: name, object: object, queue: nil, using: { notification in
        observer.next(notification as NSNotification)
      })
      return BlockDisposable {
        NotificationCenter.default.removeObserver(subscription)
      }
    }
  }
}

public extension NSObject {

  private struct AssociatedKeys {
    static var DisposeBagKey = "r_DisposeBagKey"
    static var AssociatedPropertiesKey = "r_AssociatedPropertiesKey"
  }

  /// Use this bag to dispose disposables upon the deallocation of the receiver.
  public var rBag: DisposeBag {
    if let disposeBag: AnyObject = objc_getAssociatedObject(self, &AssociatedKeys.DisposeBagKey) as AnyObject? {
      return disposeBag as! DisposeBag
    } else {
      let disposeBag = DisposeBag()
      objc_setAssociatedObject(self, &AssociatedKeys.DisposeBagKey, disposeBag, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return disposeBag
    }
  }

  /// Create a stream that observes given key path using KVO.
  public func rValueForKeyPath<T>(keyPath: String, sendInitial: Bool = true, retainStrongly: Bool = true) -> Stream<T> {
    return RKKeyValueStream(keyPath: keyPath, ofObject: self, sendInitial: sendInitial, retainStrongly: retainStrongly) { (object: AnyObject?) -> T? in
      return object as? T
    }.toStream()
  }

  /// Create a stream that observes given key path using KVO.
  public func rValueForKeyPath<T: OptionalType>(keyPath: String, sendInitial: Bool = true, retainStrongly: Bool = true) -> Stream<T> {
    return RKKeyValueStream(keyPath: keyPath, ofObject: self, sendInitial: sendInitial, retainStrongly: retainStrongly) { (object: AnyObject?) -> T? in
      if object == nil {
        return T(nilLiteral: ())
      } else {
        if let object = object as? T.Wrapped {
          return T(object)
        } else {
          return T(nilLiteral: ())
        }
      }
    }.toStream()
  }

  /// Bind `stream` to `bindable` and dispose in `rBag` of receiver.
  func bind<S: StreamType, B: BindableType>(stream: S, to bindable: B) where S.Element == B.Element {
    stream.bindTo(bindable).disposeIn(rBag)
  }

  /// Bind `stream` to `bindable` and dispose in `rBag` of receiver.
  func bind<S: StreamType, B: BindableType>(stream: S, to bindable: B) where B.Element: OptionalType, S.Element == B.Element.Wrapped {
    stream.bindTo(bindable).disposeIn(rBag)
  }

  internal var r_associatedProperties: [String:AnyObject] {
    get {
      return objc_getAssociatedObject(self, &AssociatedKeys.AssociatedPropertiesKey) as? [String:AnyObject] ?? [:]
    }
    set(property) {
      objc_setAssociatedObject(self, &AssociatedKeys.AssociatedPropertiesKey, property, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }

  public func rAssociatedPropertyForValueFor<T>(key: String, initial: T? = nil, set: ((T) -> ())? = nil) -> Property<T> {
    if let property: AnyObject = r_associatedProperties[key] {
      return property as! Property<T>
    } else {
      let property = Property<T>(initial ?? self.value(forKey: key) as! T)
      r_associatedProperties[key] = property

      property.observeNext { [weak self] (value: T) in
        if let set = set {
          set(value)
        } else {
          if let value = value as AnyObject? {
            self?.setValue(value, forKey: key)
          } else {
            self?.setValue(nil, forKey: key)
          }
        }
      }.disposeIn(rBag)

      return property
    }
  }

  public func rAssociatedPropertyForValueFor<T: OptionalType>(key: String, initial: T? = nil, set: ((T) -> ())? = nil) -> Property<T> {
    if let property: AnyObject = r_associatedProperties[key] {
      return property as! Property<T>
    } else {
      let property: Property<T>
      if let initial = initial {
        property = Property(initial)
      } else if let value = self.value(forKey: key) as? T.Wrapped {
        property = Property(T(value))
      } else {
        property = Property(T(nilLiteral: ()))
      }

      r_associatedProperties[key] = property

      property.observeNext { [weak self] (value: T) in
        if let set = set {
          set(value)
        } else {
          self?.setValue(value._unbox as AnyObject?, forKey: key)
        }
      }.disposeIn(rBag)

      return property
    }
  }
}

// MARK: - Implementations

public class RKKeyValueStream<T>: NSObject, StreamType {
  fileprivate var strongObject: NSObject? = nil
  fileprivate weak var object: NSObject? = nil
  fileprivate var context = 0
  fileprivate var keyPath: String
  fileprivate var options: NSKeyValueObservingOptions
  fileprivate let transform: (AnyObject?) -> T?
  fileprivate let subject: AnySubject<StreamEvent<T>>
  fileprivate var numberOfObservers: Int = 0

  fileprivate init(keyPath: String, ofObject object: NSObject, sendInitial: Bool, retainStrongly: Bool, transform: @escaping (AnyObject?) -> T?) {
    self.keyPath = keyPath
    self.options = sendInitial ? NSKeyValueObservingOptions.new.union(.initial) : .new
    self.transform = transform

    if sendInitial {
      subject = AnySubject(base: ReplaySubject(bufferSize: 1))
    } else {
      subject = AnySubject(base: PublishSubject())
    }

    super.init()

    self.object = object
    if retainStrongly {
      self.strongObject = object
    }
  }

  deinit {
    subject.completed()
    print("deinit")
  }

  public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    if context == &self.context {
      if let newValue = change?[NSKeyValueChangeKey.newKey] as AnyObject? {
        if let newValue = transform(newValue) {
          subject.next(newValue)
        } else {
          fatalError("Value [\(newValue)] not convertible to \(T.self) type!")
        }
      } else {
        // no new value - ignore
      }
    } else {
      super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }
  }

  fileprivate func increaseNumberOfObservers() {
    numberOfObservers += 1
    if numberOfObservers == 1 {
      object?.addObserver(self, forKeyPath: keyPath, options: options, context: &self.context)
    }
  }

  fileprivate func decreaseNumberOfObservers() {
    numberOfObservers -= 1
    if numberOfObservers == 0 {
      object?.removeObserver(self, forKeyPath: self.keyPath)
    }
  }

  public var rawStream: RawStream<StreamEvent<T>> {
    return RawStream { observer in
      self.increaseNumberOfObservers()
      let disposable = self.subject.toRawStream().observe(observer: observer.observer)
      let cleanupDisposabe = BlockDisposable {
        disposable.dispose()
        self.decreaseNumberOfObservers()
      }
      return DeinitDisposable(disposable: cleanupDisposabe)
    }
  }
}
