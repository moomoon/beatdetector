//
//  Operators.swift
//  Maddo
//
//  Created by moomoon on 12/10/2016.
//  Copyright © 2016 dr. All rights reserved.
//

import Foundation
import Curry

infix operator =??: AssignmentPrecedence

precedencegroup PipeForwardPrecedence {
  associativity: left
  higherThan: PipeBackwardPrecedence
  lowerThan: LogicalDisjunctionPrecedence
}

precedencegroup PipeBackwardPrecedence {
  associativity: right
  higherThan: AssignmentPrecedence
  lowerThan: LogicalDisjunctionPrecedence
}

infix operator <?>: PipeForwardPrecedence

infix operator ?!=: AssignmentPrecedence


func ?!=<T>(lhs: inout T?, rhs: @autoclosure () -> T) -> T {
  if let curr = lhs {
    return curr
  }
  let newVal = rhs()
  lhs = newVal
  return newVal
}


infix operator ->>: PipeForwardPrecedence
@discardableResult @inline(__always)func ->> <F, T>(lhs: F, rhs: (F) -> T) -> T {
  return rhs(lhs)
}
infix operator <<-: PipeBackwardPrecedence
@inline(__always)func <<- <F, T>(lhs: (F) -> T, rhs: F) -> T {
  return lhs(rhs)
}
infix operator •: PipeForwardPrecedence
func • <A, B, C>(lhs: @escaping (B) -> C, rhs: @escaping (A) -> B) -> (A) -> C {
  return { lhs(rhs($0)) }
}

prefix operator *
prefix func *<A, B, C>(rhs: @escaping (A) -> B) -> (@escaping (C) -> A) -> (C) -> B {
  return { lhs in { rhs(lhs($0)) } }
}

prefix operator !!
prefix func !!<A>(_ value: A) -> Optional<A> {
  return .some(value)
}
prefix operator =>
prefix func =><A, B>(_ value: A) -> (B) -> A {
  return { _ in value }
}


infix operator =~: ComparisonPrecedence

func <?><T: AnyObject, A, B>(lhs: T, rhs: @escaping (T) -> (A) -> B) -> (A) -> B? {
  return { [weak lhs] in lhs.map(rhs)?($0) }
}

@discardableResult func =?? <T>(assignTo: inout T, newValue: T?) -> T {
  if let newValue = newValue {
    assignTo = newValue
    return newValue
  }
  return assignTo
}

func reader<A, B>(_ block: @escaping (A, B) -> ()) -> (@escaping (A) -> B) -> (A) -> B {
  #if DEBUG
    return { `func` in { a in `func`(a) ->> side { block(a, $0) } } }
  #else
    return id
  #endif
}


func reader<A, B>(_ message: String = "") -> (@escaping (A) -> B) -> (A) -> B {
  #if DEBUG
    return { `func` in { a in `func`(a) ->> side { print("\(message): \(a) -> \($0)") } } }
  #else
    return id
  #endif
}

func side<T>(_ handler: @escaping (T) -> ()) -> (T) -> T {
  return { handler($0); return $0 }
}


func side<A, T>(_ startValue: A, handler: @escaping (A, T) ->()) -> (T) -> T {
  return side { handler(startValue, $0) }
}

func logger<T>(_ prefix: String = "") -> (T) -> T {
  #if DEBUG
    return side { print(prefix + " \($0)") }
  #else
    return id
  #endif
}

func reader<T>(_ prefix: String = "") -> (T) -> () {
  return logger(prefix) ->> *discard
}

func debugError<T>(with message: @escaping (T) -> String) -> (T) -> T {
  #if DEBUG
    return side { fatalError(message($0)) }
  #else
    return id
  #endif
}

func time<T>(_ msg: String = "") -> (T) -> T {
  let start = Date.timeIntervalSinceReferenceDate
  return side { _ in print("\(msg): \(Date.timeIntervalSinceReferenceDate - start)") }
}

func debugError<T>(_ message: @escaping @autoclosure () -> String) -> (T) -> T {
  return debugError { _ in message() }
}

func id<T>(_ t: T) -> T {
  return t
}

func & (lhs: Bool, rhs: Bool) -> Bool {
  return lhs && rhs
}

func discard<T>(_ drop: T) -> () {}

func modify<T>(_ lhs: inout T, _ rhs: (T) -> T) -> T {
  let old = lhs
  lhs = rhs(old)
  return old
}

func modifyMaybe<T>(_ lhs: inout T, _ rhs: (T) -> T?) -> T {
  return modify(&lhs) { rhs($0) ?? $0 }
}

func runOnMainQueue(isSync: Bool = false, execute closure: @escaping Closure) {
  if Thread.current == Thread.main { return closure() }
  if isSync { return DispatchQueue.main.sync(execute: closure) }
  DispatchQueue.main.async(execute: closure)
}

func timePassed<T>(_ prefix: String = "") -> (T) -> T {
  return side (Date.timeIntervalSinceReferenceDate) { start, _ in print("\(prefix) used \(Date.timeIntervalSinceReferenceDate - start)") }
}

typealias Closure = () -> ()
typealias Consumer<T> = (T) -> ()

func splat<P, R>(_ input: (P...) -> R, _ arguments: [P]) -> R {
  return withoutActuallyEscaping(input) { (input: @escaping (P...) -> R) -> R in
    return splat(input)(arguments)
  }
}

func splat<P, R>(_ input: @escaping (P...) -> R) -> ([P]) -> R {
  return unsafeBitCast(input, to: (([P]) -> R).self)
}

