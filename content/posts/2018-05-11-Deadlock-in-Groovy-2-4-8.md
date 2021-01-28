+++
title = "Deadlock in Groovy 2.4.8"
description = ""
date = "2018-05-11T18:39:41+08:00"
tags = ["groovy", "java"]
categories = ["programming"]
+++

前段时间，为了解决 `GroovyShell` 中的一个内存泄漏问题，把 `groovy`
从 2.4.7 升级到了 2.4.8，没想到 2.4.8 中解决内存泄漏的时候，引入了一个
高危bug：会导致线程死锁。
c.f. [GROOVY-8067](https://issues.apache.org/jira/browse/GROOVY-8067)

`jstack` 的信息有个明显特征：一堆线程 `WAITING` 在 `LockableObject.java:37`

```
java.lang.Thread.State: WAITING (parking)
...
at org.codehaus.groovy.util.LockableObject.lock(LockableObject.java:37)
...
```

以此为关键字，搜索引擎中第一条信息就是 `jenkins-ci` 对该问题的
[讨论](https://issues.jenkins-ci.org/browse/JENKINS-43197)。

## 反思

其实这个问题之前在测内存泄漏的时候，也碰到过，每次都能重现。`VisualVM`
的图形展示很规律：两次 Full GC 后，线程活动图进入心跳停止线状态。不过
由于当时看起来绕过了这个问题，没有细揪。

## 抽象

反查到 GitHub 上该问题的
[补丁](https://github.com/apache/groovy/pull/489)，有一个不大不小的感
慨：尽量用 `Concurrent Collection` 或者 `Collections.synchronizedXXX`
而不是 `synchronized` 关键字。性能的一丁点压榨永远比不上代码的清晰、健
壮性来得重要。

## 博客

通过 GitHub 上的讨论，找到了 `Jochen Theodorou` (Groovy 项目的 Leader)
的[博客](https://blackdragsview.blogspot.com)。最后一篇文章停留在
2015/4/13，根据
[维基百科](https://en.wikipedia.org/wiki/Groovy_(programming_language))
，正是 Pivotal 停止赞助 Groovy & Grails 项目的时间点。

2018/4/20，Pivotal 在纽约证券交易所上市。
