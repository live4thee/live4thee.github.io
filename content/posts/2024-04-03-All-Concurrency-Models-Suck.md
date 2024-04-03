---
title: "[zz] All Concurrency Models Suck"
date: 2024-04-03T09:37:37+08:00
tags: [ "c++" ]
categories: [ "programming" ]
draft: false
---

本文内容转载自[webarchive](https://web.archive.org/web/20170718202612/https://plus.google.com/+KentonVarda/posts/D95XKtB5DhK),
2013/11/15. 作者是 Kenton Varda, 前 CloudFlare 工程师，[cap'n proto](https://capnproto.org/)的主要作者之一。
[原始讨论](https://groups.google.com/g/capnproto/c/0mnM1FqWLMc/m/KcWSkn5ehncJ)包含一些其他内容，不在 webarchive 里。

## Threads

- Locking is hard.  Not enough and you corrupt memory randomly, too
  many and you deadlock randomly.
- Lockless is harder, and only works in restricted use cases.
- OS threads are expensive, while green threads suffer from similar
  problems to even loops -- while still having the other problems of
  threads.
- Trying to multiplex RPCs over a network connection?  Now you need an
  extra context switch whenever you receive a message on it.
  
## Event loops / actors

- Your interface must specify whether it can block.  Realize later you
  need to block somewhere?  Time to rewrite EVERYTHING.
- If you just assume everything could block and make all APIs
  asynchronous, performance suffers from bookkeeping overhead and code
  is painful to write.
- Pretty much everything has to be heap-allocated.
- An uncooperative event callback can cause starvation.
- It's hard to get optimal resource utilization, because in practice
  you can only use the CPU or main memory or the disk at any
  particular time.  Sure, there are supposedly APIs for asynchronous
  disk I/O, but in reality they are hard to use, their implementations
  are not well-optimized, and lots of disk I/O actually happens
  through virtual memory (whether swap or mmap()-based) which
  obviously cannot be asynchronous.  Using main memory and CPU
  simultaneously requires hyperthreading, which of course requires
  threading.

## Producer/consumer, publish/subscribe

- Great for Big Data processing, but doesn't fit the request/response
  model of interactive software or most fine-grained processing.

## Pure functional

- Let's be honest; your program probably has state, and you aren't
  smart enough to transform it into one that doesn't.
- Despite functional code being inherently parallel, the magical
  compiler that can parallelize it has yet to be invented.

## Transactional Memory

- May allow event loops to utilize multiple CPUs while still appearing
  sequential.  Doesn't realistically solve the other problems with
  event loops.
- May make mutex locking cheaper.  Doesn't make it easier.
