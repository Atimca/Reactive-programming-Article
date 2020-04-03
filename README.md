# What is ~~RxSwift~~ ~~Combine~~ Reactive Programming?

There are a lot of articles about Reactive Programming and different implementations on the internet. However, most of them about practical usage and only few about what this reactive programming is and how does it actually work. For my personal opionion it is more important to understand how frameworks work deep inside (spoiler: nothing complicated in there actually), rather than start to use an enumerous number of traits and operators meanwhile shoting in your leg.

So, what is Reactive programming?

According to Wikipedia:

```
Reactive programming is a declarative programming paradigm concerned with data streams and the propagation of change. With this paradigm it is possible to express static (e.g., arrays) or dynamic (e.g., event emitters) data streams with ease, and also communicate that an inferred dependency within the associated execution model exists, which facilitates the automatic propagation of the changed data flow.
```

Excuse me, WHAT?

![jackie](images/jackie_what.png)  

Ok, let's start from the begining.

Reactive programming is an idea from the late 90s that inspired Erik Meijer, a computer scientist at Microsoft, to design and develop the Microsoft Rx library, but what is it exactly?

I don't want to make one defenition of what reactive programming is. I would go to the same complication from wikipedia. Better to compare imperative and reactive approaches.

With an imperative approach developer can expect that the code instructions will execute incrimentally, one by one, one at a time, in order as you have writtem them.

Reactive approach is not just a way to handle asyncronus code it's a way to stop to think about threads and strart to think about sequences. It allows you to treat streams of asynchronous events with the same sort of simple, composable operations that you use for collections of data items like arrays. You think about how your system `react` on the new information. In simple words our system always ready to handle new information and technicaly doesn't even bother by order of calls in a program.

I assume, that most of the readers of this arcticle came from iOS development. So let me make an analogy. Reactive programming is Notification center on steroids, but don't worry, a counterweight of the reactive frameworks that they are more sequential and understandable. Moreover in iOS development, it's hard to do things in the one way. Because Apple gave us several different approaches like delegates, selectors, GCD and etc. Reactive paradigm could help solve on this problems in one fasion.

In this article I will use concepts of the main popular reactive framework for iOS: RxSwift (open source based) and Combine (iOS 13+ Apple developers based). The minimum iOS version for Combine is the one the most reasons, why we still considering third party frameworks like RxSwift for development.

Ok, sounds quite simple. Let's take a look on a couple of functions in one class in `RxSwift` implementation:

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

This even partly example looks not easy at all... Ok implementation of `RxSwift` not so simple. But let me explain myself. `RxSwift` is an advanced, highly optimized framework with big functionality. To understand the principles of reactive world this framework doesn't fit. So, what we going to do? We going to write our own reactive solution from scratch. To do this, firstly we need to understand which parts this library consists of.

## The tale of two friends

Let me answer again on the question: What reactive programming is? Reactive programming is a friendship of two design patterns: `Iterator` and `Observer`. Let's make a quick reminder how this patterns work.

