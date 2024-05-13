---
title: "Strange Latency Issue"
date: 2024-05-13T10:27:34+08:00
tags: [ "sched" ]
categories: [ "linux" ]
draft: false
---

最近碰到一个奇怪的问题。有个多线程应用，其中一个线程中的伪代码如下：

```c
gettimeofday(&begin, NULL);
foo(); // 同步过程调用
gettimeofday(&end, NULL);

usleep(N);
```

其中，`end-begin` 得到 `foo()` 的耗时 `T`. 目前可以稳定重现下面的行为：
T 的大小和 N 正相关。

疑点之一：通过 perf trace -S 可以看到，除了执行 `usleep()` 的线程之外，
其他线程的 `futex()` 耗时也显著增高了。
