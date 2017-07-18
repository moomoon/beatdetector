//
//  RxSwiftExtensions.swift
//  beatdetector
//
//  Created by m on 18/07/2017.
//  Copyright © 2017 m. All rights reserved.
//

import Foundation
import RxSwift


extension Observable {
//  func existing<T>(_ transform: @escaping (Element) -> T?) -> Observable<T> {
//    return map(transform).filterNil()
//  }
  static func create(_ onSubscribe: @escaping (AnyObserver<Element>) throws -> Disposable) -> Observable<Element> {
    return .create { observer in
      do {
        return try onSubscribe(observer)
      } catch let e {
        observer.onError(e ->> logger("e"))
        return Disposables.create()
      }
    }
  }
  func delay<U>(_ type: U.Type? = nil, until observable: Observable<U>) -> Observable<E> {
    return flatMap { observable.take(1).map(=>$0) }
  }
  func delay(subscribe: @escaping (@escaping () -> ()) -> ()) -> Observable<E> {
    return delay(Void.self, until: .create { subscribe($0.onNext); return Disposables.create() })
  }
}


