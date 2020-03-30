//: [Previous](@previous)

import Foundation

enum Event<Element> {
    case next(Element)
    case error(Error)
    case completed
}

final class Iterator<Element> {
    private var observers = [(Event<Element>) -> Void]()

    func add(_ observer: @escaping (Event<Element>) -> Void) {
        observers.append(observer)
    }

    func on(_ event: Event<Element>) {
        observers.forEach { observer in
            observer(event)
        }
    }
}

let iterator = Iterator<String>()

iterator.add { (event) in
    print(event)
}

iterator.on(.next(animals[0]))

for a in animals {
    iterator.on(.next(a))
}

//: [Next](@next)
