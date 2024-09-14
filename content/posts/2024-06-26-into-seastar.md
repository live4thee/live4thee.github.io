---
title: "Into Seastar"
date: 2024-06-26T14:40:35+08:00
tags: [ "networking", "c++", "seastar" ]
categories: [ "programming" ]
draft: false
---

在[Seastar](https://github.com/scylladb/seastar)的海洋里扑腾，喘口气。

增加了一个 HTTP handler, 用 `curl` 测试了一下能工作。所用的 Seastar 版
本只有 `http_server`, 没有 `http_client`，不得不照猫画虎写了个简陋的实现。
不但简陋，而且目前，不-工-作！

```txt
std::system_error (error system:9, read: Bad file descriptor)
```

用 `tcpdump` 抓了一下，确实也没有 HTTP 请求发出去。

**更新**：调试了一会，弱有进展。似乎光明就在眼前。

- ✅ HTTP client
- ✅ RDMA handshake
- 🔜 send/recv over RDMA channel
