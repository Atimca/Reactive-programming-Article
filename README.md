# What is ~~RxSwift~~ ~~Combine~~ Reactive Programming?

## What is Reactive Programming

There are a lot of articles about Reactive Programming and different implementations on the internet. However, most of them about practical usage and only few about what is this reactive programming and how does it actually work. For my personal opionion it is more important to understand how this frameworks work deep inside (spoiler: nothing complicated in there actually), rather than start to use an enumerous number of traits and operators meanwhile shoting in your leg.

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

With imperative approach developer can expect that the code instructions will execute incrimentally, one by one, one at a time, in order as you have  writtem them.

With reactive approach you simply don't think about it. You think about how your system `react` on the new information

Reactive programming is a paradigm that provides an easy way to create asynchronous, event-driven programs. It helps developers who use to use an imperative pull approach, it's when we make a call of something and then wayting for the result, transfer to push approach where we don't wait for the result, we `react` on the result. In simple words our system always ready to handle new information and technicaly doesn't even bother by order of calls in program.

It's important to understand that reactive aproach is not just a way to handle asyncronus code. While usign reactive paradign you will forget about threads, race conditions and everything nearby. It's kinda not important anymore.

I assume, that most of the readers of this arctile came from iOS development. So let me make an anology. Reactive programming is Notification center on steroids, but don't worry, a conterweight of the reactive frameworks that they are more sequential and understandable.


In iOS development it's hard to do this kind of things in the one way. Because from the biginning Apple gave us several different approaches like: delegates, selectors, GCD and etc. Reactive paradigm could help solve on this problems in one fasion.








Background
In many software programming tasks, you more or less expect that the instructions you write will execute and complete incrementally, one-at-a-time, in order as you have written them. But in ReactiveX, many instructions may execute in parallel and their results are later captured, in arbitrary order, by “observers.” Rather than calling a method, you define a mechanism for retrieving and transforming the data, in the form of an “Observable,” and then subscribe an observer to it, at which point the previously-defined mechanism fires into action with the observer standing sentry to capture and respond to its emissions whenever they are ready.

An advantage of this approach is that when you have a bunch of tasks that are not dependent on each other, you can start them all at the same time rather than waiting for each one to finish before starting the next one — that way, your entire bundle of tasks only takes as long to complete as the longest task in the bundle.

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

According to wikipedia:
Reactive programming is a programming paradigm oriented around data flows and the propagation of change. This means that it should be possible to express static or dynamic data flows with ease in the programming languages used, and that the underlying execution model will automatically propagate changes through the data flow.

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




# refubrished


It extends the observer pattern to support sequences of data and/or events and adds operators that allow you to compose sequences together declaratively while abstracting away concerns about things like low-level threading, synchronization, thread-safety, concurrent data structures, and non-blocking I/O.