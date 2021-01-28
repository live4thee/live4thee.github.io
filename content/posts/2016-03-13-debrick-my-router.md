---
categories:
- linux
date: 2016-03-13T00:00:00Z
description: ""
tags:
- OpenWrt
- networking
title: Debrick my Router
url: /2016/03/13/debrick-my-router/
---


前天晚上升级路由器里面的软件包时，一不小心把路由器给弄挂了，然后家里就
断网了。这个世界，饭可以少吃一顿，但是 Wi-Fi 却不可以断线一分钟啊！就
算要搜一个路由器的修复教程，也得先联网是不是。先换上了个旧的，恢复网络。

路由器取下来后，就是重刷一个 `OpenWrt` 的镜像 - 这里需要注意的是，要刷
的是 `factory image`，而不是 `sysupgrade` 所用的升级镜像文件。修复倒是
简单，先给电脑设置一个静态 IP 地址，然后把路由器启动到恢复模式，发现路
由器能 ping 通以后，立马用 tftp 把镜像文件传上去即可。

如果电脑没有网口，那就悲剧了 - 现在大部分超极本都做得很薄，没有网口。
幸亏家里还有一台 Thinkpad x220i，而且之前的设定我有一部分
[记录](https://live4thee.github.io/linux/2015/07/05/using-openwrt/)。
