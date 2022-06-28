+++
title = "Heinrich Law"
date = 2022-06-28T20:55:35+08:00
tags = ["reading"]
categories = ["life"]
draft = false
+++

前几天有同事提到海恩法则，有点意思，因此多搜索了一下。本文的主要观点，
以及下面的海恩里奇金字塔，均来自 [Heinrich Law and industrial safety](https://thinkinsights.net/strategy/heinrich-law/)。

![Heinrich’s Pyramid](/media/Heinrichs-Pyramid.png)

[William Herbert Heinrich](https://en.wikipedia.org/wiki/Herbert_William_Heinrich) 就职
于旅游保险公司，他在 20 世纪 30 年代提出了海恩金字塔模型：每一起严重事
故的背后，必然有 30 次轻微事故以及 300 次未遂先兆。该模型在安全生产领
域获得了巨大的成功，成了[behavior-based safety](https://en.wikipedia.org/wiki/Behavior-based_safety) 理论的基
础，并被奉为圭臬。

当然，也有批评。比如，Fred Manuele [证明](https://www.assp.org/)了：轻
微事故降低的同时，严重事故的故障率可能保持不变，甚至轻微增加。

在软件工程领域，我对海恩法则持怀疑态度。理由如下：
- 软件故障有连带效应，一个小故障可能会直接引发大故障；
- 公司的 JIRA 系统 P0、P1、P2 的统计数据直觉上不符合海恩金字塔；
- 帕金森琐碎定理指出，细微的事项反而容易得到更充分的讨论。往往容易因小
  失大。
  
从软件生产者的角度，SRE 故障生命周期更为实用：预防、发现、定位、恢复和
改进。
