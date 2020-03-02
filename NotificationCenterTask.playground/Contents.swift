import PlaygroundSupport
import Foundation

class WeakRef<T> where T: AnyObject {

    private(set) weak var value: T?

    init(value: T?) {
        self.value = value
    }
}

enum Event<Element> {
    case next(Element)
    case completed
}

class Observer<Element> {

    private let on: (Event<Element>) -> Void

    init(_ on: @escaping (Event<Element>) -> Void) {
        self.on = on
    }

    func on(_ event: Event<Element>) {
        on(event)
    }
}

class Variable<Element> {
    private typealias WeakObserver = WeakRef<Observer<Element>>
    private var bag: [WeakObserver] = []
    private let isolationQueue = DispatchQueue(label: "", attributes: .concurrent)

    var cash: [Element] = []

    private var _value: Element
    var value: Element {
        get {
            isolationQueue.sync { _value }
        }
        set {
            isolationQueue.async(flags: .barrier) {
                self._value = newValue
                self.cash.append(newValue)
                self.bag.forEach { $0.value?.on(.next(newValue)) }
            }
        }
    }

    init(value: Element) {
        self._value = value
    }

    deinit {
        bag.forEach { $0.value?.on(.completed) }
    }

    func subscribe(on: @escaping (Event<Element>) -> Void) -> Observer<Element> {
        let observer = Observer<Element>(on)
        bag.append(.init(value: observer))
        return observer
    }
}

let variable = Variable<Int>(value: 1)

var observer1: Observer<Int>? = variable
    .subscribe { event in
        print(event)
}

for i in 10...20 {
    DispatchQueue(label: "", qos: .background, attributes: .concurrent).asyncAfter(deadline: .now() + 0.3) {
        variable.value = i
    }
}

for i in 21...30 {
    DispatchQueue(label: "", qos: .background, attributes: .concurrent).asyncAfter(deadline: .now() + 0.3) {
        variable.value = i
    }
}

PlaygroundPage.current.needsIndefiniteExecution = true
