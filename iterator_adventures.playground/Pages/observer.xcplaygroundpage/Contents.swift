//: [Previous](@previous)

import Foundation

enum Event<Element> {
    case next(Element)
    case error(Error)
    case completed
}

protocol Observer {
    associatedtype Element

    func on(_ event: Event<Element>)
}

final class AnyObserver<Element>: Observer {

    let eventHandler: (Event<Element>) -> Void

    init(eventHandler: @escaping (Event<Element>) -> Void) {
        self.eventHandler = eventHandler
    }

    func on(_ event: Event<Element>) {
        eventHandler(event)
    }
}

final class AsyncIterator<Element>: Observer {
    private var observers = [AnyObserver<Element>]()

    func subscribe(_ observer: AnyObserver<Element>) {
        observers.append(observer)
    }

    func on(_ event: Event<Element>) {
        observers.forEach { observer in
            DispatchQueue.main.async { observer.on(event) }
        }
    }
}


//: [Next](@next)
