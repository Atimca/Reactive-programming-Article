//: [Previous](@previous)

import Foundation

import Foundation
import PlaygroundSupport

//: ## Async

extension Array {
    func forEach(
        queue: DispatchQueue,
        onNext: @escaping (Element) -> Void,
        onError: @escaping (Error) -> Void,
        onCompleted: @escaping () -> Void) {

        for element in self {
            queue.async { onNext(element) }
        }
        queue.async { onCompleted() }
    }
}

let queue = DispatchQueue(
    label: "com.iterator-adventures",
    qos: .background,
    attributes: .concurrent)

print("async start")

animals.forEach(
    queue: queue,
    onNext: { item in
        print(item)
    },
    onError: { error in
        print(error)
    },
    onCompleted: {
        print("complete")
        PlaygroundPage.current.finishExecution()
    })

print("async end")

PlaygroundPage.current.needsIndefiniteExecution = true
//: [Next](@next)
