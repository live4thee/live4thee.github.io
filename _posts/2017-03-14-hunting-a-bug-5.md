---
layout: post
title: "Hunting a Bug (5)"
description: ""
category: work
tags: [zstack]
---
{% include JB/setup %}

最近研究 `zstack`[^zs] 中一个比较诡异的
[bug](https://github.com/zstackio/issues/issues/2013)，现象是：并发创
建大量虚拟机的时候，`kvmagent` 偶尔会报告 `iptables` 操作失败，最终导
致少数虚拟机创建失败。

{% highlight plaintext %}
Another app is currently holding the xtables lock. Perhaps you want to use the -w option?
{% endhighlight %}

## 第一次尝试

显然，系统出错的那一刻 `iptables` 有多个运行实例。在 `kvmagent` 的代码
中寻找所有对 `iptables` 的操做，果然有几条漏网之鱼没有被锁同步。高高兴
兴地提交了一个
[PR](https://github.com/zstackio/zstack-utility/pull/178)，同事部署了
一个环境，没有重现。哈！

## 第二次尝试

然而另外一个同事后来发现该问题还是会重现。重新研究了一下日志，发现报错
记录中以上错误都是 *相同时间戳两两成对出现* - 我不禁开始怀疑现有的锁机
制是否有问题。

1. 单独写了测试程序，没有发现锁机制的行为异常；
2. 研究了锁机制的逻辑：
- `threading.RLock` 保证不同线程不能同时获得锁；
- `fcntl.lockf` 保证不同的进程不能同时获得锁。

`RLock` 是可重入锁，但不是重点，两个线程不能同时获得锁；`RLock` 的
`get_ident()` 得到的线程标识可能会被 recycle，但是一个进程内的活动线程
标识至少都是唯一标识的。所以，两个线程不能同时获得锁！锁机制不可能出问
题。

## 重新分析日志

明显，从锁机制入手已经进入了死胡同。重新分析一下相同时间戳报出来的出错
日志，发现了一个令人惊讶的事情：出错信息对应的消息 ID 竟然是一模一样的！
难道，同一个消息被处理了两次，又刚巧同时返回？这明显不可能（除非消息总
线代码有 bug）。核心代码已经千锤百炼，不会有这种低级错误。

然而很快便找到原因 - 对日志进行分析的分析的时候，做了多次 `grep`:

{% highlight sh %}
$ find . -type f -name \*.log | xargs grep '...' > result.log
# similar commands repeated
{% endhighlight %}

第二次 `grep` 的时候会包含 `result.log` 里面的结果。真想扇自己一个耳光。
好消息是，重新过滤了一遍以后发现：*出错的时间戳都是不一样的*。那么剩下
一个问题：当时会有哪个组件在操纵 `iptables` 呢？而且绝不是 `zstack`。

## libvirt

头号疑犯是 `libvirt`。于是在 `libvirt` 的代码库中做了一次 `git grep`，
果不其然！比如，打开 `anti-spoofing` 的时候，`libvirt` 就会设置相应的
防火墙规则。`libvirt` 会尽可能的使用 `iptables -w`，但是 `libvirt` 并
不是 `iptables` 的唯一操纵者。后来问了一下同事，能重现的环境果然是打开
了 `anti-spoofing` 的。又回到和同事经常一起报怨的问题：*Unix/Linux 很
多命令行工具都不是设计作为被“编程”使用的* - 体现在：

1. 配置接口不方便；
2. 多数默认不支持并发；
3. 默认参数配置有待商榷，比如：
- `iptable` 默认没有 `-w`，当然，这个选项是后来加上的。
- 同理，`ebtables` 的 `--concurrent` 选项。

[^zs]: ZStack, http://zstack.org
