---
title: "Notes on Unknown (2)"
date: 2024-11-20T10:02:51+08:00
tags: [ "mm", "sport", "rdma" ]
categories: [ "linux", "life" ]
draft: false
---

## 天渐冷

本月跑量目前已经 84.3 公里，灵白[魔鬼线](https://www.douyin.com/video/7230763567904066868)山路徒步 8 公里，
其中还有一段比较陡峭的崖降。刺激。

## 小本本

### vmscan 问题

请教了F老师后，[奇怪的 vmscan 问题]({{< ref "/posts/2024-11-09-notes-on-unknown" >}})得到了还算合理的解释。
目前看来比较高的可能性是内存分配在 NUMA 节点上远不均匀：NUMA 0 上的 free 水位低过 high 水位，触发了内存回收。

```sh
# 下面是比较均匀的场景
$ grep -A50 '^Node.*Normal' /proc/zoneinfo  | grep -A3 'pages free'
  pages free     24244615
        min      259039
        low      323798
        high     388557
--
  pages free     19050868
        min      263110
        low      328887
        high     394664

# 出现 vmscan 的时候
$ grep -A50 '^Node.*Normal' /proc/zoneinfo  | grep -A3 'pages free'
  pages free     349878
        min      259039
        low      323798
        high     388557
--
  pages free     1978028
        min      263622
        low      329399
        high     395176
```

此外，如果内存分配在 NUMA 节点上已经非常不均匀，开启 `numad` 后再跑业务，
会观测到更多的 vmscan: 除了 `mm_shink_slab`, `wakeup_kswapd` 之外，还
会出现 `direct_reclaim`. 从而导致性能波动更大。

1. Debian 的 `libtcmalloc-minimal4` 来自[gperftools](https://github.com/gperftools/gperftools)，并不感知 NUMA; 
2. [google/tcmalloc](https://github.com/google/tcmalloc)里[实现了 NUMA 感知](https://github.com/google/tcmalloc/commit/ef7a3f8d794c42705bf4327ca79fa17186904801)。

### RWF_UNCACHED

W老师提及了[RWF_UNCACHED](https://mp.weixin.qq.com/s/SvHSM_qwcppRMJEmDda1GQ), 不
过该功能还在 Jens Axboe 的仓库里。

### RDMA 数据异常

最近碰到的一个偶现问题，数据量大的时候可能会发生。通过加日志对 RDMA 连
接做标识、以及对 RPC 做标识后发现：一个 RDMA 连接上的两个（相邻？）RPC
在接收端出现了数据错误。把错误数据 dump 出来后和原始请求数据做比较应该
会有所发现。
