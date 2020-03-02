# What is ~~RxSwift~~ ~~Combine~~ Reactive Programming?

## Some history 

https://subscription.packtpub.com/book/application_development/9781787120426/1/01lvl1sec7/a-brief-history-of-reactivex-and-rxjava

It extends the observer pattern to support sequences of data and/or events and adds operators that allow you to compose sequences together declaratively while abstracting away concerns about things like low-level threading, synchronization, thread-safety, concurrent data structures, and non-blocking I/O.

Background
In many software programming tasks, you more or less expect that the instructions you write will execute and complete incrementally, one-at-a-time, in order as you have written them. But in ReactiveX, many instructions may execute in parallel and their results are later captured, in arbitrary order, by “observers.” Rather than calling a method, you define a mechanism for retrieving and transforming the data, in the form of an “Observable,” and then subscribe an observer to it, at which point the previously-defined mechanism fires into action with the observer standing sentry to capture and respond to its emissions whenever they are ready.

An advantage of this approach is that when you have a bunch of tasks that are not dependent on each other, you can start them all at the same time rather than waiting for each one to finish before starting the next one — that way, your entire bundle of tasks only takes as long to complete as the longest task in the bundle.

There are many terms used to describe this model of asynchronous programming and design. This document will use the following terms: An observer subscribes to an Observable. An Observable emits items or sends notifications to its observers by calling the observers’ methods.

In other documents and other contexts, what we are calling an “observer” is sometimes called a “subscriber,” “watcher,” or “reactor.” This model in general is often referred to as the “reactor pattern”.

Went from pull to push logic. We just react on what is going on.

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


much more declarative way of doing thing. you don't expect anything, after your code was executed. You just react on changes in your system

Since we manipulate with collections, we could treat them as simple arrays.

https://github.com/ReactiveX/RxSwift/blob/master/Documentation/Why.md

https://github.com/ReactiveX/RxSwift/blob/master/Documentation/MathBehindRx.md

According to wikipedia:
Reactive programming is a programming paradigm oriented around data flows and the propagation of change. This means that it should be possible to express static or dynamic data flows with ease in the programming languages used, and that the underlying execution model will automatically propagate changes through the data flow.

In computing, reactive programming is a declarative programming paradigm concerned with data streams and the propagation of change. With this paradigm it is possible to express static (e.g., arrays) or dynamic (e.g., event emitters) data streams with ease, and also communicate that an inferred dependency within the associated execution model exists, which facilitates the automatic propagation of the changed data flow.[citation needed]

RX = OBSERVABLE + OBSERVER + SCHEDULERS
We are going to discuss these points in detail one by one.
Observable: Observable are nothing but the data streams. Observable packs the data that can be passed around from one thread to another thread. They basically emit the data periodically or only once in their life cycle based on their configurations. There are various operators that can help observer to emit some specific data based on certain events, but we will look into them in upcoming parts. For now, you can think observables as suppliers. They process and supply the data to other components.
Observers: Observers consumes the data stream emitted by the observable. Observers subscribe to the observable using subscribeOn() method to receive the data emitted by the observable. Whenever the observable emits the data all the registered observer receives the data in onNext() callback. Here they can perform various operations like parsing the JSON response or updating the UI. If there is an error thrown from observable, the observer will receive it in onError().
Schedulers: Remember that Rx is for asynchronous programming and we need a thread management. There is where schedules come into the picture. Schedulers are the component in Rx that tells observable and observers, on which thread they should run. You can use observeOn() method to tell observers, on which thread you should observe. Also, you can use scheduleOn() to tell the observable, on which thread you should run. There are main default threads are provided in RxJava like Schedulers.newThread() will create new background that. Schedulers.io() will execute the code on IO thread.

If you’re familiar with RxSwift you’ll notice that Publishers are basically Observables and Subscribers are Observers; they have different names but work the same way. A Publisher exposes values that can change and a Subscriber “subscribes” so it can receive all these changes.


ADD image that everything is sequence

## Where is it come from

Why do we need it?

Who in charge of creation?

Which variations could we use now

## How does it work?

picture of screaming guy down of the infinitive locs inside an rx

## Three whales of reactive programming

### Iterator
https://refactoring.guru/design-patterns/iterator

### Observer
https://refactoring.guru/design-patterns/observer

### Functional programming

## Lets make our own basic reactive framework


## Where to go after

- http://reactivex.io
- https://github.com/ReactiveX/RxSwift
- https://refactoring.guru/