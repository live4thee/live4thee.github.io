---
title: "Notes on Unknown"
date: 2024-11-09T21:41:11+08:00
tags: [ "mm" ]
categories: [ "linux" ]
draft: false
---

记录一下最近碰到的不能理解的问题。

## `radix_tree_node` 占比

下面是某个节点的例子：

```sh
$ slabtop -sc --once | sed -e '1,6d' -e 's/J S/J-S/' -e 's/E S/E-S/' | head -10 | column -t
OBJS      ACTIVE    USE  OBJ-SIZE  SLABS   OBJ/SLAB  CACHE-SIZE  NAME
4848200   4847571   99%  1.14K     173150  28        5540800K    ext4_inode_cache
16624725  16623589  99%  0.10K     426275  39        1705100K    buffer_head
4201554   4200844   99%  0.19K     100037  42        800296K     dentry
1370768   1157410   84%  0.57K     24478   56        783296K     radix_tree_node
944190    944099    99%  0.71K     20982   45        671424K     proc_inode_cache
5973248   5973069   99%  0.06K     93332   64        373328K     lsm_inode_cache
621600    592884    95%  0.50K     19425   32        310800K     kmalloc-512
4873152   4873116   99%  0.06K     76143   64        304572K     jbd2_inode
174342    166945    95%  0.64K     3558    49        113856K     inode_cach
```

这里 `radix_tree_node` 对象的 USE 占比为 84%，正常也都比较高，甚至接近 100%. 有的节点里
该占比保持为大约 40% 出头，表明有一定的碎片化。这种情况下，内核会时不时地调度 `vmscan`
类型的回写。曾经在一个节点观察到连续四次 `vmscan`, 且每次刚好间隔 73s，但后续的 `vmscan`
并没有这个时间规律。

比较好奇这个占比差异是如何造成的。

## 内存的 free 值

相同角色、相同配置的节点，跑一段时间后 `free` 命令输出的 `free` 值可能有很大差异。
曾经看见一个服务最少的节点，只剩余了 3 GiB 左右 `free`, 而其他节点在 90 GiB 左右。 
