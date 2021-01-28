---
categories:
- work
date: 2016-03-21T00:00:00Z
description: ""
tags:
- Azure
title: LINQPad Table Driver for Azure China
url: /2016/03/21/linqpad-table-driver-for-azure-china/
---


在 Azure 的 PaaS 上构建云服务，很少有不用到 Cloud Storage 的。一般来说，
查看 Cloud Storage 中的数据主要有两个工具：

1. [Azure Table Explorer](https://azurestorageexplorer.codeplex.com/)
2. [LINQPad](http://www.linqpad.net/)，加上
[Azure Table Storage Driver](https://blog.madd0.com/2012/01/09/linqpad-driver-for-azure-table-storage/)

前者的最新版本同时支持 Global Azure 和 China Azure [^1]，而后者至今只
支持 Global Azure。由于 LINQPad 中可以直接写代码操纵 Table Storage，因
此更受程序员欢迎一点（但是前者可以直接处理 Blob Storage)。

之前有同事修改了一个工具，做 URL 转发 - 也就是抓取本机发到 global
Azure 的网络包，将其转发到 China Azure。缺点是必须以管理员权限运行，不
能处理 HTTPS 连接，而且在打开的过程中会影响其他网络服务。

我找到 LINQPad Driver for Azure Table Storage 的
[代码](https://github.com/madd0/AzureStorageDriver)（已经两年多没有更
新了）后，做了一些
[改动](https://github.com/live4thee/AzureStorageDriver/commit/30c6c489e2c059fa89b13d5cce4ce3bed28cad3d)
，这样它也能和 Azure Table Explorer 一样，可以同时连接 Global Azure 和
China Azure. 本想向原作者发一个 pull request，后来发现，已经有人提交
了一个 PR，但是没有被理睬。

[^1]: 根据政府要求，外企不能直接运营云服务，且数据中心必须建在国内。因此，Azure 的 global 版本和中国版实际上是分开的，URL 的域名也不一样。
