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

// MARK: - Free Functions

// MARK: - Tuple functions

private func tuple<A, B>(a: A, b: B) -> (A, B) { return (a, b) }
private func tuple<A, B, C>(a: A, b: B, c: C) -> (A, B, C) { return (a, b, c) }
private func tuple<A, B, C, D>(a: A, b: B, c: C, d: D) -> (A, B, C, D) { return (a, b, c, d) }
private func tuple<A, B, C, D, E>(a: A, b: B, c: C, d: D, e: E) -> (A, B, C, D, E) { return (a, b, c, d, e) }
private func tuple<A, B, C, D, E, F>(a: A, b: B, c: C, d: D, e: E, f: F) -> (A, B, C, D, E, F) { return (a, b, c, d, e, f) }

// MARK: Combine Latest

/// Combine multiple signals into one. See `combineLatest(with:)` for more info.
public func combineLatest
  <A: SignalProtocol, B: SignalProtocol, Result>
  (_ a: A, _ b: B, combine: @escaping (A.Element, B.Element) -> Result) -> Signal<Result, A.Error>
  where A.Error == B.Error {
    return a.combineLatest(with: b, combine: combine)
}

/// Combine multiple signals into one. See `combineLatest(with:)` for more info.
public func combineLatest
  <A: SignalProtocol, B: SignalProtocol, C: SignalProtocol, Result>
  (_ a: A, _ b: B, _ c: C, combine: @escaping (A.Element, B.Element, C.Element) -> Result) -> Signal<Result, A.Error>
  where A.Error == B.Error, A.Error == C.Error {
    return combineLatest(a, b).combineLatest(with: c, combine: { combine($0.0, $0.1, $1) })
}

/// Combine multiple signals into one. See `combineLatest(with:)` for more info.
public func combineLatest
  <A: SignalProtocol, B: SignalProtocol, C: SignalProtocol, D: SignalProtocol, Result>
  (_ a: A, _ b: B, _ c: C, _ d: D, combine: @escaping (A.Element, B.Element, C.Element, D.Element) -> Result) -> Signal<Result, A.Error>
  where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error {
    return combineLatest(a, b, c).combineLatest(with: d, combine: { combine($0.0, $0.1, $0.2, $1) })
}

/// Combine multiple signals into one. See `combineLatest(with:)` for more info.
public func combineLatest
  <A: SignalProtocol, B: SignalProtocol, C: SignalProtocol, D: SignalProtocol, E: SignalProtocol, Result>
  (_ a: A, _ b: B, _ c: C, _ d: D, _ e: E, combine: @escaping (A.Element, B.Element, C.Element, D.Element, E.Element) -> Result) -> Signal<Result, A.Error>
  where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error {
    return combineLatest(a, b, c, d).combineLatest(with: e, combine: { combine($0.0, $0.1, $0.2, $0.3, $1) })
}

/// Combine multiple signals into one. See `combineLatest(with:)` for more info.
public func combineLatest
  <A: SignalProtocol, B: SignalProtocol, C: SignalProtocol, D: SignalProtocol, E: SignalProtocol, F: SignalProtocol, Result>
  (_ a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, combine: @escaping (A.Element, B.Element, C.Element, D.Element, E.Element, F.Element) -> Result) -> Signal<Result, A.Error>
  where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error, A.Error == F.Error {
    return combineLatest(a, b, c, d, e).combineLatest(with: f, combine: { combine($0.0, $0.1, $0.2, $0.3, $0.4, $1) })
}

// MARK: Combine Latest with default combine.

/// Combine multiple signals into one. See `combineLatest(with:)` for more info.
public func combineLatest
  <A: SignalProtocol, B: SignalProtocol>
  (_ a: A, _ b: B) -> Signal<(A.Element, B.Element), A.Error>
  where A.Error == B.Error {
    return combineLatest(a, b, combine: tuple)
}

/// Combine multiple signals into one. See `combineLatest(with:)` for more info.
public func combineLatest
  <A: SignalProtocol, B: SignalProtocol, C: SignalProtocol>
  (_ a: A, _ b: B, _ c: C) -> Signal<(A.Element, B.Element, C.Element), A.Error>
  where A.Error == B.Error, A.Error == C.Error {
    return combineLatest(a, b, c, combine: tuple)
}

/// Combine multiple signals into one. See `combineLatest(with:)` for more info.
public func combineLatest
  <A: SignalProtocol, B: SignalProtocol, C: SignalProtocol, D: SignalProtocol>
  (_ a: A, _ b: B, _ c: C, _ d: D) -> Signal<(A.Element, B.Element, C.Element, D.Element), A.Error>
  where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error {
    return combineLatest(a, b, c, d, combine: tuple)
}

/// Combine multiple signals into one. See `combineLatest(with:)` for more info.
public func combineLatest
  <A: SignalProtocol, B: SignalProtocol, C: SignalProtocol, D: SignalProtocol, E: SignalProtocol>
  (_ a: A, _ b: B, _ c: C, _ d: D, _ e: E) -> Signal<(A.Element, B.Element, C.Element, D.Element, E.Element), A.Error>
  where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error {
    return combineLatest(a, b, c, d, e, combine: tuple)
}

