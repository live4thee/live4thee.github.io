+++
title = "Meet JVM OOM"
description = ""
date = "2018-04-24T23:12:09+08:00"
tags = ["java"]
categories = ["programming"]
+++

今天做了一次 Java 进程的 OOM 分析，记录一下过程。

## 初次怀疑

有同事最近反应 Java 进程没有响应，`kill -3`抓了一下`catalina.out`，
结果发现里面出现了多次 `OutOfMemory` 异常。不敢大意，遂进行分析。

首先，进程中大概有 1000 个 Java 线程，搜了一下：

```sh
# java -XX:+PrintFlagsFinal -version | grep -i stacksize
     intx CompilerThreadStackSize   = 0           {pd product}
    uintx MarkStackSize             = 4194304     {product}
    uintx MarkStackSizeMax          = 536870912   {product}
     intx ThreadStackSize           = 1024        {pd product}
     intx VMThreadStackSize         = 1024        {pd product}
openjdk version "1.8.0_131"
OpenJDK Runtime Environment (build 1.8.0_131-b12)
OpenJDK 64-Bit Server VM (build 25.131-b12, mixed mode)
```

* ThreadStackSize - Java thread 的 stack 大小
* VMThreadStackSize - JVM thread (e.g. GC thread) 的 stack 大小

我们没有设置栈的大小，堆设置为最大 4GB，一千个线程，每个线程维护单独的
栈，算下来 `1024 * 1000` 消耗 1GB，剩下 3GB 并不算捉襟见肘。

## 分析

### Reflection？

先本地用自己的环境复现。VisualVM得到的数据并不能很显眼的让人知道OOM的
原因在哪里。但过程中得知发现信息：`Reflection`占用了200MB以上的空间。
查看了一下相关代码，并未发现任何不妥。

### Jhat OOM.

用`jhat`分析内存使用，一个生产环境的内存转储文件有1.8GB。对比分析两个
文件的时候，`jhat`自己不幸报告了`OOM`后挂掉了。而用VisualVM统计占用内
存最多的对象时，VisualVM提醒“需要很多时间进行分析，是否继续？” - 确定
后，没有算出结果。转用自己的环境做对比，有了发现。

### Groovy!

`jhat`的内存对比引向了问题所在：[Groovy caches meta-methods](https://stackoverflow.com/questions/5815952).
 StackOverflow的帖子里解释了原因。我在下一篇文章里面再详细解释。

## 工具

试用了工具做分析，记录如下。其中，最大的坑是：因为我们的 Java 进程有自
己的用户，运行这些工具的时候直接用 root 会导致 attach 失败。

### jmap/jhat

```sh
sudo -u<user> jmap -clstats <pid>
sudo -u<user> jmap -dump:live,format=b,file=memdump.hprof <pid>
```

如上，`-clstats` 会打印 `ClassLoader` 的统计信息，不过一直没成功过。用
`jmap` 搜集了内存转储信息后，可以用 `jhat` 来进行分析。

```sh
jhat -stack false -port 8080 memdump.hprof
jhat -stack false -port 8080 -baseline base.hprof memdump.prof
```

`jhat`有个非常实用的功能是分析的时候制定 `baseline`，这样我们可以间隔
一段时间做两次 memdump，然后比较不同。

### jcmd

前提是运行 Java 程序的时候，指定`-XX:-OmitStackTraceInFastThrow`

```sh
sudo -u<user> jcmd <pid> GC.class_stats
```

### jstack

这个得到的内容其实和 `catalina.out` 几乎一样。

```sh
sudo -u<user> jstack <pid>
```

### VisualVM

[VisualVM](https://visualvm.github.io)可以以图形化的方式实时监控内存、
线程等活动状况。不过远程抓`Apache Tomcat`的数据折腾了几次一直连不上，
稍作了一下`tcpdump`发现网络连接其实没啥问题。由于远程没有图形环境，本
着先解决问题的原则，用`SSH`转发`X11`的办法，远程运行了`VisualVM`。

另外，`VisualVM`可以用来分析`hprof`文件，也很方便。
