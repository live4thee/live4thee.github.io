+++
title = "Pony Language"
date = 2021-05-10T20:25:57+08:00
tags = ["pony"]
categories = ["programming"]
draft = false
+++

某天电子邮箱里躺了一封关于 [Pony](https://www.ponylang.io) 的[问答](https://www.quora.com/What-is-your-experience-with-using-Pony-programming-language)。手贱点了进去，然后深受“广度优先”之害。

这篇文章来自 Pony 的设计者 Sylvan Clebsch 的口述 [Pony 早期历史](https://www.ponylang.io/blog/2017/05/an-early-history-of-pony/) ，原文读下来颇有点 [Coders at Work](https://book.douban.com/subject/3673223/) 的味道。

Clebsch 早期实现异步消息队列的时候，经常被内存相关 BUG 困扰。即使后来在其
他领域工作时，类似的问题还是鬼魅一般如影随形。过程中，Clebsch 花了很多时
间阅读关于类型系统、垃圾回收器、分布式调度相关的学术论文。可谓是积累了
相当多的学术基础。

最初的雏形基于 Dmitry Vyukov 实现的快速队列，以及撸出来的一个调度器。
这样就实现了一个 C 语言可用的 Actor 库。性能非常好，但还是经常会搞出各
种内存相关的 BUG。因此，性能虽然上去了，但是生产力并没有期望的那么高。

为了解决数据竞争（data race），很多 Actor 系统，比如 Erlang，会在发送
消息之前先复制一份。但为了追求高性能，就得放弃这种做法。“也许，可以通
过某种类型装饰来描述 Actor 的内存隔离属性？” 也许有读者会问，为啥不用
引用计数？因为这种系统通常每秒需要处理上百万个消息，因此更新上百万个引
用计数也是一笔不小的开销。此外，引用计数无法处理环形依赖。

创造一门编程的想法开始萦绕在心头 - 但是程序员界的第一法则就是：永远不
要创造一门新语言。也读到了很多精妙的论文 - 很有影响力，但也并不能完全
满足 Clebsch 的需求。因此他选择了去读博（在职） - 伦敦帝国理工学院，师从
Sophia Drossopoulou - 之前读过的很多论文的作者。

在 Sophia 的帮助之下，之前关于类型系统的一些想法得到了形式化验证。他们
把这些想法扩展到了分布式系统。随着研究生 Sebastian Blessing 的加入，他
们甚至成立了一个公司，名叫 Causality，专注于 Pony 的实现。为此，Clebsch 辞
退了在投行的工作。[^1] 从 2014 年 6 月开始，到了 2014 年 9 月，第一个
Pony 程序成功运行。

### 参考

- [Pony FAQ](https://www.ponylang.io/faq/)
- [Why we used Pony to write Wallaroo](https://blog.wallaroolabs.com/2017/10/why-we-used-pony-to-write-wallaroo/)
- [An Early History of Pony](https://www.ponylang.io/blog/2017/05/an-early-history-of-pony/)
- [Safely Sharing Data: Reference Capabilities in Pony](http://jtfmumm.com/blog/2016/03/06/safely-sharing-data-pony-reference-capabilities/)
- [Memory Tagging and how it improves C/C++ memory safety](https://arxiv.org/abs/1802.09517)

[^1]: 故事的结尾并不是勇士屠龙。公司没有成功，Clebsch 后来去了微软剑桥研究院。
