//: [Previous](@previous)

struct ZeroIterator<T>: IteratorProtocol {
    func next() -> T? {
        return nil
    }
}

let iterator = ZeroIterator<Int>()

while let item = iterator.next() {
    print(item)
}

print("end")

//: [Next](@next)
