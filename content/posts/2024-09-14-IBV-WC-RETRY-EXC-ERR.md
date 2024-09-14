---
title: "IBV_WC_RETRY_EXC_ERR"
date: 2024-09-14T09:42:27+08:00
tags: [ "networking", "rdma", "seastar", "c++" ]
categories: [ "programming" ]
draft: false
---

记得[休假前跑通了 RDMA 网络]({{< ref "posts/2024-06-28-before-vacation" >}}), 
并在组内做了演示。看着环境 A 屏幕上飞快滚动的日志，颇为欣喜。当时的性能数据略
有点奇怪 -- 因为开着 DEBUG 信息，并未太放在心上。

## 奇怪的报错

### 意外现象

最近继续开始相关代码的改进和打磨，首先是获取性能指标。由于环境 A 被占
用，因此在环境 B 上继续做若干横向对比。去除 DEBUG 后，再次运行测试程序，
得到一行报错：

```txt
rdma.cc:851 @processRCCQ]error on send wc: transport retry counter exceeded
```

对应的代码如下：

```cpp
if (wcs[i].status != IBV_WC_SUCCESS) {
    LOG(WARNING) << "error on send wc: " << ibv_wc_status_str(wcs[i].status));
    conn->shutdownConnection();
}
```

这里，`wcs` 数组内存放的是 [`ibv_poll_cq()`](https://www.rdmamojo.com/2013/02/15/ibv_poll_cq/) 
轮询得到的 `Work Completion` 信息。

### 更多现象

加入调试日志后，可以确认以下信息：

1. 客户端通过 *ibv_post_send()* 同时发送了两份数据，一个是 RPC 头，一个是 RPC 主体；
2. 服务端收到了 RPC 头，且数据是正确的；
3. 服务端读取 RPC 主体一直收不到数据，此时客户端已经报错 *retry counter exceeded*,
4. 报错是在 QP 建连（俗称 RDMA 握手）成功之后。

## 横向对比

### 相同环境不同代码

在相同的测试环境 B，运行 `rdma-core` 自带的测试程序 `ibv_srq_pingpong`.

```sh
# 服务端 node-2
$ ibv_srq_pingpong -d mlx5_bond_0 -g 3 -n 100 -q 2
...
# 客户端
$ ibv_srq_pingpong -d mlx5_bond_0 -g 3 -n 100 -q 2 node-2
...
```

看起来没毛病，一切正常。

### 相同代码不同环境

把自己的测试程序重新在环境 A 上跑，却发现行为不一样了。客户端/服务端打
印建连日志后，客户端虽然没有报错 `retry counter exceeded`, 服务端也没
收到任何信息。遇到了新情况。

该环境前两周拿来测友商的存储，拆掉了 RoCE 的 LAG 链路聚合。交换机上也
折腾过一通 pfc/ecn. 一番检查后，找到了原因：铲掉环境后，同事重新在机器
上做 bond 的时候，三个节点中 `node-2` 上的 bond 名字配反了。也就是
`node-{1,3}` 节点上对应的 `mlx5_bond_{0,1}` 分别对应 `node-2` 上的
`mlx5_bond_{1,0}`.

测试程序指定正确的 RDMA 设备后，再次碰到了 `retry couter exceeded`. 当
然，这个环境里 `ibv_srq_pingpong` 也没问题。回到原点。

## 错误码说明

Dotan Barak 大神对该错误码做了[一份说明](https://www.rdmamojo.com/2013/02/15/ibv_poll_cq/):

> **IBV_WC_RETRY_EXC_ERR** (12) - Transport Retry Counter Exceeded:
> The local transport timeout retry counter was exceeded while trying
> to send this message. This means that the remote side didn't send
> any Ack or Nack. If this happens when sending the first message,
> usually this mean that the connection attributes are wrong or the
> remote side isn't in a state that it can respond to messages. If
> this happens after sending the first message, usually it means that
> the remote QP isn't available anymore. Relevant for RC QPs.

总结下来，有下面几个意思：

1. 服务端可能没有发送 Ack 或 Nack;
2. 如果发送第一条信息就报错，可能是连接参数错误或者远端当时无法回复；
3. 如果是发送第一条后报的错，可能是远端的 QP 已经不在了；
4. 只在 RC 类型的 QP 下会发生。

## 反复实验

先把代码改成一条一条消息串行发送，并且设置上：

```cpp
    send_wr->send_flags = IBV_SEND_SIGNALED;
```

可以确认：确实是发送第一个 RPC 头的时候就报了`IBV_WC_RETRY_EXC_ERR`.

当然更有意思的是，服务端也确实成功收到了正确的 RPC 头。由于 QP 建立连
接已经完成，如果是连接参数错误，反过来可以说明：

> 通过调用 `ibv_modify_qp()` 把状态机一路推进到 `RTR` 再到 `RTS` 后，
> 即使没有报错，**也不能**保证 `qp_attr` 中填写的连接参数都是正确的。

### 对比建连过程

对比测试代码和 `ibv_srq_pingpong` 客户端的建连逻辑，发现一处微小的区别：

> 前者的 `qp_attr.path_mtu` 设置为 `IBV_MTU_4096`, 后者则是
> `IBV_MTU_1024`.

查看了一下 SPDK 的代码：

```sh
$ git grep IBV_MTU
lib/mlx5/mlx5_qp.c:     conn_caps->mtu = IBV_MTU_4096;

$ git grep -w path_mtu
lib/mlx5/mlx5_qp.c:             DEVX_SET(qpc, qpc, mtu, qp_attr->path_mtu);
lib/mlx5/mlx5_qp.c:     qp_attr.path_mtu = caps->mtu;
module/accel/mlx5/accel_mlx5.c: attr.path_mtu = cur_attr.path_mtu;
```

改成 `IBV_MTU_1024` 后，果然成功了。单线程单深度网络性能比现有框架提高
了整整一倍出头。

### 验证 MTU 的影响

`ibv_srq_pingpong` 可以指定 MTU（默认是 1024）.

```sh
# 服务端 node-2
$ ibv_srq_pingpong -d mlx5_bond_0 -g 3 -n 100 -q 2 -m 4096
...
# 客户端
$ ibv_srq_pingpong -d mlx5_bond_0 -g 3 -n 100 -q 2 -m 4096 node-2
...
Failed status transport retry counter exceeded (12) for wr_id 2
```

果然报了同样的错误。

### MTU 的设置

IBM 有一份文档，[Setting the MTU size](https://www.ibm.com/docs/en/linux-on-systems?topic=functions-set-mtu),
写的很清楚：RoCE 模式下，网卡其实有两个 MTU 值：

1. 以太网的 MTU;
2. InfiniBand 接口的 MTU - 也就是 IBoE (IB over Ethernet) MTU.

后者是通过前者算出来的，无法直接设置。内核里找到这样一段代码：

```c
/* include/rdma/ib_addr.h */
static inline enum ib_mtu iboe_get_mtu(int mtu)
{
        /*
         * Reduce IB headers from effective IBoE MTU.
         */
        mtu = mtu - (IB_GRH_BYTES + IB_UDP_BYTES + IB_BTH_BYTES +
                     IB_EXT_XRC_BYTES + IB_EXT_ATOMICETH_BYTES +
                     IB_ICRC_BYTES);

        if (mtu >= ib_mtu_enum_to_int(IB_MTU_4096))
                return IB_MTU_4096;
        else if (mtu >= ib_mtu_enum_to_int(IB_MTU_2048))
                return IB_MTU_2048;
        else if (mtu >= ib_mtu_enum_to_int(IB_MTU_1024))
                return IB_MTU_1024;
        else if (mtu >= ib_mtu_enum_to_int(IB_MTU_512))
                return IB_MTU_512;
        else if (mtu >= ib_mtu_enum_to_int(IB_MTU_256))
                return IB_MTU_256;
        else
                return 0;
}
```

可见，该 MTU 值为 `256 * 2^n`, `n = 0..4`. 环境里以太网 MTU 是 1500, 因此计
算出 IBoE MTU 为 1024. 可以通过 `ibv_devinfo` 查看:

```sh
$ ibv_devinfo -d mlx5_bond_0
hca_id: mlx5_bond_0
        transport:                      InfiniBand (0)
		...
		hys_port_cnt:                  1
                port:   1
                        state:                  PORT_ACTIVE (4)
                        max_mtu:                4096 (5)
                        active_mtu:             1024 (3)
                        sm_lid:                 0
                        port_lid:               0
                        port_lmc:               0x00
                        link_layer:             Ethernet
```

可以看到，当前 `active_mtu` 为 1024, 硬件支持的最大值 `max_mtu` 为 4096.

## 后记

### 挂钟问题

测试代码中，一些调试日志打印的时间戳很奇怪，原来是用的
`std::chrono::steady_clock` 是稳步单调增挂钟。改成
`std::chrono::high_resolution_clock` 解决。

MSVC 和 GCC 的行为略有不同。GCC 有宏 `_GLIBCXX_USE_CLOCK_MONOTONIC` 来
控制 `std::chrono::system_clock` 采用哪个挂钟。参考[Stack Overflow](https://stackoverflow.com/questions/13263277/difference-between-stdsystem-clock-and-stdsteady-clock).

### 之前的演示？

演了个寂寞？为啥当初没注意到 `retry counter exceeded` 呢？

### AI 的助攻

梳理建连逻辑的时候，通过内部的 AI 服务可以分类、简化、细化代码逻辑。
