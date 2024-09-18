---
title: "RDMA Networking - Intro"
date: 2024-06-12T09:59:23+08:00
tags: [ "networking", "rdma" ]
categories: [ "programming" ]
draft: false
---

## 前言

最近给[Seastar](https://github.com/scylladb/seastar)增加 RDMA 网络支持，
接触了一堆资料。比如：

- futurewei 的 [chogori-seastar](https://github.com/futurewei-cloud/chogori-seastar-rd)
- bRPC 的 [RDMA 支持](https://github.com/apache/brpc/blob/master/docs/cn/rdma.md)
- spdk 的 [RDMA 相关代码](https://github.com/spdk/spdk/tree/master/lib/rdma)
- 文档、示例比较全面的 [rdma-core](https://github.com/linux-rdma/rdma-core)
- 最后，[Dotan Barak](https://www.rdmamojo.com/about/)的[rdmamojo.com](https://www.rdmamojo.com/)

修改示例、运行示例，再了解一些硬件特性 -- 所谓“[Mechanical Sympathy](https://dzone.com/articles/mechanical-sympathy)”，基本上能掌握一个大概。

> “You don’t have to be an engineer to be be a racing driver, but you
> do have to have Mechanical Sympathy.” – Jackie Stewart, racing driver.

好记性不如烂笔头。这里记一些基础知识，主要来自 Rohit Zambre 的[博客](https://www.rohitzambre.com/blog/category/User-level%20Networking)。

## 相关名词解析

### InfiniBand & IB Verbs API

根据 Red Hat 的文档，InfiniBand 有[两个不同的含义](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/networking_guide/ch-configure_infiniband_and_rdma_networks)：

- InfiniBand 网络的物理链接层协议；
- 高级编程接口，InfiniBand Verbs API, 也就是文档中常见的 IB verbs API
  (libibverbs).
  
和传统上基于 socket 的 TCP/IP 编程接口不同，IB 允许 RDMA 操作。IB
verbs API 就是用户态的 RDMA 编程规范接口。IB verbs API 下层可以是 IB网
络，也可以是 RoCE v1、RoCEv2 或者 iWRAP.

![RDMA Networks](/media/rdma-networks.png)

IB规范由[IBTA](https://www.infinibandta.org/ibta-specification/)定义，
目前最新的规范是
[v1.7](https://www.infinibandta.org/wp-content/uploads/2023/07/IBTA-Overview-of-IBTA-Volume-1-Release-1.7-2023-07-11.pdf),
需要成员资格才能下载。IB 规范分为软件规范和硬件规范，软件规范主要定义
的就是 Verbs API.

> `libibverbs` is the software component (Verbs API) of the IB
> interface. As `sockets` is to TCP/IP, `libibverbs` is to IB.

### OFED & MOFED

[OFED](https://www.openfabrics.org/ofed-for-linux/) (Open Fabric Enterprise Distribution) 
是以开源软件方式发布的 RDMA 以及 kernel bypass 应用，分为用户态和内核
态两部分。

- 用户态 API 包含在 [rdma-core](https://github.com/linux-rdma/rdma-core)；
- 内核态驱动在 [Linux 内核](https://git.kernel.org) 的 [driver/infiniband](https://github.com/torvalds/linux/tree/master/drivers/infiniband)目录。

MOFED (Mellanox OFED) 包含一些针对 Mellanox 硬件的优化。

正如 drivers/infiniband 包含了若干厂家驱动，rdma-core 通过
[providers](https://github.com/linux-rdma/rdma-core/tree/master/providers)
方式包含厂家的用户态驱动。

### OFI & libfabric

[OFI](https://github.com/ofiwg/ofi-guide/blob/master/OFIGuide.md)
(OpenFabric Interface) 是一个编程框架，由 OFIWG 维护，聚焦于向应用提供
fabric communication 服务。OFI 框架的设计目标是用来满足 HPC 等相关场景
下的性能和扩展需求。作为 OFI 的实现，下图是 libfabric 的构架图：

![libfabric](/media/libfabric.png)

OFI 分为两大组件：

- OFI framework: 实现通用服务；
- Providers: 向 OFI 框架提供具体硬件服务，比如：socket provider (TCP),
  UDP provider, 其它 providers 包括：InfiniBand, Cray Aries networks
  (uGNI), CISCO usNIC or Intel Omni-Path Architecture (PSM2) 等等。

使用 libfabric 框架编程只需要配置好正确的 provider，而不必直接使用底层
编程接口。

### UCX

和 libfabric 类似，[UCX](https://openucx.org/) (Unified Communication
X)也是一个高性能的开源、产品级的统一通信框架。

![UCX](/media/ucx.png)

MUG (MVAPICH User Group)做了一个[比较](https://mug.mvapich.cse.ohio-state.edu/static/media/mug/presentations/23/MUG23TuesdayBrianSmith.pdf)：

![UCX vs libfabric](/media/ucx-libfabric.png)

### librdmacm

和 socket 一样，使用 RDMA 进行通信的前提是先要[建立连接](https://www.rdmamojo.com/2014/01/18/connecting-queue-pairs/)。
在RDMA 协议下，建立连接意味着交换通信两端的 QP 信息，并切换 QP 状态。
不同的连接方式（UD、UC、RC）下，需要交换或设置的信息略有不同。bRPC 的
实现是通过 TCP 做前置信息交换，并建立 RC 连接。chogori-seastar 建连
则不依赖 TCP.

因为建连琐碎而易错，因此 rdma-core 中包含了 librdmacm (connection
manager) 用来专门做 RDMA 的连接管理。对于 iWRAP, 这也是唯一的建连方式。
对于 IB 或者 RoCE 则可以纯用 libibverbs, 或者用librmdacm 建连、用Verbs
API 做数据通信。
