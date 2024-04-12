---
title: "Hugo: Ref Not Found"
date: 2024-04-12T14:21:12+08:00
tags: [ "hugo" ]
categories: [ "life" ]
draft: false
---

在 Mac 上也用 `brew` 装了一个 `hugo`. 不过，把自己的 gh-pages 抓到本地
后，生成静态网页时总是报错 `Ref_Not_Found`. 把报错的文件路径粘贴出来检
查了一下，对应的文件却又实实在在地在磁盘躺着。

- Linux 环境：hugo v0.111.3
- Mac 环境：hugo v0.123.7

出错的地方都是使用 `ref` 指令做站内引用的地方。

搜了一下，原来是 v123.0 开始引入了[逻辑路径](https://gohugo.io/methods/page/path/)的概念，
是个非向前兼容的改动。解决方法类似如下：

- 修改前：ref "/content/posts/foo.md"
- 修改后：ref "/posts/foo"
