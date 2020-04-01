# What is ~~RxSwift~~ ~~Combine~~ Reactive Programming?

## What is Reactive Programming

There are a lot of articles about Reactive Programming and different implementations on the internet. However, most of them about practical usage and only few about what is this reactive programming and how does it actually work. For my personal opionion it is more important to understand how frameworks work deep inside (spoiler: nothing complicated in there actually), rather than start to use an enumerous number of traits and operators meanwhile shoting in your leg.

So, what is Reactive programming?

According to Wikipedia:

```
Reactive programming is a declarative programming paradigm concerned with data streams and the propagation of change. With this paradigm it is possible to express static (e.g., arrays) or dynamic (e.g., event emitters) data streams with ease, and also communicate that an inferred dependency within the associated execution model exists, which facilitates the automatic propagation of the changed data flow.
```

Excuse me, WHAT?

![jackie](images/jackie_what.jpg)  

Ok, let's start from the begining.

Reactive programming is an idea from the late 90s that inspired Erik Meijer, a computer scientist at Microsoft, to design and develop the Microsoft Rx library, but what is it exactly?

I don't want to make one defenition of what reactive programming is. I would go to the same complicated definition from wikipedia. Better to compare imperative and reactive approaches.

With an imperative approach developer can expect that the code instructions will execute incrimentally, one by one, one at a time, in order as you have writtem them.

With reactive approach you simply don't think about it. You think about how your system `react` on the new information. In simple words our system always ready to handle new information and technicaly doesn't even bother by order of calls in program.

It's important to understand that reactive aproach is not just a way to handle asyncronus code. However, while usign reactive paradign you will forget about threads, race conditions and everything else. It's kinda not important anymore. To be trully open there's still schedulers concept nearby, but it's not so complicated and won't be covered in this article.

I assume, that most of the readers of this arcticle came from iOS development. So let me make an analogy. Reactive programming is Notification center on steroids, but don't worry, a counterweight of the reactive frameworks that they are more sequential and understandable. In iOS development, it's hard to do things in the one way. Because Apple gave us several different approaches like delegates, selectors, GCD and etc. Reactive paradigm could help solve on this problems in one fasion.

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

This even partly example looks not easy at all... Ok implementation of `RxSwift` not so simple. But let me explain myself. `RxSwift` is a advanced, highly optimized framework with a big functionality. To understand the principles of reactive world this framework doesn't fit. So, what we going to do? We going to write our own reactive library from scratch. For do this, firstly we need to understand from which parts this library consists of.

## The tale of two friends

Let me answer again on the question: What reactive programming is? Reactive programming is a friendship of two design patterns: `Iterator` and `Observer`. Let's make a quick reminder how does this patterns work.

