---
layout: post
title: "Using OpenWrt"
description: "A introduction to OpenWrt"
category: linux
tags: [networking]
---
{% include JB/setup %}

之前做路由器方面的工作的时候，老大给我发来了两款还算比较强劲的路由器。
其中一款当时OpenWrt还没有正式支持，自己尝试编译了DD-Wrt和OpenWrt的代码，
但编出来的镜像都不能工作。后来从DD-Wrt站点下载了预编译镜像，倒是跑的很
好。另一款，性能弱一点，OpenWrt支持的很好，编译、刷机，一下搞定。

我得说，DD-Wrt的编译系统对于开发者非常不友好，而OpenWrt简直就是福音。
它的整个源代码的组织、编译、补丁都非常干净，正是我理想中的组织系统方式
（基于Makefile - 有点类似BSD的Ports系统）。其编译系统的呈现和编译Linux
内核几乎一样。很酷。

这周on-call，晚上连公司的网络经常超时，便想把自己那个老旧的TP-Link换成
很久之前刷了OpenWrt的路由器。当时编译镜像的时候除了基本的工具，啥都没
选，因此配置工作只能通过SSH登录后，命令行操作。这也正是我所希望的，没
有WebUI，因此不需要跑个Web服务器 - 况且大部分时候，我们也不需要它。

路由器接着电信的机顶盒，稍微配置一下就行了：

~~~
uci set network.wan.proto=dhcp // WAN口从机顶盒获取IP

uci set wireless.@wifi-device[0].disabled=0
uci set wireless.@wifi-device[0].txpower=17
uci set wireless.@wifi-device[0].channel=6
uci set wireless.@wifi-iface[0].mode=ap
uci set wireless.@wifi-iface[0].ssid=[无线SSID]
uci set wireless.@wifi-iface[0].network=lan
uci set wireless.@wifi-iface[0].encryption=psk2
uci set wireless.@wifi-iface[0].key=[无线密码]

uci commit
/etc/init.d/network restart
~~~

