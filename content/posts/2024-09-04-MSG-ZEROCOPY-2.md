---
title: "MSG_ZEROCOPY (2)"
date: 2024-09-04T20:29:47+08:00
tags: [ "networking" ]
categories: [ "linux" ]
draft: false
---

不服输的F老师兴冲冲地告诉我可以稳定复现零拷贝的效果，并演示了一下，
果然很稳。`mpstat` 也很有说服力。

我拿出我的 50 GbE 环境，向F老师演示了一下：开不开没啥区别，`mpstat`
同样波澜不惊。F老师说，“我的是万兆网，我再研究一下。”

检查了 SPDK sock 模块的代码，果然是用了 `MSG_ZEROCOPY`.

9/1 跑步目标契合度得分 3%；9/3契合度得分 10%. 两个月没跑步，心率涨了10，
配速多了 60 秒。