/// Combine multiple signals into one. See `combineLatest(with:)` for more info.
public func combineLatest
  <A: SignalProtocol, B: SignalProtocol, C: SignalProtocol, D: SignalProtocol, E: SignalProtocol, F: SignalProtocol>
  (_ a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F) -> Signal<(A.Element, B.Element, C.Element, D.Element, E.Element, F.Element), A.Error>
  where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error, A.Error == F.Error {
    return combineLatest(a, b, c, d, e, f, combine: tuple)
}

// MARK: Zip

/// Zip multiple signals into one. See `zip(with:)` for more info.
public func zip
  <A: SignalProtocol, B: SignalProtocol, Result>
  (_ a: A, _ b: B, combine: @escaping (A.Element, B.Element) -> Result) -> Signal<Result, A.Error>
  where A.Error == B.Error {
    return a.zip(with: b, combine: combine)
}

/// Zip multiple signals into one. See `zip(with:)` for more info.
public func zip
  <A: SignalProtocol, B: SignalProtocol, C: SignalProtocol, Result>
  (_ a: A, _ b: B, _ c: C, combine: @escaping (A.Element, B.Element, C.Element) -> Result) -> Signal<Result, A.Error>
  where A.Error == B.Error, A.Error == C.Error {
    return zip(a, b).zip(with: c, combine: { combine($0.0, $0.1, $1) })
}

/// Zip multiple signals into one. See `zip(with:)` for more info.
public func zip
  <A: SignalProtocol, B: SignalProtocol, C: SignalProtocol, D: SignalProtocol, Result>
  (_ a: A, _ b: B, _ c: C, _ d: D, combine: @escaping (A.Element, B.Element, C.Element, D.Element) -> Result) -> Signal<Result, A.Error>
  where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error {
    return zip(a, b, c).zip(with: d, combine: { combine($0.0, $0.1, $0.2, $1) })
}

/// Zip multiple signals into one. See `zip(with:)` for more info.
public func zip
  <A: SignalProtocol, B: SignalProtocol, C: SignalProtocol, D: SignalProtocol, E: SignalProtocol, Result>
  (_ a: A, _ b: B, _ c: C, _ d: D, _ e: E, combine: @escaping (A.Element, B.Element, C.Element, D.Element, E.Element) -> Result) -> Signal<Result, A.Error>
  where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error {
    return zip(a, b, c, d).zip(with: e, combine: { combine($0.0, $0.1, $0.2, $0.3, $1) })
}

/// Zip multiple signals into one. See `zip(with:)` for more info.
public func zip
  <A: SignalProtocol, B: SignalProtocol, C: SignalProtocol, D: SignalProtocol, E: SignalProtocol, F: SignalProtocol, Result>
  (_ a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F, combine: @escaping (A.Element, B.Element, C.Element, D.Element, E.Element, F.Element) -> Result) -> Signal<Result, A.Error>
  where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error, A.Error == F.Error {
    return zip(a, b, c, d, e).zip(with: f, combine: { combine($0.0, $0.1, $0.2, $0.3, $0.4, $1) })
}

// MARK: Zip with default combine.

/// Zip multiple signals into one. See `zip(with:)` for more info.
public func zip
  <A: SignalProtocol, B: SignalProtocol>
  (_ a: A, _ b: B) -> Signal<(A.Element, B.Element), A.Error>
  where A.Error == B.Error {
    return zip(a, b, combine: tuple)
}

/// Zip multiple signals into one. See `zip(with:)` for more info.
public func zip
  <A: SignalProtocol, B: SignalProtocol, C: SignalProtocol>
  (_ a: A, _ b: B, _ c: C) -> Signal<(A.Element, B.Element, C.Element), A.Error>
  where A.Error == B.Error, A.Error == C.Error {
    return zip(a, b, c, combine: tuple)
}

/// Zip multiple signals into one. See `zip(with:)` for more info.
public func zip
  <A: SignalProtocol, B: SignalProtocol, C: SignalProtocol, D: SignalProtocol>
  (_ a: A, _ b: B, _ c: C, _ d: D) -> Signal<(A.Element, B.Element, C.Element, D.Element), A.Error>
  where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error {
    return zip(a, b, c, d, combine: tuple)
}

/// Zip multiple signals into one. See `zip(with:)` for more info.
public func zip
  <A: SignalProtocol, B: SignalProtocol, C: SignalProtocol, D: SignalProtocol, E: SignalProtocol>
  (_ a: A, _ b: B, _ c: C, _ d: D, _ e: E) -> Signal<(A.Element, B.Element, C.Element, D.Element, E.Element), A.Error>
  where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error {
    return zip(a, b, c, d, e, combine: tuple)
}

