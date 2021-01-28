+++
categories = ["work"]
date = "2017-06-30T20:40:31+08:00"
description = ""
tags = ["storage"]
title = "DRBD Split-Brain"
url = "/2017/06/30/DRBD-Split-Brain/"
+++

上午正在聚精会神写代码的时候，QA团队的同事说，一个测试环境的DRBD集群貌
似出了问题，数据不一致。心里一个惊，真是怕啥来啥。一边疑惑着“不应该啊”，
一边看日志。然后，发现两个节点在非常相近的时间内，同时出现了：

```text
fence handler: this is survivor, will resume-io.
```

然后内核的日志：

```text
Split-Brain detected but unresolved, dropping connection!
```

百思不得其解。重新思想验证了考虑过的各种情况，还是没有头绪。康书记不知
道啥时候突然站在身后：“你这个不得行啊！没两天就脑裂了。”我也很绝望。不
应该啊！

## 原理

然而“天无绝人之路”。偶然看见了 DRBD 作者之一，`Lars Ellenberg` 在邮件
列表解释的脑裂检测
[工作原理](http://lists.linbit.com/pipermail/drbd-user/2009-March/011630.html)
，顿时豁然开朗。

脑裂在节点不能互相通信的情况下发生，而且只有节点恢复通信后才能检测到。
这意味着，要从脑裂状态恢复，必须要选择一台节点作为牺牲品，其数据会被覆
盖。因此，脑裂越早检测到，分叉的数据越少。

当 DRBD 主节点[^1] 无法和它的对等节点[^2]通信时，会新生成一个 uuid，并
记录此后写入的数据。同时，DRBD 也会维护一些历史上用过的 uuid。当节点之
间恢复连接时，会校验当前 uuid，如果发现对方的 uuid 并不在自己的历史记
录中，那么显然，发生了脑裂。

## 复盘

因为 DRBD 初始化磁盘镜像纯走网络会比较慢，因此我采用了所谓
[Truck Based Replication](https://docs.linbit.com/doc/users-guide-90/ch-admin-manual/#s-using-truck-based-replication).
它在保证两块磁盘数据已经一致的情况下，通过设置相同 uuid 的方法，让
DRBD 以为两块磁盘已经同步好了。

由于 QA 同事测试我的 bugfix 时，会在已有环境重新初始化节点，此时两台拥
有网络连接的节点中，一台节点的 uuid 会被人为强制修改。这样，立刻触发了
对等节点的脑裂检查逻辑。

[^1]: Node in **primary** role.
[^2]: Peer node.