`Iterator` is a behavioral design pattern that lets you traverse elements of a collection without exposing its underlying representation (list, stack, tree, etc.). You can read more by this [link](https://refactoring.guru/design-patterns/iterator).

`Observer` is a behavioral design pattern that lets you define a subscription mechanism to notify multiple objects about any events that happen to the object they’re observing. You can read more by this [link](https://refactoring.guru/design-patterns/observer).

How these two fellas work together? In easy words, you use `Observer` pattern to be subscribed for new events and use `Iterator` pattern to treat streams like sequences.

**Iterator**

Let's start from the begining. From `Iterator` pattern.

Here's a simple sequence of integers:
```swift
let sequence = [1, 2, 3, 4, 5]
```

And I want to interate through it. Easy enough:
```swift
var iterator = sequence.makeIterator()

while let item = iterator.next() {
    print(item)
}

// 1 2 3 4 5
```
  
However, I think that everybody would call this method of iteration via sequence a little bit weird. Let's do the proper one:
```swift
sequence.forEach { item in
    print(item)
}

// 1 2 3 4 5
```

Ok, now it looks more natural I hope. I used `forEach` method on purpose. `forEach` has this signature `func forEach(_ body: (Element) -> Void)`. It's a function which take a function(handler) as an argument and perform this handler over the sequence. Let's try to build `forEach` by ourself.

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

Ok, I went so far and did some strange custom `forEach` for Array. What is this for? We finished with some simple overview of `Iterator` pattern and let's move to `Observer`.

There are many terms used to describe this model of asynchronous programming and design. This article will use the following terms: An `Observer` subscribes to an `Observable`. An `Observable` emits items or sends notifications to its observers by calling the observers’ methods.

It other words: `Observable` is a stream with data itself and `Observer` is a cunsomer of this stream, who reacts on the new data.

Let's start with `Observer`. As I said it's a cunsomer of data stream, who can do something around this data. Let me translate, it's a class with a function inside, which calls when new data arrives:

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

`Observable` it's a data itself. Let's make it simple for the first iteration.

```swift
class Observable<Element> {

    var value: Element

    init(value: Element) {
        self.value = value
    }
}
```

Also `Observable` should allow to `subscribe` of consumer of this data. And via changing of this data in `Observable` `Observer` neads to know about this changes.

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
And it works! But hold on for a sec let's add some modifications, before we go further.

Maybe you've already mentioned, that our `Observable` stores all input `Observers` via subscription, which is not so great. Let's make this dependency `weak`. Swift doesn't support weak array for now, maybe forever, that's why we need to handle this situation somehow. Let's imptement the class wrapper with weak referance on it.

```swift
class WeakRef<T> where T: AnyObject {

    private(set) weak var value: T?

    init(value: T?) {
        self.value = value
    }
}
```

It's a generic object, which could hold other objects weakly. Let's make some improvements to our `Observable`.

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
Ok, for now `Observer`s not holded by `Observable`. Let's try this out and create two observers.

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

As you can see, the second `Obsesrver` was destroyed after `2` which proves workability of our code.

But I think, creating `Observer` object by hand all the time could be boring, so let's improve `Observable` to consume a closure not an object. 

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

Let's do some asynchronous stress test for our `Observable`.

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
In this case we should receive numbers from 1 to 9 in random order, because we run changes in different asynchronous queue. However for my case it was like this 

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

As you can see it's not that was expected. Race condition happens and it should be fixed. The solution is easy, let's add some thread syncronisation. There are several options how to achive this, but I'll use method with dispatch barrier. Here's the solution.

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

The same test as previously gave me the result.

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
This time it's even in the right order, but it's not granted. Now our reactive framework has thread syncronisation.

There's another difference between vanila `Observer` pattern and most of the reactive frameworks. Usually, as an `Element` from `Observable` you consume not just an `Element`, but some kind of `Event` structure, which looks like this.

```swift
enum Event<Element> {
    case next(Element)
    case completed
    case error(Error)
}
```

Kinda handy solution, because you can handle situation when your sequence completed or received an error. I don't want to spend time for adopting this practice right now, I think it doesn't metter in the big picture of understanding the concept.

**Let's compose `Observer` and `Iterator`**

One of the killer feartures for reactive programming is possibility to treat your `Observable` `sequence` as a `Sequence` I think everybody knows this handy functions like `map`, `flatMap`, `reduce` and so on. As an example, let's try to add to our `Observable` the `map` function. But firstly let's remember how does it work with a simple array.

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

True `map` function would have this structure `func map<T>(_ transform: @escaping (Element) -> T) -> Observable<T>`, but for a sake of simplicity of this article I just added this `func map(_ transform: @escaping (Element) -> Element) -> Observable<Element>`. I hope you can forgive me and understood the point. 

Actually we've done with our own reactive framework, congratulations to everybody who followed untill the end. It's super simplified but it works. Gist with a last iteration of this article you can find [here](https://gist.github.com/Atimca/51c83f4c9161fc36bed340b02e605d09).

## Outro

I hope at least for now, reactive programming hasn't looked scary anymore. However, I still hear time to time from people, that reactive way could lead us to enumorous number of sequencies flying around the project and it's very easy to shoot in your leg with this approach. I won't fight against this, and you can easily google bad style of dooing reactive. I don't want to make any cliffhangers, but I hope to show you a way, how to treat reactive approach in the next chapters.

## Where to go after

- http://reactivex.io
- https://github.com/ReactiveX/RxSwift
- https://refactoring.guru/