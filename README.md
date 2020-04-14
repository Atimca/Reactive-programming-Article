# What is ~~RxSwift~~ ~~Combine~~ Reactive Programming?

There are many articles about Reactive Programming and different implementations on the internet. However, most of them are about practical usage, and only a few concern what Reactive Programming is, and how it actually works. In my opinion, it is more important to understand how frameworks work deep inside - spoiler: nothing actually complicated there - rather than starting to use a number of traits and operators meanwhile shooting yourself in the foot.

So, what is Reactive programming?

According to Wikipedia:

```
Reactive programming is a declarative programming paradigm concerned with data streams and the propagation of change. With this paradigm, it is possible to express static (e.g., arrays) or dynamic (e.g., event emitters) data streams with ease, and also communicate that an inferred dependency within the associated execution model exists, which facilitates the automatic propagation of the changed data flow.
```

Excuse me, WHAT?

![jackie](images/jackie_what.png)  

Let's start from the beginning.

Reactive programming is an idea from the late 90s that inspired Erik Meijer, a computer scientist at Microsoft, to design and develop the Microsoft Rx library, but what is it exactly?

I don't want to provide one definition of what reactive programming is. I would use the same complicated description as Wikipedia. I think it's better to compare imperative and reactive approaches.

With an imperative approach, a developer can expect that the code instructions will be executed incrementally, one by one, one at a time, in order as you have written them.

The reactive approach is not just a way to handle asynchronous code; it's a way to stop thinking about threads, and start to think about sequences. It allows you to treat streams of asynchronous events with the same sort of simple, composable operations that you use for collections of data items like arrays. You think about how your system `reacts` to the new information. In simple words, our system is always ready to handle new information, and technically the order of the calls is not a concern.

I assume that most of the readers of this article came from iOS development. So let me make an analogy. Reactive programming is Notification center on steroids, but don't worry, a counterweight of the reactive frameworks is that they are more sequential and understandable. Moreover in iOS development, it's hard to do things in one way, because Apple gave us several different approaches like delegates, selectors, GCD and etc. The reactive paradigm could help solve these problems in one fashion.

It sounds quite simple. Let's take a look ar a couple of functions in one class implementation of one of the most popular frameworks `RxSwift`:

```swift
public final class BehaviorSubject<Element> {

    public func value() throws -> Element {
        self._lock.lock(); defer { self._lock.unlock() }
            if self._isDisposed {
                throw RxError.disposed(object: self)
            }
            
            if let error = self._stoppedEvent?.error {
                throw error
            }
            else {
                return self._element
            }
    }

    func _synchronized_on(_ event: Event<Element>) -> Observers {
        self._lock.lock(); defer { self._lock.unlock() }
        if self._stoppedEvent != nil || self._isDisposed {
            return Observers()
        }
        
        switch event {
        case .next(let element):
            self._element = element
        case .error, .completed:
            self._stoppedEvent = event
        }
        
        return self._observers
    }
}
```

![long_neck](images/long_neck.png)

This even partial example does not look easy at all... As we can see the implementation of `RxSwift` is not so simple. But let me explain myself. `RxSwift` is an advanced, highly optimized framework with wide functionality. To understand the principles of the reactive world, this framework doesn't fit. So, what are we going to do? We are going to write our own reactive solution from scratch. To do this, firstly we need to understand which parts this library consists of.

## The tale of two friends

Let me answer again the question: What is reactive programming? Reactive programming is a friendship of two design patterns: `Iterator` and `Observer`. Let's have a quick reminder of how these patterns work.

