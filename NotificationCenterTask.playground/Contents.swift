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

class Observable<Element> {
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

//let observable = Observable<Int>(value: 1)
//
//var observer1: Observer<Int>? = observable
//    .subscribe { event in
//        print(event)
//}
//
//for i in 10...20 {
//    DispatchQueue(label: "", qos: .background, attributes: .concurrent).asyncAfter(deadline: .now() + 0.3) {
//        observable.value = i
//    }
//}
//
//for i in 21...30 {
//    DispatchQueue(label: "", qos: .background, attributes: .concurrent).asyncAfter(deadline: .now() + 0.3) {
//        observable.value = i
//    }
//}

let sequence = [1, 2, 3, 4, 5]
var iterator = sequence.makeIterator()

//while let item = iterator.next() {
//    print(item)
//}

//sequence.forEach { item in
//    print(item)
//}

extension Array {
    func forEach(_ body: @escaping (Element) -> Void) {
        for element in self {
            body(element)
        }
    }
}

func handle(_ item: Int) {
    print(item)
}

//sequence.forEach(handle)

extension Array {
    func forEach(
        on queue: DispatchQueue,
        body: @escaping (Element) -> Void) {
        for element in self {
            queue.async { body(element) }
        }
    }
}

let queue = DispatchQueue(
    label: "com.reactive",
    qos: .background,
    attributes: .concurrent
)

sequence.forEach(on: queue, body: handle)

PlaygroundPage.current.needsIndefiniteExecution = true
