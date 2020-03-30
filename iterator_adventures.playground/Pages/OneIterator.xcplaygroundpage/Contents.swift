//: [Previous](@previous)

struct OneIterator<T>: IteratorProtocol {
    private(set) var item: T?

    init(item: T) {
        self.item = item
    }

    mutating func next() -> T? {
        let item = self.item
        self.item = nil
        return item
    }
}

var iterator = OneIterator<Int>(item: 23)

while let item = iterator.next() {
    print(item)
}

print("end")

//: [Next](@next)