`Iterator` is a behavioral design pattern that lets you traverse elements of a collection without exposing its underlying representation (list, stack, tree, etc.). You can read more at this [link](https://refactoring.guru/design-patterns/iterator).

`Observer` is a behavioral design pattern that lets you define a subscription mechanism to notify multiple objects about any events that happen to the object they’re observing. You can read more at this [link](https://refactoring.guru/design-patterns/observer).

How do these two friends work together? In simple terms, you use the `Observer` pattern to be subscribed for new events, and use the `Iterator` pattern to treat streams like sequences.

**Iterator**

Let's start from the beginning. From the `Iterator` pattern.

Here's a simple sequence of integers:
```swift
let sequence = [1, 2, 3, 4, 5]
```

And I want to iterate through it. Easy enough:
```swift
var iterator = sequence.makeIterator()

while let item = iterator.next() {
    print(item)
}

// 1 2 3 4 5
```
  
However, I think that everybody would say this way of iteration via sequence is a little bit weird. Let's do this the proper way:
```swift
sequence.forEach { item in
    print(item)
}

// 1 2 3 4 5
```

For now, it looks more natural, or at least I hope so. I used the `forEach` method on purpose. `forEach` has this signature `func forEach(_ body: (Element) -> Void)`. It's a function which takes a function(handler) as an argument and performs this handler over the sequence. Let's try to build `forEach` by ourselves.

```swift
extension Array {
    func forEach(_ body: @escaping (Element) -> Void) {
        for element in self {
            body(element)
        }
    }
}

sequence.forEach {
    print($0)
}

// 1 2 3 4 5
```

With `forEach` semantics it's possible to write this elegant code.

```swift
func handle(_ item: Int) {
    print(item)
}

sequence.forEach(handle)

// 1 2 3 4 5
```

As I said before, that reactive programming is above all thread problems. Let's add to our custom `forEach` some thread abstraction.

```swift
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

// Output is unpredictable, but we'd see all 5 values.
```

**Observer**

I went so far and did some strange custom `forEach` for Array. What is this for? We'll know about this a little bit later, but now let's move to `Observer`.

There are many terms used to describe this model of asynchronous programming and design. This article will use the following terms: an `Observer` and `Observable`. An `Observer` subscribes to an `Observable`, and the `Observable` emits items or sends notifications to its observers by calling the observers’ methods.

In other words: `Observable` is a stream with data itself, and `Observer` is a consumer of this stream.

Let's start with the `Observer`. As I said, it's a consumer of a data stream, which can do something around this data. Let me translate, it's a class with a function inside, which calls when new data arrives. Let’s implement this class.:

```swift
class Observer<Element> {

    private let on: (Element) -> Void

    init(_ on: @escaping (Element) -> Void) {
        self.on = on
    }

    func on(_ event: Element) {
        on(event)
    }
}
```

And now let’s move to `Observable`. `Observable` it's data itself. Let's make it simple for the first iteration.

```swift
class Observable<Element> {

    var value: Element

    init(value: Element) {
        self.value = value
    }
}
```

The most interesting part is that `Observable` should allow to `subscribe` to a consumer of this data. And via changing this data in `Observable`, `Observer` needs to know about these changes.

```swift
class Observable<Element> {
    private var observers: [Observer<Element>] = []

    var value: Element {
        didSet {
            observers.forEach { $0.on(self.value) }
        }
    }

    init(value: Element) {
        self.value = value
    }

    func subscribe(on observer: Observer<Element>) {
        observers.append(observer)
    }
}
```

Actually we just build our `Observer` pattern. So, let's try this out.

```swift
let observer = Observer<Int> {
    print($0)
}

let observable = Observable<Int>(value: 0)
observable.subscribe(on: observer)

for i in 1...5 {
    observable.value = i
}

// 1, 2, 3, 4, 5
```
And it works! But hold on for a second - let's add some modifications before we go further.

Maybe you've already mentioned that our `Observable` stores all input `Observers` via subscription, which is not so great. Let's make this dependency `weak`. However, Swift doesn't support weak arrays for now and maybe forever, that's why we need to handle this situation otherwise. Let's implement the class wrapper with a weak reference in it.

```swift
class WeakRef<T> where T: AnyObject {

    private(set) weak var value: T?

    init(value: T?) {
        self.value = value
    }
}
```

As a result, you can see a generic object, which could hold other objects weakly. Now let's make some improvements to `Observable`.

```swift
class Observable<Element> {
    private typealias WeakObserver = WeakRef<Observer<Element>>
    private var observers: [WeakObserver] = []

    var value: Element {
        didSet {
            observers.forEach { $0.value?.on(self.value) }
        }
    }

    init(value: Element) {
        self.value = value
    }

    func subscribe(on observer: Observer<Element>) {
        observers.append(.init(value: observer))
    }
}
```
For now `Observer`s not held by `Observable`. Let's try this out and create two observers.

```swift
let observer1 = Observer<Int> {
    print("first:  ", $0)
}

var observer2: Observer! = Observer<Int> {
    print("second: ", $0)
}

let observable = Observable<Int>(value: 0)
observable.subscribe(on: observer1)
observable.subscribe(on: observer2)

for i in 1...5 {
    observable.value = i

    if i == 2 {
        observer2 = nil
    }
}

/*
first:   1
second:  1
first:   2
second:  2
first:   3
first:   4
first:   5
*/
```

As you can see, the second `Observer` was destroyed after `2`, which proves the workability of the code. However, I think creating an `Observer` object by hand all the time could be annoying, so let's improve `Observable` to consume a closure, not an object. 

```swift
class Observable<Element> {
    private typealias WeakObserver = WeakRef<Observer<Element>>
    private var observers: [WeakObserver] = []

    var value: Element {
        didSet {
            observers.forEach { $0.value?.on(self.value) }
        }
    }

    init(value: Element) {
        self.value = value
    }

    func subscribe(onNext: @escaping (Element) -> Void) -> Observer<Element> {
        let observer = Observer(onNext)
        observers.append(.init(value: observer))
        return observer
    }
}

let observable = Observable<Int>(value: 0)
let observer = observable.subscribe {
    print($0)
}

for i in 1...5 {
    observable.value = i
}

// 1, 2, 3, 4, 5
```

For my taste usage is more clear now, however it's possible to use both `subscribe` functions.

For now, our tiny reactive framework looks finished, but not exactly. Let's do some asynchronous stress tests for the `Observable`.

```swift
let observable = Observable<Int>(value: 0)
let observer = observable.subscribe {
    print($0)
}

for i in 1...5 {
    DispatchQueue(label: "1", qos: .background, attributes: .concurrent).asyncAfter(deadline: .now() + 0.3) {
        observable.value = i
    }
}

for i in 6...9 {
    DispatchQueue(label: "2", qos: .background, attributes: .concurrent).asyncAfter(deadline: .now() + 0.3) {
        observable.value = i
    }
}
```
In this case, we should receive numbers from 1 to 9 in random order, because changes run in the different asynchronous queues. For my case, it was like this 

```swift
/*
3
4
4
4
5
6
7
8
9
*/
```

As you can see, it's not the expected result. A race condition happened and it should be fixed. The solution is easy - let's add some thread synchronization. There are several ways to achieve this, but I'll use a method with a dispatch barrier. Here's the solution.

```swift
class Observable<Element> {
    private typealias WeakObserver = WeakRef<Observer<Element>>
    private var observers: [WeakObserver] = []
    private let isolationQueue = DispatchQueue(label: "", attributes: .concurrent)

    private var _value: Element
    var value: Element {
        get {
            isolationQueue.sync { _value }
        }
        set {
            isolationQueue.async(flags: .barrier) {
                self._value = newValue
                self.observers.forEach { $0.value?.on(newValue) }
            }
        }
    }

    init(value: Element) {
        self._value = value
    }

    func subscribe(onNext: @escaping (Element) -> Void) -> Observer<Element> {
        let observer = Observer(onNext)
        observers.append(.init(value: observer))
        return observer
    }
}
```

The same test as before gave me this result:

```swift
/*
1
2
3
4
5
6
7
8
9
*/
```
This time it's even in the right order, but be aware that it's not guaranteed. Now our reactive framework has thread synchronization.

Let's move further and there's another difference between a vanilla `Observer` pattern and most of the reactive frameworks. Usually, as an `Element` from `Observable`, you manipulate not just an `Element`, but some kind of `Event` enumeration, which looks like this.

```swift
enum Event<Element> {
    case next(Element)
    case completed
    case error(Error)
}
```

It’s a handy solution, because you can handle situations when your sequence completed or received an error. I don't want to spend time adopting this practice right now, I think it doesn't matter for concept understanding.

**Let's compose `Observer` and `Iterator`**

One of the killer features for reactive programming is the possibility to treat your `Observable` `sequence` as a `Sequence` I think everybody knows these handy functions like `map`, `flatMap`, `reduce`, and so on. As an example, let's try to add to our `Observable` the `map` function. But firstly let's remember how it works with a simple array.

```swift
let sequence = [1, 2, 3, 4, 5]
let newSequence = sequence
    .map { element in
        return element + 1
}

// newSequence: 2, 3, 4, 5, 6
```

This case is a primitive adding 1 to every element. Can we do the same with an `Observable`? Sure we can. Let's add a `map` function to our `Observable`.

```swift
class Observable<Element> {
    typealias WeakObserver = WeakRef<Observer<Element>>
    private var observers: [WeakObserver] = []
    private let isolationQueue = DispatchQueue(label: "", attributes: .concurrent)

    private var _value: Element
    var value: Element {
        get {
            isolationQueue.sync { _value }
        }
        set {
            isolationQueue.async(flags: .barrier) {
                self._value = newValue
                self.observers.forEach { $0.value?.on(newValue) }
            }
        }
    }
    private var transform: ((Element) -> Element)?

    init(value: Element) {
        self._value = value
    }

    func subscribe(onNext: @escaping (Element) -> Void) -> Observer<Element> {
        let transform = self.transform ?? { $0 }
        let observer = Observer<Element> { element in
            onNext(transform(element))
        }
        observers.append(.init(value: observer))
        return observer
    }

    func map(_ transform: @escaping (Element) -> Element) -> Observable<Element> {
        self.transform = transform
        return self
    }
}

let observable = Observable<Int>(value: 0)
let observer = observable
    .map { $0 + 1 }
    .subscribe { print($0) }

for i in 1...5 {
    observable.value = i
}

// 2, 3, 4, 5, 6
```

Yeah, you can mention that I've cheated a little bit.

![Mr_Burns.png](images/Mr_Burns.png)

True `map` function would have structure with a generic like this `func map<T>(_ transform: @escaping (Element) -> T) -> Observable<T>`, but for the sake of simplicity in this article I just added this `func map(_ transform: @escaping (Element) -> Element) -> Observable<Element>`. I hope you could forgive me and understand the point. 

Actually, we're done for now with our own reactive framework, congratulations to everybody who followed until the end. It's super simplified but it works. Gist with the last iteration of this article you can find [here](https://gist.github.com/Atimca/51c83f4c9161fc36bed340b02e605d09).

I hope at least for now, reactive programming doesn’t look scary anymore. However, I hear all the time from people, that reactive way could lead us t an enormous number of sequences flying around the project and it's very easy to shoot yourself in the foot with this approach. I won't fight against this, and you can easily Google a bad style of doing reactive. I don't want to leave you with a cliffhanger, but I hope to show you a way, how to treat a reactive approach in the next chapters.

## Where to go after

- http://reactivex.io
- https://github.com/ReactiveX/RxSwift
- https://refactoring.guru/


