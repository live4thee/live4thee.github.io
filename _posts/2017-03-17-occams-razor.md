---
layout: post
title: "Occam's Razor"
description: ""
category: work
tags: [zstack]
---
{% include JB/setup %}

今天在解决
[issue #2259](https://github.com/zstackio/issues/issues/2259)的过程中，
突然发现，该问题的现象能够很容易地解释
[issue #1235](https://github.com/zstackio/issues/issues/1235)。而#1235
曾经被认为是一个不可思议的一个老大难问题，参详了好久，做了两次修复，但
偶尔还是能够重现。不过现在我确信，#2259 描述的步骤正是一直没有注意到的
复现步骤。简单、而且容易重复。

## 问题的根源

[Zstack](http://zstack.org) 中 Image 状态有两处，一个是 Image 表中维护
的状态，另一个是镜像服务器表中维护的该镜像在镜像服务器中的状态。分两处
的原因是，一个镜像可能同时存放在不同的镜像服务器中。镜像添加到不同的服
务器中的时候，很可能有的已经可用，有的还未添加完毕。

曾经以为做添加、删除的时候，操纵两张表的代码没有做到事务性，如果中间恰
好重启管理节点，有可能会状态不一致 - 虽然这种可能性非常非常小。前两次
的修复后仍然能复现就说明我们碰到的一定不是这种状况。

## 避免状态重复

同步状态是最容易出 bug 的场景。如果用 `CloudTable`，可以把
BackupStorage 的 uuid 当作 `Partition Key`，而 Image 本身的 `uuid` 当
作 `Row Key`，这样 PK + RK 唯一决定了该 Image 在某 BS 里的状态。在关系
型数据库里面，就需要把 PK+RK 拼接成一个 `Primary Key`。但这显然又不利
于实现一个通用的查询框架，该框架中任何资源都由一个 uuid 做为主键。

另一个办法是把 Image 表作为一个视图来实现，同一个镜像文件添加到不同的
镜像服务器后，生成不同的镜像 uuid。
