+++
title = "Java Thread States"
description = ""
date = "2018-05-11T19:12:23+08:00"
tags = ["java"]
categories = ["programming"]
+++

根据 Oracle 的
[官方文档](https://docs.oracle.com/javase/8/docs/technotes/guides/troubleshoot/tooldescr034.html)
，Java 线程有如下状态：

状态          | 描述
--------------|------------
NEW           | 刚创建的新线程
RUNNABLE      | 线程正在JVM内执行
BLOCKED       | 线程阻塞在 monitor lock
WAITING       | 线程无限等待其他线程的某个特定动作
TIMED_WAITING | 同上，只是有时间限制
TERMINATED    | 线程已经结束

不过，用 VisualVM 看的时候，我们会看到如下状态：

![vsvm-state](/media/visualvm-states.png)

因为，VisualVM 对状态做了映射。根据
[StackOverflow](https://stackoverflow.com/questions/27406200) 的解释：

Java     | VisualVM
---------|--------
BLOCKED  | Monitor
RUNNABLE | Running
WAITING/TIMED_WAITING | Sleeping/Park/Wait
TERMINATED/NEW | Zombie

其中：

VisualVM | Description
---------|------------
Sleeping | specifically waiting in Thread.sleep()
Park     | specifically waiting in sun.misc.Unsafe.park() via LockSupport

如下操作会导致线程进入 TIMED_WAITING 状态：

1. Thread.sleep(sleeptime)
2. Object.wait(timeout)
3. Thread.join(timeout)
4. LockSupport.parkNanos(timeout)
5. LockSupport.parkUntil(timeout)

不知道 VisualVM 为啥要做这种状态映射，估计是为了区分等待原因。最后，附
上 Java 线程生命周期的状态机：

![state-machine](/media/java-thread-states.png)
