//: [Previous](@previous)

import Foundation

struct InfinityIterator<T>: IteratorProtocol {
    let item: T

    init(item: T) {
        self.item = item
    }

    mutating func next() -> T? {
        return item
    }
}

var iterator = InfinityIterator<Int>(item: 3)

var count = 0

while let item = iterator.next() {
    print(item)
    
    count += 1
    if count == 23 {
        break
    }
}

print("end")

//: [Next](@next)
