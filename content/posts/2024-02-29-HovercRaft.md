---
title: "HovercRaft"
date: 2024-02-29T16:44:40+08:00
tags: [ "paper" ]
categories: [ "programming" ]
draft: true
---

一起读论文：[HovercRaft: Achieving Scalability and Fault-tolerance for
microsecond-scale Datacenter Services](https://infoscience.epfl.ch/record/276586).
来自 EPFL（洛桑联邦理工学院），发表在 EuroSys '20. [slides](https://www.eurosys2020.org/wp-content/uploads/2020/04/slides/423_kogias_slides.pdf)

## 背景简介

云平台的服务一般需要满足三个基本需求：可扩展、低（尾）延迟、容错。其中，

- 可扩展性一般通过放松一致性要求而达成；
- 容错则要求状态机复制 (SMR) 的一致性。

这两个需求在实现上互相掣肘。系统添加节点后，往往需要牺牲一致性从而提高
性能；或者，牺牲性能提高可用性或一致性。

论文阐述了一个名为 'HovercRaft' 的 Raft 协议扩展，思路是消除 CPU、I/O
瓶颈，对请求做负载均衡。实现上的三板斧：kernel-bypass 技术、数据中心传
输协议、网内加速 (in-network acceleration).

![HovercRaft](/media/hoverc-raft.png)

图中，

- L/F 分别指 Leader/Follower;
- R2P2 是 EPFL 提出的一个面向数据中心 RPC、基于 UDP 的协议，USENIX ATC '19 [论文](https://www.usenix.org/conference/atc19/presentation/kogias-r2p2)

## 论文的贡献

### 两个问题

1. 可否以一种应用透明的方式，让应用通过 SMR 达成容错？
2. 在问题一的基础上，怎么让应用的性能也得到提高？

### 三个贡献

- 在 R2P2 的基础上实现了 Raft；
- 提出 HovercRaft - 利用 R2P2 的内置特性系统化地消除 SMR 相关的 CPU, I/O 瓶颈；
- 利用 in-network 加速器消除扩展性瓶颈。

## 设计

### 感知 SMR 的 RPC 层

一句话：把 SMR (state-machine replication) 放在 RPC 层实现。论文选择在
R2P2 之上实现了 Raft, 出于如下考虑：

- R2P2 支持 in-network 加速；
- R2P2 把 target/replier 分离，易于做 LB.

![SMR-aware RPC layer](/media/smr-aware-rpc.png)

在 SMR 语义的选择上，倾向于 Raft 而不是 Paxos 及其变种 - 因为前者有
strong leader (可以利用集群的全局视图信息) 以及 in-order commit (简化
了in-network 加速). 这里提到了另一篇论文 [OUM & NOPaxos](https://www.usenix.org/conference/osdi16/technical-sessions/presentation/li),
来自 OSDI '16.

### Replication 和 Ordering 分离

Raft Leader 有两个重要职责，在 AppendEntries RPC 中实现：

- 向 Follower 复制数据；
- 让 Follower 按顺序 `apply()` 数据。

一个 LogEntry 在 Leader 以及至少一个 Follower 写入日志后，才能把
`commitIndex` 向前推进。因此 Leader 的 I/O 能力会是集群的瓶颈。论文的
解决办法是把两者分离：

- 复制 LogEntry 是乱序的，client 通过 IP multicast 向 (pre-defined)
  Raft Group 内的所有节点发送请求；
- `apply()` 的保序则通过修改过的 RPC 请求实现 - 此时 RPC 请求里面包含
  了 LogEntry 的信息 - 通过三元组 `(req_id, src_port, src_ip)` 唯一寻
  址。但是没有数据了，数据已经实现通过 IP multicast 传到了相关节点。

### 回复的负载均衡

Raft 协议中，client 向 Leader 提交请求，请求处理的回复来自 Leader 节点。
只要 Follower 能及时 `apply()` 日志，也能向 client 回复请求。

由于 Leader 具有集群内的全局视野，因此它可以调度请求的回复者。论文为
Raft 日志增加了 `replier` 只读字段，匹配该字段的节点负责回复请求。也因
此，论文采用了 R2P2 -- 允许处理请求的节点不同于回复请求的节点。

### Bounded Qeueue

Join-Bounded Shortest Queue (JBSQ) 是 EPFL 的 R2P2
[论文](https://www.usenix.org/conference/atc19/presentation/kogias-r2p2)
里首先提出的。SOSP '23 有一篇讨论使用近似最优调度降低 tail latency 的
[论文](https://dslab.epfl.ch/pubs/concord.pdf)，
里面也应用了 JBSQ，主作者也还是来自 EPFL.

JBSQ 是个建立在队列上的调度系统，每个节点上未完成的未完成请求都设有一
个上限 -- 因此节点故障的场景下，失败的请求也有个上限。通过 JBSQ, 调度
逻辑还可以感知节点的负载，从而更好的做负载均衡。这里隐隐约约有点 Amazon
[Aurora](https://pdos.csail.mit.edu/6.824/papers/aurora.pdf) 的影子。

### Load Balancing Read-only Operations

让只读请求走 Raft 共识协议显然会有不小的性能影响。因此，通常有两种绕过
共识协议的优化方法：`readIndex` 或者 `readLease`. 本论文通过结合前述
`replier` 字段以及 JBSQ, 可以实现一个全局较优的回复节点选择算法。

## HovercRaft++

这部分是通过 P4 实现网内加速，需要交换机支持。
