+++
title = "Future & Promise"
date = 2023-11-21T11:46:08+08:00
tags = ["java", "c++"]
categories = ["programming"]
draft = false
+++

基于异步事件的编程框架基本上都有 `Future` 和 `Promise` 的概念。比如，
主流编程语言中 C++11 有
[std::future](https://en.cppreference.com/w/cpp/thread/future) 和
[std::promise](https://en.cppreference.com/w/cpp/thread/promise), 而
Java 1.5 开始有
[Future](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/Future.html),
Java 1.8 有
[CompletableFuture](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/CompletableFuture.html).


Future & Promise 本质上是同一个计算的两个方面：[^ans]

- 对于调用者而言，调用某异步会立即返回。代价是调用返回的 Future 中可能
  并不包含计算结果，但包含对 Promise 的引用；

- 对于异步方法的实现者而言，它需要立即返回一个 Future 给调用者，同时需
  要运行异步任务（比如，通过提交任务到运行任务队列的线程池之类），得到
  结果后填入 Future 中的 promise 对象。

对于调用者，Future 只读；对于实现者，promise 可写（通常只写一次）。
[这里](http://dist-prog-book.com/chapter/2/futures.html)有更详细的讨论。


[^ans]: [What's the difference between a Future and a Promise?](https://stackoverflow.com/questions/14541975/whats-the-difference-between-a-future-and-a-promise)
