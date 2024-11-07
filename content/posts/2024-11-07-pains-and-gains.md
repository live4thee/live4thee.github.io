---
title: "Pains & Gains"
date: 2024-11-07T21:58:36+08:00
tags: [ "mm" ]
categories: [ "life" ]
draft: false
---

## Pains

### Physical

大概十月中旬开始，起床时两手有点麻，无法握拳。差不多一分钟内，症状消失。
最近几天左手背开始有点酸疼。

### Mental

这两天被 Linux 的内存管理系统折腾的够呛。莫名其妙的 `VMSCAN`，以及
`radix_tree_node` 对象在 slab 中的神奇占比。一堆未曾深入理解过的
`page cache` 回写行为。

## Gains

### Physical

休息了七、八两个月份后，重新开始跑步。最近 VO2 Max 从 48 重新爬回 50，
离之前的 51、52 迈进了一大步。

### Mental

`bpftrace` 自带的脚本 `writeback.bt`, `vmscan.bt` 以及 `syncsnoop.bt`
可以非常方便地观察回写原因、vmscan 细节以及刷盘动作。

Dirty Expire 只是回写的一种可能条件，没有 Expire 不代表就不会被回写。

就算内存的 Free 值高达 100GB/256GB，仍然可能发生 VMSCAN.

VMSCAN 的一个可能原因是 slab 碎片化。

sysctl 的某些设定，可能也会影响 `radix_tree_node` 占比（这里说的不是
`vm.vfs_cache_pressure`）。

磁盘越大，要管理的 inode/dentry 也越多啊！