`Iterator` is a behavioral design pattern that lets you traverse elements of a collection without exposing its underlying representation (list, stack, tree, etc.). You can read more by this [link](https://refactoring.guru/design-patterns/iterator).

`Observer` is a behavioral design pattern that lets you define a subscription mechanism to notify multiple objects about any events that happen to the object they’re observing. You can read more by this [link](https://refactoring.guru/design-patterns/observer).

How does this two fellas work together? In easy words, you use `Observer` pattern to be subscribed for new events and use `Iterator` pattern to treat streams of asynchronous events with the same sort of simple, composable operations that you use for collections of data items like arrays. It frees you from tangled webs of callbacks and thereby makes your code more readable and less prone to bugs.

**NOW ABOUT HOW TO CREATE YOUR OWN.**

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

// Output would be unpredictable, but we'd see all 5 values.
```

Ok, I went so far and did some strange custom `forEach` for Array. What is this for? We finished with some simple overview of `Iterator` pattern and let's move to `Observer`. As you remember `Observer` pattern allows to observe for some events over the object. So we have two active entities. `Observable` something that emits data and `Observer` consumes the data stream emitted by the `observable`.

// Observable is a stream with data itself and Observer is a cunsomer of this stream, who react on the new data

Let's start with `Observer`. It's a cunsomer of data stream, who can do something around this data. Let me translate, it's a class with a function inside, which calls when new data arrives:

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

`Observable` it's a data itself.

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

Maybe you've already mantioned, that out `Observable` stores all input `Observers` via subscription, which is not so great. Let's make this dependency `weak`. Swift doesn't support weak array for now, maybe for forever, so we need to handle this situation somehow. Let's imptement the entity wrapper with weak referance on it.

```swift
class WeakRef<T> where T: AnyObject {

    private(set) weak var value: T?

    init(value: T?) {
        self.value = value
    }
}
```

It's a generic object, which could held other objects weakly. Let's make some improvements to our `Observable`.

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

But I think, creating `Observer` object by hand all the time could be boring, so let's improve `Observable` to consume the closure not an object. 

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
In this case we should receive numbers from 1 to 9 in random order, because we run changes in different asynchronous queue. But for my case it was like this 

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

As you can see not that we expected. The solution is easy, let's add some thread protection.
































There are many terms used to describe this model of asynchronous programming and design. This document will use the following terms: An observer subscribes to an Observable. An Observable emits items or sends notifications to its observers by calling the observers’ methods.

In other documents and other contexts, what we are calling an “observer” is sometimes called a “subscriber,” “watcher,” or “reactor.” This model in general is often referred to as the “reactor pattern”.

Way to stop to think about threads and strart to think about sequences.


Syntaxis sugar helps to do hard things in the easy way.

Why Use Observables?  
The ReactiveX Observable model allows you to treat streams of asynchronous events with the same sort of simple, composable operations that you use for collections of data items like arrays. It frees you from tangled webs of callbacks, and thereby makes your code more readable and less prone to bugs.

![logo](images/image1.png)

How is this Observable implemented?

Who cares (actually we are, this article about this). However, who cares, while using it in your project.

- does it work synchronously on the same thread as the caller?
- does it work asynchronously on a distinct thread?
- does it divide its work over multiple threads that may return data to the caller in any order?
- does it use an Actor (or multiple Actors) instead of a thread pool?
- does it use NIO with an event-loop to do asynchronous network access?
- does it use an event-loop to separate the work thread from the callback thread?

The Observable type adds two missing semantics to the Gang of Four’s Observer pattern, to match those that are available in the Iterable type:

the ability for the producer to signal to the consumer that there is no more data available (a foreach loop on an Iterable completes and returns normally in such a case; an Observable calls its observer’s onCompleted method)
the ability for the producer to signal to the consumer that an error has occurred (an Iterable throws an exception if an error takes place during iteration; an Observable calls its observer’s onError method)
With these additions, ReactiveX harmonizes the Iterable and Observable types. The only difference between them is the direction in which the data flows. This is very important because now any operation you can perform on an Iterable, you can also perform on an Observable.


much more declarative way of doing things. you don't expect anything after your code was executed. You just react on changes in your system

Since we manipulate with collections, we could treat them as simple arrays.

https://github.com/ReactiveX/RxSwift/blob/master/Documentation/Why.md

https://github.com/ReactiveX/RxSwift/blob/master/Documentation/MathBehindRx.md

RX = OBSERVABLE + OBSERVER + SCHEDULERS
We are going to discuss these points in detail one by one.
Observable: Observable are nothing but the data streams. Observable packs the data that can be passed around from one thread to another thread. They basically emit the data periodically or only once in their life cycle based on their configurations. There are various operators that can help observer to emit some specific data based on certain events, but we will look into them in upcoming parts. For now, you can think observables as suppliers. They process and supply the data to other components.
Observers: Observers consumes the data stream emitted by the observable. Observers subscribe to the observable using subscribeOn() method to receive the data emitted by the observable. Whenever the observable emits the data all the registered observer receives the data in onNext() callback. Here they can perform various operations like parsing the JSON response or updating the UI. If there is an error thrown from observable, the observer will receive it in onError().
Schedulers: Remember that Rx is for asynchronous programming and we need a thread management. There is where schedules come into the picture. Schedulers are the component in Rx that tells observable and observers, on which thread they should run. You can use observeOn() method to tell observers, on which thread you should observe. Also, you can use scheduleOn() to tell the observable, on which thread you should run. There are main default threads are provided in RxJava like Schedulers.newThread() will create new background that. Schedulers.io() will execute the code on IO thread.

If you’re familiar with RxSwift you’ll notice that Publishers are basically Observables and Subscribers are Observers; they have different names but work the same way. A Publisher exposes values that can change and a Subscriber “subscribes” so it can receive all these changes.


ADD image that everything is sequence


People Are Afraid of usign reactive approaches like RxSwift.

## Where is it come from

Why do we need it?

Who in charge of creation?

Which variations could we use now

## How does it work?

picture of screaming guy down of the infinitive locs inside an rx

### Functional programming

## Lets make our own basic reactive framework


## Outro

I hope at least for now, reactive programming hasn't looked scary anymore. However, I hear time to time from people, that reactive way could lead us to enumorous number of sequencies flying around the project and it's very easy to shoot in your leg with this approach. I won't fight against this, and you can easily google bad style of dooing reactive. I just will try to show a simple way of living in harmony with reactive way in next chapters.

## Where to go after

- http://reactivex.io
- https://github.com/ReactiveX/RxSwift
- https://refactoring.guru/




# refubrished


It extends the observer pattern to support sequences of data and/or events and adds operators that allow you to compose sequences together declaratively while abstracting away concerns about things like low-level threading, synchronization, thread-safety, concurrent data structures, and non-blocking I/O.