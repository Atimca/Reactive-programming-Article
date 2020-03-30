//: [Previous](@previous)

import Foundation
import PlaygroundSupport

//: ## Sync

print("sync start")

flowers.forEach { item in
    print(item)
}

print("sync end")


//: ## Async

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
    label: "com.iterator-adventures",
    qos: .background,
    attributes: .concurrent)

print("async start")

animals.forEach(on: queue) { item in
    print(item)
}

print("async end")

PlaygroundPage.current.needsIndefiniteExecution = true

//: [Next](@next)
