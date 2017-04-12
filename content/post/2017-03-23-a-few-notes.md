---
categories:
- work
date: 2017-03-23T00:00:00Z
description: ""
tags:
- misc
title: A Few Notes
url: /2017/03/23/a-few-notes/
---


深水区的`bug`修复起来有点老眼昏花，有时候也有点欲哭无泪。

## 真相有时候很残酷

这一周的调试生活从测试团队刚报的一个问题开始，极端情况下物理机器分配的
问题。之前，已经修复掉了。因为测试组有远远更多的硬件资源，而且有现场，
于是立即开始了日志的分析。

头发不知道又多白了几根，几番峰回路转，结果是发现真相后，眼泪掉下来。

1. 老同志的 REST server 有 bug，导致并发高的时侯，偶而有 REST 请求被丢
   掉。这就给了我一个假象，那就是确实有创建失败。然而这其实和分配算法
   没有一点关系。

2. 测试代码中，其请求的资源总量本来就多于可以分配的资源，一定会失败。


## 真相有时候很遥远

另外一个 `bug` 是日志里观察到 `shell` 中 `mkdir -p` 失败，返回值 `-6`。
一开始以为这个错误代码是 `mkdir` 系统调用直接返回的，也就是 `-errno`。
找到`errno` 为 `6` 的是这样：

```
#define ENXIO 6 /* No such device or address */
```

查了 `mkdir` 的手册，又复查了源代码，确定它不会返回 `ENXIO`。然后突然
想起来，Linux/Unix 的 shell 返回值区间是 `[0, 255]`。比如，`exit(-1)`
会得到 `255`，`exit(-2)` 会得到 `254`，这样。

```
$ (exit -1); echo $?
255
$ (exit -2); echo $?
254
```

因此 `-6` 绝对不是 `shell` 中返回的。考虑到 `shell` 是通过 `python` 的
`subprocess` 库调用的。根据 `python` 的在线
[文档](https://docs.python.org/3/library/subprocess.html#subprocess.Popen.returncode)：

```
subprocess.Popen.returnCode

A negative value -N indicates that the child was terminated by signal N (POSIX only).
```

好吧，`6` 原来是 `SIGABRT`，至于为啥被 `abort` 了。已经太久远，环境不
在，没法研究了。只能以日志中的一些 `I/O error` 猜测当时 `I/O` 已经挂了。