/// Zip multiple signals into one. See `zip(with:)` for more info.
public func zip
  <A: SignalProtocol, B: SignalProtocol, C: SignalProtocol, D: SignalProtocol, E: SignalProtocol, F: SignalProtocol>
  (_ a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F) -> Signal<(A.Element, B.Element, C.Element, D.Element, E.Element, F.Element), A.Error>
  where A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error, A.Error == F.Error {
    return zip(a, b, c, d, e, f, combine: tuple)
}


// MARK: Merge

/// Merge multiple signals into one. See `merge(with:)` for more info.
public func merge
  <A: SignalProtocol, B: SignalProtocol>
  (_ a: A, _ b: B) -> Signal<A.Element, A.Error>
  where A.Element == B.Element, A.Error == B.Error {
    return a.merge(with: b)
}

/// Merge multiple signals into one. See `merge(with:)` for more info.
public func merge
  <A: SignalProtocol, B: SignalProtocol, C: SignalProtocol>
  (_ a: A, _ b: B, _ c: C) -> Signal<A.Element, A.Error>
  where A.Element == B.Element, A.Element == C.Element, A.Error == B.Error, A.Error == C.Error {
    return merge(a, b).merge(with: c)
}

/// Merge multiple signals into one. See `merge(with:)` for more info.
public func merge
  <A: SignalProtocol, B: SignalProtocol, C: SignalProtocol, D: SignalProtocol>
  (_ a: A, _ b: B, _ c: C, _ d: D) -> Signal<A.Element, A.Error>
  where A.Element == B.Element, A.Element == C.Element, A.Element == D.Element, A.Error == B.Error, A.Error == C.Error, A.Error == D.Error {
    return merge(a, b, c).merge(with: d)
}

/// Merge multiple signals into one. See `merge(with:)` for more info.
public func merge
  <A: SignalProtocol, B: SignalProtocol, C: SignalProtocol, D: SignalProtocol, E: SignalProtocol>
  (_ a: A, _ b: B, _ c: C, _ d: D, _ e: E) -> Signal<A.Element, A.Error>
  where A.Element == B.Element, A.Element == C.Element, A.Element == D.Element, A.Element == E.Element, A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error {
    return merge(a, b, c, d).merge(with: e)
}

/// Merge multiple signals into one. See `merge(with:)` for more info.
public func merge
  <A: SignalProtocol, B: SignalProtocol, C: SignalProtocol, D: SignalProtocol, E: SignalProtocol, F: SignalProtocol>
  (_ a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F) -> Signal<A.Element, A.Error>
  where A.Element == B.Element, A.Element == C.Element, A.Element == D.Element, A.Element == E.Element, A.Element == F.Element, A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error, A.Error == F.Error {
    return merge(a, b, c, d, e).merge(with: f)
}

// MARK: Amb

/// Amb multiple signals into one. See `amb(with:)` for more info.
public func amb
  <A: SignalProtocol, B: SignalProtocol>
  (_ a: A, _ b: B) -> Signal<A.Element, A.Error>
  where A.Element == B.Element, A.Error == B.Error {
    return a.amb(with: b)
}

/// Amb multiple signals into one. See `amb(with:)` for more info.
public func amb
  <A: SignalProtocol, B: SignalProtocol, C: SignalProtocol>
  (_ a: A, _ b: B, _ c: C) -> Signal<A.Element, A.Error>
  where A.Element == B.Element, A.Element == C.Element, A.Error == B.Error, A.Error == C.Error {
    return amb(a, b).amb(with: c)
}

/// Amb multiple signals into one. See `amb(with:)` for more info.
public func amb
  <A: SignalProtocol, B: SignalProtocol, C: SignalProtocol, D: SignalProtocol>
  (_ a: A, _ b: B, _ c: C, _ d: D) -> Signal<A.Element, A.Error>
  where A.Element == B.Element, A.Element == C.Element, A.Element == D.Element, A.Error == B.Error, A.Error == C.Error, A.Error == D.Error {
    return amb(a, b, c).amb(with: d)
}

/// Amb multiple signals into one. See `amb(with:)` for more info.
public func amb
  <A: SignalProtocol, B: SignalProtocol, C: SignalProtocol, D: SignalProtocol, E: SignalProtocol>
  (_ a: A, _ b: B, _ c: C, _ d: D, _ e: E) -> Signal<A.Element, A.Error>
  where A.Element == B.Element, A.Element == C.Element, A.Element == D.Element, A.Element == E.Element, A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error {
    return amb(a, b, c, d).amb(with: e)
}

/// Amb multiple signals into one. See `amb(with:)` for more info.
public func amb
  <A: SignalProtocol, B: SignalProtocol, C: SignalProtocol, D: SignalProtocol, E: SignalProtocol, F: SignalProtocol>
  (_ a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F) -> Signal<A.Element, A.Error>
  where A.Element == B.Element, A.Element == C.Element, A.Element == D.Element, A.Element == E.Element, A.Element == F.Element, A.Error == B.Error, A.Error == C.Error, A.Error == D.Error, A.Error == E.Error, A.Error == F.Error {
    return amb(a, b, c, d, e).amb(with: f)
}
