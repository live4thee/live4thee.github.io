+++
title = "stdout*deferred"
date = 2020-01-28T20:12:07+08:00
tags = ["java"]
categories = ["programming"]
draft = false
+++

跑 *maven test* 的时候，发现 */tmp* 目录下多了一堆命名模式为
*stdout*deferred* 的文件，居然把根盘的空间（总共 6 GB）给消耗光了。

![screenshot](/media/deferred.png)

查了一下，原来是 *surefire* 插件[搞的鬼](https://issues.apache.org/jira/browse/SUREFIRE-1147)。
